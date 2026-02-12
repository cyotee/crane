// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Solady                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {ICowRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowRouter.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";
import {BalancerV3AuthenticationRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationRepo.sol";
import {CowRouterRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterRepo.sol";

/**
 * @title ICowRouterDFPkg
 * @notice Interface for CowRouterDFPkg constructor and deployment arguments.
 */
interface ICowRouterDFPkg {
    /**
     * @notice Constructor arguments for the package.
     * @param balancerV3VaultAwareFacet Facet for vault awareness.
     * @param balancerV3AuthenticationFacet Facet for action authentication.
     * @param cowRouterFacet Facet for CoW router functionality.
     * @param balancerV3Vault The Balancer V3 vault address.
     * @param diamondFactory The diamond package factory for deployments.
     */
    struct PkgInit {
        IFacet balancerV3VaultAwareFacet;
        IFacet balancerV3AuthenticationFacet;
        IFacet cowRouterFacet;
        IVault balancerV3Vault;
        IDiamondPackageCallBackFactory diamondFactory;
    }

    /**
     * @notice Deployment arguments for each router instance.
     * @param protocolFeePercentage Fee charged on donations (18-decimal FP, max 50%).
     * @param feeSweeper Address that receives collected protocol fees.
     */
    struct PkgArgs {
        uint256 protocolFeePercentage;
        address feeSweeper;
    }

    /**
     * @notice Deploy a new CoW router.
     * @param protocolFeePercentage Fee percentage (max 50%).
     * @param feeSweeper Address to receive fees.
     * @return router The deployed router address.
     */
    function deployRouter(
        uint256 protocolFeePercentage,
        address feeSweeper
    ) external returns (address router);
}

/**
 * @title CowRouterDFPkg
 * @notice Diamond Factory Package for deploying Balancer V3 CoW Routers.
 * @dev CoW Routers handle MEV-protected swaps and surplus donations for CoW Protocol.
 *
 * Key features:
 * - Swap + Donate in single transaction (for MEV surplus capture)
 * - Pure donate functionality
 * - Protocol fee collection on donations
 * - Fee withdrawal to configurable sweeper
 *
 * Storage initialization:
 * - CowRouterRepo: protocolFeePercentage, feeSweeper
 * - BalancerV3VaultAwareRepo: vault reference
 * - BalancerV3AuthenticationRepo: action ID root
 */
contract CowRouterDFPkg is IDiamondFactoryPackage, ICowRouterDFPkg {
    using BetterEfficientHashLib for bytes;

    IVault public immutable BALANCER_V3_VAULT;
    IDiamondPackageCallBackFactory public immutable DIAMOND_PACKAGE_FACTORY;

    IFacet public immutable BALANCER_V3_VAULT_AWARE_FACET;
    IFacet public immutable BALANCER_V3_AUTHENTICATION_FACET;
    IFacet public immutable COW_ROUTER_FACET;

    error InvalidFeeSweeper();
    error ProtocolFeePercentageAboveLimit(uint256 provided, uint256 max);

    constructor(PkgInit memory pkgInit) {
        BALANCER_V3_VAULT = pkgInit.balancerV3Vault;
        DIAMOND_PACKAGE_FACTORY = pkgInit.diamondFactory;
        BALANCER_V3_VAULT_AWARE_FACET = pkgInit.balancerV3VaultAwareFacet;
        BALANCER_V3_AUTHENTICATION_FACET = pkgInit.balancerV3AuthenticationFacet;
        COW_ROUTER_FACET = pkgInit.cowRouterFacet;

        // Initialize authentication with package's action ID root
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );

        // Initialize vault repo for later operations
        BalancerV3VaultAwareRepo._initialize(pkgInit.balancerV3Vault);
    }

    /**
     * @notice Deploy a new CoW router.
     * @param protocolFeePercentage_ Fee percentage on donations (max 50%).
     * @param feeSweeper_ Address to receive collected fees.
     * @return router The deployed router proxy address.
     */
    function deployRouter(
        uint256 protocolFeePercentage_,
        address feeSweeper_
    ) public returns (address router) {
        router = DIAMOND_PACKAGE_FACTORY.deploy(
            this,
            abi.encode(
                PkgArgs({
                    protocolFeePercentage: protocolFeePercentage_,
                    feeSweeper: feeSweeper_
                })
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         IDiamondFactoryPackage                         */
    /* ---------------------------------------------------------------------- */

    function packageName() public pure returns (string memory name_) {
        return type(CowRouterDFPkg).name;
    }

    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IBalancerV3VaultAware).interfaceId;
        interfaces[1] = type(ICowRouter).interfaceId;
        return interfaces;
    }

    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](3);
        facetAddresses_[0] = address(BALANCER_V3_VAULT_AWARE_FACET);
        facetAddresses_[1] = address(BALANCER_V3_AUTHENTICATION_FACET);
        facetAddresses_[2] = address(COW_ROUTER_FACET);
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
        facetCuts_ = new IDiamond.FacetCut[](3);

        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(BALANCER_V3_VAULT_AWARE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_VAULT_AWARE_FACET.facetFuncs()
        });

        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(BALANCER_V3_AUTHENTICATION_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: BALANCER_V3_AUTHENTICATION_FACET.facetFuncs()
        });

        facetCuts_[2] = IDiamond.FacetCut({
            facetAddress: address(COW_ROUTER_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: COW_ROUTER_FACET.facetFuncs()
        });

        return facetCuts_;
    }

    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    /**
     * @notice Calculate deterministic salt from router parameters.
     * @dev Includes fee percentage and sweeper for unique router addresses.
     */
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        PkgArgs memory decodedArgs = abi.decode(pkgArgs, (PkgArgs));

        // Validate fee sweeper
        if (decodedArgs.feeSweeper == address(0)) {
            revert InvalidFeeSweeper();
        }

        // Validate protocol fee percentage
        if (decodedArgs.protocolFeePercentage > CowRouterRepo.MAX_PROTOCOL_FEE_PERCENTAGE) {
            revert ProtocolFeePercentageAboveLimit(
                decodedArgs.protocolFeePercentage,
                CowRouterRepo.MAX_PROTOCOL_FEE_PERCENTAGE
            );
        }

        // Hash all parameters for deterministic salt
        return abi.encode(pkgArgs)._hash();
    }

    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        // No processing needed for router args
        return pkgArgs;
    }

    function updatePkg(address, bytes memory) public virtual returns (bool) {
        // No per-proxy state to update for routers
        return true;
    }

    /**
     * @notice Initialize the router's storage during deployment.
     * @dev Called via delegatecall on the proxy during CREATE2 deployment.
     * Initializes CowRouterRepo with fee settings for withdrawCollectedProtocolFees to work.
     */
    function initAccount(bytes memory initArgs) public {
        PkgArgs memory decodedArgs = abi.decode(initArgs, (PkgArgs));

        // Initialize vault awareness for router operations
        BalancerV3VaultAwareRepo._initialize(BALANCER_V3_VAULT);

        // Initialize authentication with package's action ID root
        BalancerV3AuthenticationRepo._initialize(
            keccak256(abi.encode(address(this)))
        );

        // CRITICAL: Initialize CoW router storage with fee settings
        // This is required for withdrawCollectedProtocolFees to work
        CowRouterRepo._initialize(
            decodedArgs.protocolFeePercentage,
            decodedArgs.feeSweeper
        );
    }

    /**
     * @notice No post-deploy actions needed for routers.
     * @dev Routers don't need vault registration like pools do.
     */
    function postDeploy(address) public pure returns (bool) {
        return true;
    }
}
