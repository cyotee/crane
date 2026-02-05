// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solady                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IBasePool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePool.sol";
import {IPoolInfo} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-utils/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {
    IUnbalancedLiquidityInvariantRatioBounds
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {ICowPool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowPool.sol";
import {IHooks} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IHooks.sol";
import {
    TokenConfig,
    PoolRoleAccounts,
    LiquidityManagement
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                  OpenZeppelin                              */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {Address} from "@crane/contracts/utils/Address.sol";
import {SafeERC20} from "@crane/contracts/utils/SafeERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
import {IBalancerV3Pool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3Pool.sol";
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
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";
import {BalancerV3WeightedPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolRepo.sol";
import {CowPoolRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolRepo.sol";

/**
 * @title ICowPoolDFPkg
 * @notice Interface for CowPoolDFPkg constructor and deployment arguments.
 */
interface ICowPoolDFPkg {
    /**
     * @notice Constructor arguments for the package.
     * @param balancerV3VaultAwareFacet Facet for vault awareness.
     * @param betterBalancerV3PoolTokenFacet Facet for BPT token functionality.
     * @param defaultPoolInfoFacet Facet for pool info queries.
     * @param balancerV3AuthenticationFacet Facet for action authentication.
     * @param cowPoolFacet Facet for CoW pool functionality (hooks + weighted math).
     * @param balancerV3Vault The Balancer V3 vault address.
     * @param diamondFactory The diamond package factory for deployments.
     * @param poolFeeManager Address that manages pool fees.
     * @param trustedCowRouter The trusted CoW router for MEV-protected swaps.
     */
    struct PkgInit {
        IFacet balancerV3VaultAwareFacet;
        IFacet betterBalancerV3PoolTokenFacet;
        IFacet defaultPoolInfoFacet;
        IFacet balancerV3AuthenticationFacet;
        IFacet cowPoolFacet;
        IVault balancerV3Vault;
        IDiamondPackageCallBackFactory diamondFactory;
        address poolFeeManager;
        address trustedCowRouter;
    }

    /**
     * @notice Deployment arguments for each pool instance.
     * @param tokenConfigs Token configurations for the pool.
     * @param normalizedWeights Weights for each token (must sum to 1e18).
     */
    struct PkgArgs {
        TokenConfig[] tokenConfigs;
        uint256[] normalizedWeights;
    }

    /**
     * @notice Deploy a new CoW pool.
     * @param tokenConfigs Token configurations.
     * @param normalizedWeights Weights for each token.
     * @return pool The deployed pool address.
     */
    function deployPool(
        TokenConfig[] calldata tokenConfigs,
        uint256[] calldata normalizedWeights
    ) external returns (address pool);
}

/**
 * @title CowPoolDFPkg
 * @notice Diamond Factory Package for deploying Balancer V3 CoW Pools.
 * @dev CoW Pools are weighted pools that integrate with CoW Protocol for MEV protection.
 * They restrict swaps to a trusted router and enable donation-based liquidity additions.
 *
 * Key features:
 * - Extends weighted pool math
 * - Implements IHooks for access control on swaps and liquidity
 * - Only allows swaps from trusted CoW Router
 * - Enables donations for MEV surplus redistribution
 * - Pool registers ITSELF as the hooks contract
 *
 * Storage initialization:
 * - CowPoolRepo: cowPoolFactory, trustedCowRouter (CRITICAL for onRegister validation)
 * - BalancerV3WeightedPoolRepo: normalizedWeights
 * - BalancerV3PoolRepo: invariant bounds, fee bounds, tokens
 * - ERC20Repo: name, symbol, decimals
 * - EIP712Repo: domain separator
 * - BalancerV3VaultAwareRepo: vault reference
 */
contract CowPoolDFPkg is
    BalancerV3BasePoolFactory,
    IDiamondFactoryPackage,
    ICowPoolDFPkg
{
    using Address for address[];
    using BetterEfficientHashLib for bytes;
    using SafeERC20 for IERC20;
    using TokenConfigUtils for TokenConfig[];
    using WeightedTokenConfigUtils for TokenConfig[];

    // CoW pools use standard weighted pool bounds
    uint256 private constant _MIN_SWAP_FEE_PERCENTAGE = 1e12; // 0.0001%
    uint256 private constant _MAX_SWAP_FEE_PERCENTAGE = 0.1e18; // 10%
    uint256 private constant _MIN_INVARIANT_RATIO = 60e16; // 60%
    uint256 private constant _MAX_INVARIANT_RATIO = 500e16; // 500%

    IVault public immutable BALANCER_V3_VAULT;
    IDiamondPackageCallBackFactory public immutable DIAMOND_PACKAGE_FACTORY;
    address public immutable TRUSTED_COW_ROUTER;
    address public immutable COW_POOL_FACTORY;

    IFacet public immutable BALANCER_V3_VAULT_AWARE_FACET;
    IFacet public immutable BETTER_BALANCER_V3_POOL_TOKEN_FACET;
    IFacet public immutable DEFAULT_POOL_INFO_FACET;
    IFacet public immutable BALANCER_V3_AUTHENTICATION_FACET;
    IFacet public immutable COW_POOL_FACET;

    error InvalidTokensLength(uint256 maxLength, uint256 minLength, uint256 providedLength);
    error WeightsTokensMismatch(uint256 tokensLength, uint256 weightsLength);
    error InvalidTrustedCowRouter();

    constructor(PkgInit memory pkgInit) {
        if (pkgInit.trustedCowRouter == address(0)) revert InvalidTrustedCowRouter();

        BALANCER_V3_VAULT = pkgInit.balancerV3Vault;
        DIAMOND_PACKAGE_FACTORY = pkgInit.diamondFactory;
        TRUSTED_COW_ROUTER = pkgInit.trustedCowRouter;
        // NOTE: initAccount() is executed via delegatecall from the proxy.
        // Use an immutable captured here so the pool stores the *DFPkg* as its factory.
        COW_POOL_FACTORY = address(this);
        BALANCER_V3_VAULT_AWARE_FACET = pkgInit.balancerV3VaultAwareFacet;
        BETTER_BALANCER_V3_POOL_TOKEN_FACET = pkgInit.betterBalancerV3PoolTokenFacet;
        DEFAULT_POOL_INFO_FACET = pkgInit.defaultPoolInfoFacet;
        BALANCER_V3_AUTHENTICATION_FACET = pkgInit.balancerV3AuthenticationFacet;
        COW_POOL_FACET = pkgInit.cowPoolFacet;

        BalancerV3BasePoolFactoryRepo._initialize(
            365 days,
            pkgInit.poolFeeManager
        );
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );

        // Initialize vault repo so postDeploy can call _registerPoolWithBalV3Vault
        BalancerV3VaultAwareRepo._initialize(pkgInit.balancerV3Vault);
    }

    /**
     * @notice Minimal ICowPoolFactory compatibility for refreshTrustedCowRouter().
     * @dev The pool stores COW_POOL_FACTORY as its factory and calls
     * ICowPoolFactory(factory).getTrustedCowRouter() when refreshing.
     */
    function getTrustedCowRouter() external view returns (address) {
        return TRUSTED_COW_ROUTER;
    }

    function _diamondPkgFactory() internal view virtual override returns (IDiamondPackageCallBackFactory) {
        return DIAMOND_PACKAGE_FACTORY;
    }

    function _poolDFPkg() internal view virtual override returns (IDiamondFactoryPackage) {
        return IDiamondFactoryPackage(this);
    }

    /**
     * @notice Deploy a new CoW pool.
     * @param tokenConfigs_ Token configurations (2-8 tokens).
     * @param normalizedWeights_ Weights for each token (must sum to 1e18).
     * @return pool The deployed pool proxy address.
     */
    function deployPool(
        TokenConfig[] calldata tokenConfigs_,
        uint256[] calldata normalizedWeights_
    ) public returns (address pool) {
        pool = DIAMOND_PACKAGE_FACTORY.deploy(
            this,
            abi.encode(
                PkgArgs({
                    tokenConfigs: tokenConfigs_,
                    normalizedWeights: normalizedWeights_
                })
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         IDiamondFactoryPackage                         */
    /* ---------------------------------------------------------------------- */

    function packageName() public pure returns (string memory name_) {
        return type(CowPoolDFPkg).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](14);
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
        interfaces[11] = type(ICowPool).interfaceId;
        interfaces[12] = type(IHooks).interfaceId;
        interfaces[13] = type(IBalancerV3WeightedPool).interfaceId;
        return interfaces;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](5);
        facetAddresses_[0] = address(BALANCER_V3_VAULT_AWARE_FACET);
        facetAddresses_[1] = address(BETTER_BALANCER_V3_POOL_TOKEN_FACET);
        facetAddresses_[2] = address(DEFAULT_POOL_INFO_FACET);
        facetAddresses_[3] = address(BALANCER_V3_AUTHENTICATION_FACET);
        facetAddresses_[4] = address(COW_POOL_FACET);
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
            facetAddress: address(COW_POOL_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: COW_POOL_FACET.facetFuncs()
        });

        return facetCuts_;
    }

    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    /**
     * @notice Calculate deterministic salt from pool parameters.
     * @dev Includes token configs and weights for unique pool addresses.
     */
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));

        uint256 tokensLen = decodedArgs.tokenConfigs.length;
        if (tokensLen < 2 || tokensLen > 8) {
            revert InvalidTokensLength(8, 2, tokensLen);
        }
        if (decodedArgs.normalizedWeights.length != tokensLen) {
            revert WeightsTokensMismatch(tokensLen, decodedArgs.normalizedWeights.length);
        }

        // Sort tokenConfigs AND weights together to maintain alignment
        (decodedArgs.tokenConfigs, decodedArgs.normalizedWeights) =
            decodedArgs.tokenConfigs._sortWithWeights(decodedArgs.normalizedWeights);
        pkgArgs = abi.encode(decodedArgs);
        return abi.encode(pkgArgs)._hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));
        // Sort tokenConfigs AND weights together to maintain alignment
        (decodedArgs.tokenConfigs, decodedArgs.normalizedWeights) =
            decodedArgs.tokenConfigs._sortWithWeights(decodedArgs.normalizedWeights);
        processedPkgArgs = abi.encode(decodedArgs);
        return processedPkgArgs;
    }

    function updatePkg(address expectedProxy, bytes memory pkgArgs) public virtual returns (bool) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));
        BalancerV3BasePoolFactoryRepo._setTokenConfigs(expectedProxy, decodedArgs.tokenConfigs);
        // Note: CoW pools do NOT have a configurable hooks contract - the pool IS the hook
        return true;
    }

    /**
     * @notice Initialize the pool's storage during deployment.
     * @dev Called via delegatecall on the proxy during CREATE2 deployment.
     * CRITICAL: Initializes CowPoolRepo with factory and router for onRegister to succeed.
     */
    function initAccount(bytes memory initArgs) public {
        PkgArgs memory decodedArgs = abi.decode(initArgs, (PkgArgs));

        address[] memory tokens = new address[](decodedArgs.tokenConfigs.length);
        for (uint256 i = 0; i < decodedArgs.tokenConfigs.length; i++) {
            tokens[i] = address(decodedArgs.tokenConfigs[i].token);
        }

        string memory name = _buildPoolName(tokens);

        // Initialize ERC20 token storage
        ERC20Repo._initialize(
            name,
            "BPT",
            18
        );

        // Initialize EIP712 for permit functionality
        EIP712Repo._initialize(
            name,
            "1"
        );

        // Initialize base pool storage
        BalancerV3PoolRepo._initialize(
            _MIN_INVARIANT_RATIO,
            _MAX_INVARIANT_RATIO,
            _MIN_SWAP_FEE_PERCENTAGE,
            _MAX_SWAP_FEE_PERCENTAGE,
            tokens
        );

        // Initialize weighted pool weights
        BalancerV3WeightedPoolRepo._initialize(
            decodedArgs.normalizedWeights
        );

        // Initialize authentication with factory's action ID root
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );

        // Initialize vault awareness for pool operations
        BalancerV3VaultAwareRepo._initialize(BALANCER_V3_VAULT);

        // CRITICAL: Initialize CoW pool storage with factory and trusted router
        // This is required for CowPoolTarget.onRegister() to succeed
        CowPoolRepo._initialize(
            COW_POOL_FACTORY,
            TRUSTED_COW_ROUTER
        );
    }

    function _buildPoolName(address[] memory tokens) internal view returns (string memory) {
        if (tokens.length == 2) {
            return string.concat(
                "BV3CoW of (",
                IERC20Metadata(tokens[0]).name(),
                " / ",
                IERC20Metadata(tokens[1]).name(),
                ")"
            );
        } else {
            string memory result = "BV3CoW of (";
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

    /**
     * @notice Configure liquidity management for CoW pools.
     * @dev CoW pools MUST have:
     * - enableDonation: true (for MEV surplus redistribution)
     * - disableUnbalancedLiquidity: true (prevents bypassing swap logic)
     */
    function _liquidityManagement() internal pure returns (LiquidityManagement memory liquidityManagement) {
        liquidityManagement = LiquidityManagement({
            disableUnbalancedLiquidity: true, // Required for CoW pools
            enableAddLiquidityCustom: false,
            enableRemoveLiquidityCustom: false,
            enableDonation: true // Required for CoW pools
        });
    }

    /**
     * @notice Register the pool with the Balancer V3 vault.
     * @dev The pool registers ITSELF as the hooks contract because it implements IHooks.
     * The vault will call pool.onRegister() which validates:
     * - pool == address(this) (pool is registering itself)
     * - factory == CowPoolRepo._getCowPoolFactory() (factory is our DFPkg)
     * - liquidityManagement.enableDonation == true
     * - liquidityManagement.disableUnbalancedLiquidity == true
     */
    function postDeploy(address proxy) public returns (bool) {
        _registerPoolWithBalV3Vault(
            proxy,
            BalancerV3BasePoolFactoryRepo._getTokenConfigs(proxy),
            5e16, // 5% initial swap fee
            false, // Not protocol fee exempt
            _roleAccounts(),
            proxy, // CRITICAL: Pool IS its own hooks contract
            _liquidityManagement()
        );
        return true;
    }
}
