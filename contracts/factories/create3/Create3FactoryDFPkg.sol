// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IFacetRegistry} from "@crane/contracts/registries/facet/IFacetRegistry.sol";
import {IDiamondFactoryPackageRegistry} from "@crane/contracts/registries/package/IDiamondFactoryPackageRegistry.sol";
import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";
import {ICallTargetRegistryManagement} from "@crane/contracts/interfaces/ICallTargetRegistryManagement.sol";
import {IOperable} from "@crane/contracts/interfaces/IOperable.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

// tag::ICREATE3DFPkg[]
interface ICREATE3DFPkg is IDiamondFactoryPackage {
    // tag::PkgInit-create3[]
    /// @dev Constructor args for the Create3FactoryDFPkg. Contains the canonical facets
    ///      that will be bundled into the Create3Factory Diamond (Cut + ownership + operable + registries).
    struct PkgInit {
        // Historical/introspection facets are commented because the minimal bootstrap
        // for the Create3Factory itself only needs the operational surface.
        IFacet diamondCutFacet;
        IFacet multiStepOwnableFacet;
        IFacet operableFacet;
        IFacet create3FactoryFacet;
        IFacet facetRegistryFacet;
        IFacet packageRegistryFacet;
        IFacet callTargetRegistryQueryFacet;
        IFacet callTargetRegistryManagementFacet;
        IDiamondPackageCallBackFactory diamondFactory;
    }

    // end::PkgInit-create3[]

    // tag::PkgArgs-create3[]
    /// @dev Args passed when deploying a Create3Factory instance via the DFPkg.
    struct PkgArgs {
        address owner;
    }
    // end::PkgArgs-create3[]

    // tag::deployCreate3Factory[]
    /// @notice Deploys a fully configured Create3Factory Diamond proxy (with supporting facets).
    /// @param owner Initial owner (receives MultiStepOwnable + Operable control).
    /// @return The deployed ICreate3FactoryProxy (also a Diamond).
    /// @custom:signature deployCreate3Factory(address)
    /// @custom:selector 0x34cb11b5
    function deployCreate3Factory(address owner) external returns (ICreate3FactoryProxy);
    // end::deployCreate3Factory[]
}

// end::ICREATE3DFPkg[]

// tag::Create3FactoryDFPkg[]
contract Create3FactoryDFPkg is ICREATE3DFPkg {
    using BetterEfficientHashLib for bytes;

    ICREATE3DFPkg immutable SELF;

    // Historical introspection facets (commented) were part of fuller bootstrap in the past.
    IFacet public immutable DIAMOND_CUT_FACET;
    IFacet public immutable MULTI_STEP_OWNABLE_FACET;
    IFacet public immutable OPERABLE_FACET;
    IFacet public immutable CREATE3_FACTORY_FACET;
    IFacet public immutable FACET_REGISTRY_FACET;
    IFacet public immutable DIAMOND_FACTORY_PACKAGE_FACET;
    IFacet public immutable CALL_TARGET_REGISTRY_QUERY_FACET;
    IFacet public immutable CALL_TARGET_REGISTRY_MANAGEMENT_FACET;

    IDiamondPackageCallBackFactory public immutable DIAMOND_FACTORY;

    // tag::constructor-create3dfpkg[]
    /// @notice Constructs the package, capturing all facet references that will be attached
    ///         to every Create3Factory Diamond deployed from it.
    constructor(PkgInit memory pkgInit) {
        SELF = this;
        DIAMOND_CUT_FACET = pkgInit.diamondCutFacet;
        MULTI_STEP_OWNABLE_FACET = pkgInit.multiStepOwnableFacet;
        OPERABLE_FACET = pkgInit.operableFacet;
        CREATE3_FACTORY_FACET = pkgInit.create3FactoryFacet;
        FACET_REGISTRY_FACET = pkgInit.facetRegistryFacet;
        DIAMOND_FACTORY_PACKAGE_FACET = pkgInit.packageRegistryFacet;
        CALL_TARGET_REGISTRY_QUERY_FACET = pkgInit.callTargetRegistryQueryFacet;
        CALL_TARGET_REGISTRY_MANAGEMENT_FACET = pkgInit.callTargetRegistryManagementFacet;
        DIAMOND_FACTORY = pkgInit.diamondFactory;
    }

    // end::constructor-create3dfpkg[]

    // tag::deployCreate3Factory-impl[]
    /// @notice Deploys a fully configured Create3Factory Diamond proxy (with supporting facets).
    /// @param owner Initial owner (receives MultiStepOwnable + Operable control).
    /// @return The deployed ICreate3FactoryProxy (also a Diamond).
    /// @custom:signature deployCreate3Factory(address)
    /// @custom:selector 0x34cb11b5
    /// @inheritdoc ICREATE3DFPkg
    function deployCreate3Factory(address owner) external returns (ICreate3FactoryProxy) {
        return ICreate3FactoryProxy(DIAMOND_FACTORY.deploy(SELF, abi.encode(PkgArgs({owner: owner}))));
    }

    // end::deployCreate3Factory-impl[]

    // tag::packageName-create3[]
    /// @notice Returns the canonical name of this Diamond Factory Package.
    /// @return name_ The package name string.
    /// @custom:signature packageName()
    /// @custom:selector 0xabc8b346
    /// @inheritdoc IDiamondFactoryPackage
    function packageName() public pure returns (string memory name_) {
        return type(Create3FactoryDFPkg).name;
    }

    // end::packageName-create3[]

    // tag::packageMetadata-create3[]
    /// @notice Returns the full metadata for this package (name, supported interfaces, facet addresses).
    /// @return name_ The package name.
    /// @return interfaces The interface IDs provided by the package's facets.
    /// @return facets The addresses of the bundled facets.
    /// @custom:signature packageMetadata()
    /// @custom:selector 0xf45469e7
    /// @inheritdoc IDiamondFactoryPackage
    function packageMetadata()
        public
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets)
    {
        return (packageName(), facetInterfaces(), facetAddresses());
    }

    // end::packageMetadata-create3[]

    // tag::facetAddresses-create3[]
    /// @notice Returns the addresses of all facet implementations provided by this DFPkg.
    /// @return facetAddresses_ Array of 8 facet addresses in package order.
    /// @custom:signature facetAddresses()
    /// @custom:selector 0x52ef6b2c
    /// @inheritdoc IDiamondFactoryPackage
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](8);
        facetAddresses_[0] = address(DIAMOND_CUT_FACET);
        facetAddresses_[1] = address(MULTI_STEP_OWNABLE_FACET);
        facetAddresses_[2] = address(OPERABLE_FACET);
        facetAddresses_[3] = address(CREATE3_FACTORY_FACET);
        facetAddresses_[4] = address(FACET_REGISTRY_FACET);
        facetAddresses_[5] = address(DIAMOND_FACTORY_PACKAGE_FACET);
        facetAddresses_[6] = address(CALL_TARGET_REGISTRY_QUERY_FACET);
        facetAddresses_[7] = address(CALL_TARGET_REGISTRY_MANAGEMENT_FACET);
    }

    // end::facetAddresses-create3[]

    // tag::facetInterfaces-create3[]
    /// @notice Returns the ERC-165 interface IDs supported by the facets in this package.
    /// @return interfaces Array of 8 interface IDs corresponding to the bundled facets.
    /// @custom:signature facetInterfaces()
    /// @custom:selector 0x2ea80826
    /// @inheritdoc IDiamondFactoryPackage
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](8);
        interfaces[0] = type(IDiamondCut).interfaceId;
        interfaces[1] = type(IMultiStepOwnable).interfaceId;
        interfaces[2] = type(IOperable).interfaceId;
        interfaces[3] = type(ICreate3Factory).interfaceId;
        interfaces[4] = type(IFacetRegistry).interfaceId;
        interfaces[5] = type(IDiamondFactoryPackageRegistry).interfaceId;
        interfaces[6] = type(ICallTargetRegistryQuery).interfaceId;
        interfaces[7] = type(ICallTargetRegistryManagement).interfaceId;
    }

    // end::facetInterfaces-create3[]

    // tag::facetCuts-create3[]
    /// @notice Returns the facet cuts (add actions) needed to install this package's facets on a Diamond.
    /// @return facetCuts_ Array of 8 FacetCut structs for DiamondCut.
    /// @custom:signature facetCuts()
    /// @custom:selector 0xa4b3ad35
    /// @inheritdoc IDiamondFactoryPackage
    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](8);
        facetCuts_[0] = IDiamond.FacetCut({
            facetAddress: address(DIAMOND_CUT_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: DIAMOND_CUT_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            facetAddress: address(MULTI_STEP_OWNABLE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: MULTI_STEP_OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[2] = IDiamond.FacetCut({
            facetAddress: address(OPERABLE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: OPERABLE_FACET.facetFuncs()
        });
        facetCuts_[3] = IDiamond.FacetCut({
            facetAddress: address(CREATE3_FACTORY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: CREATE3_FACTORY_FACET.facetFuncs()
        });
        facetCuts_[4] = IDiamond.FacetCut({
            facetAddress: address(FACET_REGISTRY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: FACET_REGISTRY_FACET.facetFuncs()
        });
        facetCuts_[5] = IDiamond.FacetCut({
            facetAddress: address(DIAMOND_FACTORY_PACKAGE_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: DIAMOND_FACTORY_PACKAGE_FACET.facetFuncs()
        });
        facetCuts_[6] = IDiamond.FacetCut({
            facetAddress: address(CALL_TARGET_REGISTRY_QUERY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: CALL_TARGET_REGISTRY_QUERY_FACET.facetFuncs()
        });
        facetCuts_[7] = IDiamond.FacetCut({
            facetAddress: address(CALL_TARGET_REGISTRY_MANAGEMENT_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: CALL_TARGET_REGISTRY_MANAGEMENT_FACET.facetFuncs()
        });
    }

    // end::facetCuts-create3[]

    // tag::diamondConfig-create3[]
    /// @notice Returns the full diamond configuration (facet cuts + interfaces) for instantiating a Diamond from this package.
    /// @return config The DiamondConfig struct containing cuts and interfaces.
    /// @custom:signature diamondConfig()
    /// @custom:selector 0x65d375b3
    /// @inheritdoc IDiamondFactoryPackage
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    // end::diamondConfig-create3[]

    // tag::calcSalt-create3[]
    /// @notice Computes the CREATE3 salt for a given package deployment args (used for deterministic proxy address).
    /// @param pkgArgs The encoded PkgArgs for the deployment.
    /// @return salt The derived bytes32 salt (hash of pkgArgs).
    /// @custom:signature calcSalt(bytes)
    /// @custom:selector 0xd82be56e
    /// @inheritdoc IDiamondFactoryPackage
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        return pkgArgs._hash();
    }

    // end::calcSalt-create3[]

    // tag::processArgs-create3[]
    /// @notice Processes (and here, passthrough) the package args prior to use in deployment/calc.
    /// @param pkgArgs The raw PkgArgs bytes.
    /// @return processedPkgArgs The processed bytes (identity in this impl).
    /// @custom:signature processArgs(bytes)
    /// @custom:selector 0x87c3adb3
    /// @inheritdoc IDiamondFactoryPackage
    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        return pkgArgs;
    }

    // end::processArgs-create3[]

    // tag::updatePkg-create3[]
    /// @notice Hook for post-deploy package update validation (returns true, no-op here).
    /// @param expectedProxy (unused) The expected proxy address.
    /// @param pkgArgs (unused) The package args.
    /// @return True (update always accepted for this package).
    /// @custom:signature updatePkg(address,bytes)
    /// @custom:selector 0xa9089235
    /// @inheritdoc IDiamondFactoryPackage
    function updatePkg(address expectedProxy, bytes memory pkgArgs) public pure returns (bool) {
        return true;
    }

    // end::updatePkg-create3[]

    // tag::initAccount-create3[]
    /// @notice Initializes the deployed Diamond proxy account (called via delegatecall by factory). Sets up MultiStepOwnable ownership.
    /// @param initArgs The encoded PkgArgs containing the initial owner.
    /// @custom:signature initAccount(bytes)
    /// @custom:selector 0x870d4838
    /// @inheritdoc IDiamondFactoryPackage
    function initAccount(bytes memory initArgs) public {
        (PkgArgs memory accountInit) = abi.decode(initArgs, (PkgArgs));
        MultiStepOwnableRepo._initialize(accountInit.owner, 1 days);
    }

    // end::initAccount-create3[]

    // tag::postDeploy-create3[]
    /// @notice Post-deployment hook (no-op for this package; returns true).
    /// @param account (unused) The address of the deployed proxy.
    /// @return True to indicate success.
    /// @custom:signature postDeploy(address)
    /// @custom:selector 0x70068fcf
    /// @inheritdoc IDiamondFactoryPackage
    function postDeploy(address account) public pure returns (bool) {
        return true;
    }
    // end::postDeploy-create3[]
}
// end::Create3FactoryDFPkg[]
