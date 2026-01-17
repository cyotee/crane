// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solady                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IPoolInfo} from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@balancer-labs/v3-interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {
    IUnbalancedLiquidityInvariantRatioBounds
} from "@balancer-labs/v3-interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    TokenConfig,
    PoolRoleAccounts,
    LiquidityManagement
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                  OpenZeppelin                              */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
import {IBalancerV3WeightedPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol";
import {
    BalancerV3BasePoolFactory
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol";
import {TokenConfigUtils} from "@crane/contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol";
import {WeightedTokenConfigUtils} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/WeightedTokenConfigUtils.sol";
import {BalancerV3BasePoolFactoryRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {BalancerV3PoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol";
import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol";
import {BalancerV3WeightedPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol";

interface IBalancerV3WeightedPoolDFPkg {
    struct PkgInit {
        IFacet balancerV3VaultAwareFacet;
        IFacet betterBalancerV3PoolTokenFacet;
        IFacet defaultPoolInfoFacet;
        IFacet standardSwapFeePercentageBoundsFacet;
        IFacet unbalancedLiquidityInvariantRatioBoundsFacet;
        IFacet balancerV3AuthenticationFacet;
        IFacet balancerV3WeightedPoolFacet;
        IVault balancerV3Vault;
        IDiamondPackageCallBackFactory diamondFactory;
        address poolFeeManager;
    }

    struct PkgArgs {
        TokenConfig[] tokenConfigs;
        uint256[] normalizedWeights;
        address hooksContract;
    }

    function deployPool(
        TokenConfig[] calldata tokenConfigs,
        uint256[] calldata normalizedWeights,
        address hooksContract
    ) external returns (address vault);
}

contract BalancerV3WeightedPoolDFPkg is
    BalancerV3BasePoolFactory,
    IDiamondFactoryPackage,
    IBalancerV3WeightedPoolDFPkg
{
    using Address for address[];
    using BetterEfficientHashLib for bytes;
    using SafeERC20 for IERC20;
    using TokenConfigUtils for TokenConfig[];
    using WeightedTokenConfigUtils for TokenConfig[];

    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.1e18; // 10%
    uint256 private constant _MIN_INVARIANT_RATIO = 60e16; // 60% (lower for weighted pools)
    uint256 private constant _MAX_INVARIANT_RATIO = 500e16; // 500% (higher for weighted pools)

    IVault public immutable BALANCER_V3_VAULT;
    IDiamondPackageCallBackFactory public immutable DIAMOND_PACKAGE_FACTORY;

    IFacet public immutable BALANCER_V3_VAULT_AWARE_FACET;
    IFacet public immutable BETTER_BALANCER_V3_POOL_TOKEN_FACET;
    IFacet public immutable DEFAULT_POOL_INFO_FACET;
    IFacet public immutable BALANCER_V3_AUTHENTICATION_FACET;
    IFacet public immutable BALANCER_V3_WEIGHTED_POOL_FACET;

    constructor(PkgInit memory pkgInit) {
        BALANCER_V3_VAULT = pkgInit.balancerV3Vault;
        DIAMOND_PACKAGE_FACTORY = pkgInit.diamondFactory;
        BALANCER_V3_VAULT_AWARE_FACET = pkgInit.balancerV3VaultAwareFacet;
        BETTER_BALANCER_V3_POOL_TOKEN_FACET = pkgInit.betterBalancerV3PoolTokenFacet;
        DEFAULT_POOL_INFO_FACET = pkgInit.defaultPoolInfoFacet;
        BALANCER_V3_AUTHENTICATION_FACET = pkgInit.balancerV3AuthenticationFacet;
        BALANCER_V3_WEIGHTED_POOL_FACET = pkgInit.balancerV3WeightedPoolFacet;
        BalancerV3BasePoolFactoryRepo._initialize(
            365 days,
            pkgInit.poolFeeManager
        );
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );
    }

    function _diamondPkgFactory() internal view virtual override returns (IDiamondPackageCallBackFactory) {
        return DIAMOND_PACKAGE_FACTORY;
    }

    function _poolDFPkg() internal view virtual override returns (IDiamondFactoryPackage) {
        return IDiamondFactoryPackage(this);
    }

    function deployPool(
        TokenConfig[] calldata tokenConfigs_,
        uint256[] calldata normalizedWeights_,
        address hooksContract
    ) public returns (address vault) {
        vault = DIAMOND_PACKAGE_FACTORY.deploy(
            this,
            abi.encode(
                PkgArgs({
                    tokenConfigs: tokenConfigs_,
                    normalizedWeights: normalizedWeights_,
                    hooksContract: hooksContract
                })
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         IDiamondFactoryPackage                         */
    /* ---------------------------------------------------------------------- */

    function packageName() public pure returns (string memory name_) {
        return type(BalancerV3WeightedPoolDFPkg).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](12);
        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
        interfaces[3] = type(IERC20Permit).interfaceId;
        interfaces[4] = type(IERC5267).interfaceId;
        interfaces[5] = type(IBalancerV3VaultAware).interfaceId;
        interfaces[6] = type(IPoolInfo).interfaceId;
        interfaces[7] = type(IBasePool).interfaceId;
        interfaces[8] = type(ISwapFeePercentageBounds).interfaceId;
        interfaces[9] = type(IUnbalancedLiquidityInvariantRatioBounds).interfaceId;
        interfaces[10] = type(IBalancerPoolToken).interfaceId;
        interfaces[11] = type(IBalancerV3WeightedPool).interfaceId;
        return interfaces;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](5);
        facetAddresses_[0] = address(BALANCER_V3_VAULT_AWARE_FACET);
        facetAddresses_[1] = address(BETTER_BALANCER_V3_POOL_TOKEN_FACET);
        facetAddresses_[2] = address(DEFAULT_POOL_INFO_FACET);
        facetAddresses_[3] = address(BALANCER_V3_AUTHENTICATION_FACET);
        facetAddresses_[4] = address(BALANCER_V3_WEIGHTED_POOL_FACET);
    }

    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](5);

        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(BALANCER_V3_VAULT_AWARE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_VAULT_AWARE_FACET.facetFuncs()
        });

        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(BETTER_BALANCER_V3_POOL_TOKEN_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BETTER_BALANCER_V3_POOL_TOKEN_FACET.facetFuncs()
        });

        facetCuts_[2] = IDiamond.FacetCut({
            facetAddress: address(DEFAULT_POOL_INFO_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: DEFAULT_POOL_INFO_FACET.facetFuncs()
        });

        facetCuts_[3] = IDiamond.FacetCut({
            facetAddress: address(BALANCER_V3_AUTHENTICATION_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_AUTHENTICATION_FACET.facetFuncs()
        });

        facetCuts_[4] = IDiamond.FacetCut({
            facetAddress: address(BALANCER_V3_WEIGHTED_POOL_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_WEIGHTED_POOL_FACET.facetFuncs()
        });

        return facetCuts_;
    }

    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    error InvalidTokensLength(uint256 maxLength, uint256 minLength, uint256 providedLength);
    error WeightsTokensMismatch(uint256 tokensLength, uint256 weightsLength);

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));

        uint256 tokensLen = decodedArgs.tokenConfigs.length;
        if (tokensLen < 2 || tokensLen > 8) {
            revert InvalidTokensLength(8, 2, tokensLen);
        }
        if (decodedArgs.normalizedWeights.length != tokensLen) {
            revert WeightsTokensMismatch(tokensLen, decodedArgs.normalizedWeights.length);
        }

        // Sort tokenConfigs AND weights together to maintain alignment (Finding 1 fix)
        (decodedArgs.tokenConfigs, decodedArgs.normalizedWeights) =
            decodedArgs.tokenConfigs._sortWithWeights(decodedArgs.normalizedWeights);
        pkgArgs = abi.encode(decodedArgs);
        return abi.encode(pkgArgs)._hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));
        // Sort tokenConfigs AND weights together to maintain alignment (Finding 1 fix)
        (decodedArgs.tokenConfigs, decodedArgs.normalizedWeights) =
            decodedArgs.tokenConfigs._sortWithWeights(decodedArgs.normalizedWeights);
        processedPkgArgs = abi.encode(decodedArgs);
        return processedPkgArgs;
    }

    function updatePkg(address expectedProxy, bytes memory pkgArgs) public virtual returns (bool) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));
        BalancerV3BasePoolFactoryRepo._setTokenConfigs(expectedProxy, decodedArgs.tokenConfigs);
        BalancerV3BasePoolFactoryRepo._setHooksContract(expectedProxy, decodedArgs.hooksContract);
        return true;
    }

    function initAccount(bytes memory initArgs) public {
        PkgArgs memory decodedArgs = abi.decode(initArgs, (PkgArgs));

        address[] memory tokens = new address[](decodedArgs.tokenConfigs.length);
        for (uint256 i = 0; i < decodedArgs.tokenConfigs.length; i++) {
            tokens[i] = address(decodedArgs.tokenConfigs[i].token);
        }

        string memory name = _buildPoolName(tokens);

        ERC20Repo._initialize(
            name,
            "BPT",
            18
        );
        EIP712Repo._initialize(
            name,
            "1"
        );
        BalancerV3PoolRepo._initialize(
            _MIN_INVARIANT_RATIO,
            _MAX_INVARIANT_RATIO,
            _MIN_SWAP_FEE_PERCENTAGE,
            _MAX_SWAP_FEE_PERCENTAGE,
            tokens
        );
        BalancerV3WeightedPoolRepo._initialize(
            decodedArgs.normalizedWeights
        );
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );
    }

    function _buildPoolName(address[] memory tokens) internal view returns (string memory) {
        if (tokens.length == 2) {
            return string.concat(
                "BV3Weighted of (",
                IERC20Metadata(tokens[0]).name(),
                " / ",
                IERC20Metadata(tokens[1]).name(),
                ")"
            );
        } else {
            string memory result = "BV3Weighted of (";
            for (uint256 i = 0; i < tokens.length; i++) {
                result = string.concat(result, IERC20Metadata(tokens[i]).name());
                if (i < tokens.length - 1) {
                    result = string.concat(result, " / ");
                }
            }
            return string.concat(result, ")");
        }
    }

    function _roleAccounts() internal view returns (PoolRoleAccounts memory roleAccounts) {
        address manager = BalancerV3BasePoolFactoryRepo._getPoolManager();
        roleAccounts = PoolRoleAccounts({pauseManager: manager, swapFeeManager: manager, poolCreator: manager});
    }

    function _liquidityManagement() internal pure returns (LiquidityManagement memory liquidityManagement) {
        liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: false,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: true
        });
    }

    function postDeploy(address proxy) public returns (bool) {
        _registerPoolWithBalV3Vault(
            proxy,
            BalancerV3BasePoolFactoryRepo._getTokenConfigs(proxy),
            5e16,
            false,
            _roleAccounts(),
            BalancerV3BasePoolFactoryRepo._getHooksContract(proxy),
            _liquidityManagement()
        );
        return true;
    }
}
