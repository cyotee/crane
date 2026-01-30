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
    TokenType,
    PoolRoleAccounts,
    LiquidityManagement
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";

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
import {IBalancerV3LBPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3LBPool.sol";
import {
    BalancerV3BasePoolFactory
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactory.sol";
import {TokenConfigUtils} from "@crane/contracts/protocols/dexes/balancer/v3/utils/TokenConfigUtils.sol";
import {BalancerV3BasePoolFactoryRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {BalancerV3PoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3PoolRepo.sol";
import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol";
import {BalancerV3LBPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/lbp/BalancerV3LBPoolRepo.sol";

interface IBalancerV3LBPoolDFPkg {
    struct PkgInit {
        IFacet balancerV3VaultAwareFacet;
        IFacet betterBalancerV3PoolTokenFacet;
        IFacet defaultPoolInfoFacet;
        IFacet standardSwapFeePercentageBoundsFacet;
        IFacet unbalancedLiquidityInvariantRatioBoundsFacet;
        IFacet balancerV3AuthenticationFacet;
        IFacet balancerV3LBPoolFacet;
        IVault balancerV3Vault;
        IDiamondPackageCallBackFactory diamondFactory;
        address poolFeeManager;
    }

    struct PkgArgs {
        address projectToken;
        address reserveToken;
        uint256 projectTokenStartWeight;
        uint256 projectTokenEndWeight;
        uint256 startTime;
        uint256 endTime;
        bool blockProjectTokenSwapsIn;
        uint256 reserveTokenVirtualBalance;
        address hooksContract;
    }

    function deployPool(
        address projectToken,
        address reserveToken,
        uint256 projectTokenStartWeight,
        uint256 projectTokenEndWeight,
        uint256 startTime,
        uint256 endTime,
        bool blockProjectTokenSwapsIn,
        uint256 reserveTokenVirtualBalance,
        address hooksContract
    ) external returns (address pool);
}

contract BalancerV3LBPoolDFPkg is
    BalancerV3BasePoolFactory,
    IDiamondFactoryPackage,
    IBalancerV3LBPoolDFPkg
{
    using Address for address[];
    using BetterEfficientHashLib for bytes;
    using SafeERC20 for IERC20;
    using TokenConfigUtils for TokenConfig[];

    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.1e18; // 10%
    uint256 private constant _MIN_INVARIANT_RATIO = 60e16; // 60%
    uint256 private constant _MAX_INVARIANT_RATIO = 500e16; // 500%

    IVault public immutable BALANCER_V3_VAULT;
    IDiamondPackageCallBackFactory public immutable DIAMOND_PACKAGE_FACTORY;

    IFacet public immutable BALANCER_V3_VAULT_AWARE_FACET;
    IFacet public immutable BETTER_BALANCER_V3_POOL_TOKEN_FACET;
    IFacet public immutable DEFAULT_POOL_INFO_FACET;
    IFacet public immutable BALANCER_V3_AUTHENTICATION_FACET;
    IFacet public immutable BALANCER_V3_LB_POOL_FACET;

    constructor(PkgInit memory pkgInit) {
        BALANCER_V3_VAULT = pkgInit.balancerV3Vault;
        DIAMOND_PACKAGE_FACTORY = pkgInit.diamondFactory;
        BALANCER_V3_VAULT_AWARE_FACET = pkgInit.balancerV3VaultAwareFacet;
        BETTER_BALANCER_V3_POOL_TOKEN_FACET = pkgInit.betterBalancerV3PoolTokenFacet;
        DEFAULT_POOL_INFO_FACET = pkgInit.defaultPoolInfoFacet;
        BALANCER_V3_AUTHENTICATION_FACET = pkgInit.balancerV3AuthenticationFacet;
        BALANCER_V3_LB_POOL_FACET = pkgInit.balancerV3LBPoolFacet;
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
        address projectToken_,
        address reserveToken_,
        uint256 projectTokenStartWeight_,
        uint256 projectTokenEndWeight_,
        uint256 startTime_,
        uint256 endTime_,
        bool blockProjectTokenSwapsIn_,
        uint256 reserveTokenVirtualBalance_,
        address hooksContract_
    ) public returns (address pool) {
        pool = DIAMOND_PACKAGE_FACTORY.deploy(
            this,
            abi.encode(
                PkgArgs({
                    projectToken: projectToken_,
                    reserveToken: reserveToken_,
                    projectTokenStartWeight: projectTokenStartWeight_,
                    projectTokenEndWeight: projectTokenEndWeight_,
                    startTime: startTime_,
                    endTime: endTime_,
                    blockProjectTokenSwapsIn: blockProjectTokenSwapsIn_,
                    reserveTokenVirtualBalance: reserveTokenVirtualBalance_,
                    hooksContract: hooksContract_
                })
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         IDiamondFactoryPackage                         */
    /* ---------------------------------------------------------------------- */

    function packageName() public pure returns (string memory name_) {
        return type(BalancerV3LBPoolDFPkg).name;
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
        interfaces[11] = type(IBalancerV3LBPool).interfaceId;
        return interfaces;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](5);
        facetAddresses_[0] = address(BALANCER_V3_VAULT_AWARE_FACET);
        facetAddresses_[1] = address(BETTER_BALANCER_V3_POOL_TOKEN_FACET);
        facetAddresses_[2] = address(DEFAULT_POOL_INFO_FACET);
        facetAddresses_[3] = address(BALANCER_V3_AUTHENTICATION_FACET);
        facetAddresses_[4] = address(BALANCER_V3_LB_POOL_FACET);
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
            facetAddress: address(BALANCER_V3_LB_POOL_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_LB_POOL_FACET.facetFuncs()
        });

        return facetCuts_;
    }

    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    error InvalidTokenCount();
    error InvalidTimeRange();
    error InvalidWeights();

    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));

        // Validate basic parameters
        if (decodedArgs.startTime >= decodedArgs.endTime) {
            revert InvalidTimeRange();
        }

        // LBPs are always 2-token pools
        // Sort tokens to ensure deterministic addresses
        (address token0, address token1) = decodedArgs.projectToken < decodedArgs.reserveToken
            ? (decodedArgs.projectToken, decodedArgs.reserveToken)
            : (decodedArgs.reserveToken, decodedArgs.projectToken);

        // Use sorted tokens for salt computation
        bytes memory sortedArgs = abi.encode(
            token0,
            token1,
            decodedArgs.projectTokenStartWeight,
            decodedArgs.projectTokenEndWeight,
            decodedArgs.startTime,
            decodedArgs.endTime
        );

        return sortedArgs._hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        // LBP args don't need reordering like weighted pool
        // Just validate and return
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));

        if (decodedArgs.startTime >= decodedArgs.endTime) {
            revert InvalidTimeRange();
        }

        return pkgArgs;
    }

    function updatePkg(address expectedProxy, bytes memory pkgArgs) public virtual returns (bool) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));

        // Build TokenConfig array for 2 tokens
        TokenConfig[] memory tokenConfigs = new TokenConfig[](2);

        // Sort tokens for Vault registration
        (address token0, address token1) = decodedArgs.projectToken < decodedArgs.reserveToken
            ? (decodedArgs.projectToken, decodedArgs.reserveToken)
            : (decodedArgs.reserveToken, decodedArgs.projectToken);

        tokenConfigs[0] = TokenConfig({
            token: IERC20(token0),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            paysYieldFees: false
        });
        tokenConfigs[1] = TokenConfig({
            token: IERC20(token1),
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            paysYieldFees: false
        });

        BalancerV3BasePoolFactoryRepo._setTokenConfigs(expectedProxy, tokenConfigs);
        BalancerV3BasePoolFactoryRepo._setHooksContract(expectedProxy, decodedArgs.hooksContract);
        return true;
    }

    function initAccount(bytes memory initArgs) public {
        PkgArgs memory decodedArgs = abi.decode(initArgs, (PkgArgs));

        // Determine token indices based on sorting
        (uint256 projectTokenIndex, uint256 reserveTokenIndex) = decodedArgs.projectToken < decodedArgs.reserveToken
            ? (uint256(0), uint256(1))
            : (uint256(1), uint256(0));

        // Build sorted token array for pool name
        address[] memory tokens = new address[](2);
        tokens[0] = decodedArgs.projectToken < decodedArgs.reserveToken
            ? decodedArgs.projectToken
            : decodedArgs.reserveToken;
        tokens[1] = decodedArgs.projectToken < decodedArgs.reserveToken
            ? decodedArgs.reserveToken
            : decodedArgs.projectToken;

        string memory name = _buildPoolName(tokens);

        ERC20Repo._initialize(
            name,
            "LBP-BPT",
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

        // Compute scaling factor for reserve token
        uint256 reserveScalingFactor = 10 ** (18 - IERC20Metadata(decodedArgs.reserveToken).decimals());
        uint256 virtualBalanceScaled18 = decodedArgs.reserveTokenVirtualBalance * reserveScalingFactor;

        BalancerV3LBPoolRepo._initialize(
            projectTokenIndex,
            reserveTokenIndex,
            decodedArgs.projectTokenStartWeight,
            decodedArgs.projectTokenEndWeight,
            decodedArgs.startTime,
            decodedArgs.endTime,
            decodedArgs.blockProjectTokenSwapsIn,
            virtualBalanceScaled18,
            reserveScalingFactor
        );
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );
    }

    function _buildPoolName(address[] memory tokens) internal view returns (string memory) {
        return string.concat(
            "BV3LBP of (",
            IERC20Metadata(tokens[0]).name(),
            " / ",
            IERC20Metadata(tokens[1]).name(),
            ")"
        );
    }

    function _roleAccounts() internal view returns (PoolRoleAccounts memory roleAccounts) {
        address manager = BalancerV3BasePoolFactoryRepo._getPoolManager();
        roleAccounts = PoolRoleAccounts({pauseManager: manager, swapFeeManager: manager, poolCreator: manager});
    }

    function _liquidityManagement() internal pure returns (LiquidityManagement memory liquidityManagement) {
        // LBPs typically disable unbalanced liquidity
        liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: true,
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: false
        });
    }

    function postDeploy(address proxy) public returns (bool) {
        _registerPoolWithBalV3Vault(
            proxy,
            BalancerV3BasePoolFactoryRepo._getTokenConfigs(proxy),
            5e16, // 5% swap fee (typical for LBPs)
            false,
            _roleAccounts(),
            BalancerV3BasePoolFactoryRepo._getHooksContract(proxy),
            _liquidityManagement()
        );
        return true;
    }
}
