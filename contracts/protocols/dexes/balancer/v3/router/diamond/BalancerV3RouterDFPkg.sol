// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                   Solady                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import {IRouterCommon} from "@balancer-labs/v3-interfaces/contracts/vault/IRouterCommon.sol";
import {IBatchRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBatchRouter.sol";
import {ICompositeLiquidityRouter} from "@balancer-labs/v3-interfaces/contracts/vault/ICompositeLiquidityRouter.sol";
import {IBufferRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBufferRouter.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {BalancerV3RouterStorageRepo} from "./BalancerV3RouterStorageRepo.sol";

/* -------------------------------------------------------------------------- */
/*                          IBalancerV3RouterDFPkg                            */
/* -------------------------------------------------------------------------- */

/**
 * @title IBalancerV3RouterDFPkg
 * @notice Interface for the Balancer V3 Router Diamond Factory Package.
 */
interface IBalancerV3RouterDFPkg {
    /**
     * @notice Constructor arguments for the Router DFPkg.
     * @dev These are immutable facet references stored in the package.
     */
    struct PkgInit {
        /// @dev Core router facets
        IFacet routerSwapFacet;
        IFacet routerAddLiquidityFacet;
        IFacet routerRemoveLiquidityFacet;
        IFacet routerInitializeFacet;
        IFacet routerCommonFacet;
        /// @dev Batch router facet
        IFacet batchSwapFacet;
        /// @dev Buffer router facet
        IFacet bufferRouterFacet;
        /// @dev Composite liquidity facets
        IFacet compositeLiquidityERC4626Facet;
        IFacet compositeLiquidityNestedFacet;
        /// @dev Diamond factory for deploying router instances
        IDiamondPackageCallBackFactory diamondFactory;
    }

    /**
     * @notice Per-instance deployment arguments for the Router.
     * @dev These configure each deployed router instance.
     */
    struct PkgArgs {
        /// @dev Balancer V3 Vault to route operations through
        IVault vault;
        /// @dev WETH token for ETH wrapping/unwrapping
        IWETH weth;
        /// @dev Permit2 contract for token approvals (address(0) for prepaid routers)
        IPermit2 permit2;
        /// @dev Version string for the router
        string routerVersion;
    }

    /**
     * @notice Deploy a new Router Diamond instance.
     * @param vault The Balancer V3 Vault
     * @param weth The WETH token
     * @param permit2 The Permit2 contract (address(0) for prepaid routers)
     * @param routerVersion Version string
     * @return router The deployed router address
     */
    function deployRouter(
        IVault vault,
        IWETH weth,
        IPermit2 permit2,
        string calldata routerVersion
    ) external returns (address router);
}

/* -------------------------------------------------------------------------- */
/*                          BalancerV3RouterDFPkg                             */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3RouterDFPkg
 * @notice Diamond Factory Package for deploying Balancer V3 Router instances.
 * @dev This package bundles all Router facets and provides deterministic deployment
 * via the DiamondPackageCallBackFactory.
 *
 * The Router Diamond provides:
 * - Single token swaps (IRouter)
 * - Add/remove liquidity (IRouter)
 * - Pool initialization (IRouter)
 * - Batch swaps (IBatchRouter)
 * - Buffer operations (IBufferRouter)
 * - Composite liquidity for ERC4626 and nested pools (ICompositeLiquidityRouter)
 *
 * Usage:
 * 1. Deploy this package with all facet references
 * 2. Call deployRouter() to create router instances
 * 3. Each router instance is a Diamond proxy with all router functionality
 */
contract BalancerV3RouterDFPkg is IDiamondFactoryPackage, IBalancerV3RouterDFPkg {
    using BetterEfficientHashLib for bytes;

    /* ========================================================================== */
    /*                              IMMUTABLE STATE                               */
    /* ========================================================================== */

    IDiamondPackageCallBackFactory public immutable DIAMOND_PACKAGE_FACTORY;

    // Core router facets
    IFacet public immutable ROUTER_SWAP_FACET;
    IFacet public immutable ROUTER_ADD_LIQUIDITY_FACET;
    IFacet public immutable ROUTER_REMOVE_LIQUIDITY_FACET;
    IFacet public immutable ROUTER_INITIALIZE_FACET;
    IFacet public immutable ROUTER_COMMON_FACET;

    // Batch router facet
    IFacet public immutable BATCH_SWAP_FACET;

    // Buffer router facet
    IFacet public immutable BUFFER_ROUTER_FACET;

    // Composite liquidity facets
    IFacet public immutable COMPOSITE_LIQUIDITY_ERC4626_FACET;
    IFacet public immutable COMPOSITE_LIQUIDITY_NESTED_FACET;

    /* ========================================================================== */
    /*                                CONSTRUCTOR                                 */
    /* ========================================================================== */

    constructor(PkgInit memory pkgInit) {
        DIAMOND_PACKAGE_FACTORY = pkgInit.diamondFactory;

        // Core router facets
        ROUTER_SWAP_FACET = pkgInit.routerSwapFacet;
        ROUTER_ADD_LIQUIDITY_FACET = pkgInit.routerAddLiquidityFacet;
        ROUTER_REMOVE_LIQUIDITY_FACET = pkgInit.routerRemoveLiquidityFacet;
        ROUTER_INITIALIZE_FACET = pkgInit.routerInitializeFacet;
        ROUTER_COMMON_FACET = pkgInit.routerCommonFacet;

        // Batch router facet
        BATCH_SWAP_FACET = pkgInit.batchSwapFacet;

        // Buffer router facet
        BUFFER_ROUTER_FACET = pkgInit.bufferRouterFacet;

        // Composite liquidity facets
        COMPOSITE_LIQUIDITY_ERC4626_FACET = pkgInit.compositeLiquidityERC4626Facet;
        COMPOSITE_LIQUIDITY_NESTED_FACET = pkgInit.compositeLiquidityNestedFacet;
    }

    /* ========================================================================== */
    /*                              DEPLOY FUNCTION                               */
    /* ========================================================================== */

    /**
     * @inheritdoc IBalancerV3RouterDFPkg
     */
    function deployRouter(
        IVault vault,
        IWETH weth,
        IPermit2 permit2,
        string calldata routerVersion
    ) public returns (address router) {
        router = DIAMOND_PACKAGE_FACTORY.deploy(
            this,
            abi.encode(
                PkgArgs({
                    vault: vault,
                    weth: weth,
                    permit2: permit2,
                    routerVersion: routerVersion
                })
            )
        );
    }

    /* ========================================================================== */
    /*                         IDiamondFactoryPackage                             */
    /* ========================================================================== */

    /**
     * @notice Returns the package name.
     */
    function packageName() public pure returns (string memory name_) {
        return type(BalancerV3RouterDFPkg).name;
    }

    /**
     * @notice Returns all interface IDs supported by deployed routers.
     */
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](5);
        interfaces[0] = type(IRouter).interfaceId;
        interfaces[1] = type(IRouterCommon).interfaceId;
        interfaces[2] = type(IBatchRouter).interfaceId;
        interfaces[3] = type(ICompositeLiquidityRouter).interfaceId;
        interfaces[4] = type(IBufferRouter).interfaceId;
        return interfaces;
    }

    /**
     * @notice Returns all facet addresses.
     */
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](9);
        facetAddresses_[0] = address(ROUTER_SWAP_FACET);
        facetAddresses_[1] = address(ROUTER_ADD_LIQUIDITY_FACET);
        facetAddresses_[2] = address(ROUTER_REMOVE_LIQUIDITY_FACET);
        facetAddresses_[3] = address(ROUTER_INITIALIZE_FACET);
        facetAddresses_[4] = address(ROUTER_COMMON_FACET);
        facetAddresses_[5] = address(BATCH_SWAP_FACET);
        facetAddresses_[6] = address(BUFFER_ROUTER_FACET);
        facetAddresses_[7] = address(COMPOSITE_LIQUIDITY_ERC4626_FACET);
        facetAddresses_[8] = address(COMPOSITE_LIQUIDITY_NESTED_FACET);
    }

    /**
     * @notice Returns package metadata.
     */
    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    /**
     * @notice Returns the facet cuts for diamond construction.
     */
    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](9);

        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(ROUTER_SWAP_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: ROUTER_SWAP_FACET.facetFuncs()
        });

        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(ROUTER_ADD_LIQUIDITY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: ROUTER_ADD_LIQUIDITY_FACET.facetFuncs()
        });

        facetCuts_[2] = IDiamond.FacetCut({
            facetAddress: address(ROUTER_REMOVE_LIQUIDITY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: ROUTER_REMOVE_LIQUIDITY_FACET.facetFuncs()
        });

        facetCuts_[3] = IDiamond.FacetCut({
            facetAddress: address(ROUTER_INITIALIZE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: ROUTER_INITIALIZE_FACET.facetFuncs()
        });

        facetCuts_[4] = IDiamond.FacetCut({
            facetAddress: address(ROUTER_COMMON_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: ROUTER_COMMON_FACET.facetFuncs()
        });

        facetCuts_[5] = IDiamond.FacetCut({
            facetAddress: address(BATCH_SWAP_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BATCH_SWAP_FACET.facetFuncs()
        });

        facetCuts_[6] = IDiamond.FacetCut({
            facetAddress: address(BUFFER_ROUTER_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BUFFER_ROUTER_FACET.facetFuncs()
        });

        facetCuts_[7] = IDiamond.FacetCut({
            facetAddress: address(COMPOSITE_LIQUIDITY_ERC4626_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: COMPOSITE_LIQUIDITY_ERC4626_FACET.facetFuncs()
        });

        facetCuts_[8] = IDiamond.FacetCut({
            facetAddress: address(COMPOSITE_LIQUIDITY_NESTED_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: COMPOSITE_LIQUIDITY_NESTED_FACET.facetFuncs()
        });

        return facetCuts_;
    }

    /**
     * @notice Returns the diamond configuration.
     */
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({
            facetCuts: facetCuts(),
            interfaces: facetInterfaces()
        });
    }

    /**
     * @notice Calculates the deterministic salt for deployment.
     */
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        // Salt is derived from the deployment args
        return pkgArgs._hash();
    }

    /**
     * @notice Processes deployment arguments (validation/normalization).
     */
    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        // No special processing needed - just return as-is
        return pkgArgs;
    }

    /**
     * @notice Updates an existing deployment (not supported for Router).
     */
    function updatePkg(
        address, // expectedProxy
        bytes memory // pkgArgs
    ) public virtual returns (bool) {
        // Router doesn't support updates after deployment
        return false;
    }

    /**
     * @notice Initializes the router storage on the deployed proxy.
     * @dev Called via delegatecall from the proxy during deployment.
     */
    function initAccount(bytes memory initArgs) public {
        PkgArgs memory decodedArgs = abi.decode(initArgs, (PkgArgs));

        BalancerV3RouterStorageRepo._initialize(
            decodedArgs.vault,
            decodedArgs.weth,
            decodedArgs.permit2,
            decodedArgs.routerVersion
        );
    }

    /**
     * @notice Post-deployment hook.
     * @dev Router doesn't need any post-deployment registration.
     */
    function postDeploy(address) public pure returns (bool) {
        return true;
    }
}
