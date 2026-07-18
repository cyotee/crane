// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";
import {ICallTargetRegistryManagement} from "@crane/contracts/interfaces/ICallTargetRegistryManagement.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

// tag::ICallTargetRegistryDFPkg[]
interface ICallTargetRegistryDFPkg is IDiamondFactoryPackage {
    // tag::PkgInit[]
    /// @dev Constructor args for the CallTargetRegistryDFPkg. Contains the canonical facets
    ///      that will be bundled into the CallTargetRegistry Diamond (Cut + ownership + query + management).
    struct PkgInit {
        IFacet diamondCutFacet;
        IFacet multiStepOwnableFacet;
        IFacet callTargetRegistryQueryFacet;
        IFacet callTargetRegistryManagementFacet;
        IDiamondPackageCallBackFactory diamondFactory;
    }

    // end::PkgInit[]

    // tag::PkgArgs[]
    /// @dev Args passed when deploying a CallTargetRegistry instance via the DFPkg.
    struct PkgArgs {
        address owner;
    }
    // end::PkgArgs[]

    // tag::deployCallTargetRegistry[]
    /// @notice Deploys a fully configured CallTargetRegistry Diamond proxy (with supporting facets).
    /// @param owner Initial owner (receives MultiStepOwnable control).
    /// @return The deployed IDiamond (CallTarget registry proxy).
    /// @custom:signature deployCallTargetRegistry(address)
    /// @custom:selector 0x26d10134
    function deployCallTargetRegistry(address owner) external returns (IDiamond);
    // end::deployCallTargetRegistry[]
}

// end::ICallTargetRegistryDFPkg[]

// tag::CallTargetRegistryDFPkg[]
contract CallTargetRegistryDFPkg is ICallTargetRegistryDFPkg {
    using BetterEfficientHashLib for bytes;

    ICallTargetRegistryDFPkg immutable SELF;

    IFacet public immutable DIAMOND_CUT_FACET;
    IFacet public immutable MULTI_STEP_OWNABLE_FACET;
    IFacet public immutable CALL_TARGET_REGISTRY_QUERY_FACET;
    IFacet public immutable CALL_TARGET_REGISTRY_MANAGEMENT_FACET;
    IDiamondPackageCallBackFactory public immutable DIAMOND_FACTORY;

    // tag::constructor-calltargetdfpkg[]
    /// @notice Constructs the package, capturing all facet references that will be attached
    ///         to every CallTargetRegistry Diamond deployed from it.
    constructor(PkgInit memory pkgInit) {
        SELF = this;
        DIAMOND_CUT_FACET = pkgInit.diamondCutFacet;
        MULTI_STEP_OWNABLE_FACET = pkgInit.multiStepOwnableFacet;
        CALL_TARGET_REGISTRY_QUERY_FACET = pkgInit.callTargetRegistryQueryFacet;
        CALL_TARGET_REGISTRY_MANAGEMENT_FACET = pkgInit.callTargetRegistryManagementFacet;
        DIAMOND_FACTORY = pkgInit.diamondFactory;
    }

    // end::constructor-calltargetdfpkg[]

    // tag::deployCallTargetRegistry-impl[]
    /// @notice Deploys a fully configured CallTargetRegistry Diamond proxy (with supporting facets).
    /// @param owner Initial owner (receives MultiStepOwnable control).
    /// @return The deployed IDiamond (CallTarget registry proxy).
    /// @custom:signature deployCallTargetRegistry(address)
    /// @custom:selector 0x26d10134
    /// @inheritdoc ICallTargetRegistryDFPkg
    function deployCallTargetRegistry(address owner) external returns (IDiamond) {
        return IDiamond(DIAMOND_FACTORY.deploy(SELF, abi.encode(PkgArgs({owner: owner}))));
    }

    // end::deployCallTargetRegistry-impl[]

    // tag::packageName-calltarget[]
    /// @notice Returns the canonical name of this Diamond Factory Package.
    /// @return name_ The package name string.
    /// @custom:signature packageName()
    /// @custom:selector 0xabc8b346
    /// @inheritdoc IDiamondFactoryPackage
    function packageName() public pure returns (string memory name_) {
        return type(CallTargetRegistryDFPkg).name;
    }

    // end::packageName-calltarget[]

    // tag::packageMetadata-calltarget[]
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

    // end::packageMetadata-calltarget[]

    // tag::facetAddresses-calltarget[]
    /// @notice Returns the addresses of all facet implementations provided by this DFPkg.
    /// @return facetAddresses_ Array of 4 facet addresses in package order.
    /// @custom:signature facetAddresses()
    /// @custom:selector 0x52ef6b2c
    /// @inheritdoc IDiamondFactoryPackage
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](4);
        facetAddresses_[0] = address(DIAMOND_CUT_FACET);
        facetAddresses_[1] = address(MULTI_STEP_OWNABLE_FACET);
        facetAddresses_[2] = address(CALL_TARGET_REGISTRY_QUERY_FACET);
        facetAddresses_[3] = address(CALL_TARGET_REGISTRY_MANAGEMENT_FACET);
    }

    // end::facetAddresses-calltarget[]

    // tag::facetInterfaces-calltarget[]
    /// @notice Returns the ERC-165 interface IDs supported by the facets in this package.
    /// @return interfaces Array of 4 interface IDs corresponding to the bundled facets.
    /// @custom:signature facetInterfaces()
    /// @custom:selector 0x2ea80826
    /// @inheritdoc IDiamondFactoryPackage
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](4);
        interfaces[0] = type(IDiamondCut).interfaceId;
        interfaces[1] = type(IMultiStepOwnable).interfaceId;
        interfaces[2] = type(ICallTargetRegistryQuery).interfaceId;
        interfaces[3] = type(ICallTargetRegistryManagement).interfaceId;
    }

    // end::facetInterfaces-calltarget[]

    // tag::facetCuts-calltarget[]
    /// @notice Returns the facet cuts (add actions) needed to install this package's facets on a Diamond.
    /// @return facetCuts_ Array of 4 FacetCut structs for DiamondCut.
    /// @custom:signature facetCuts()
    /// @custom:selector 0xa4b3ad35
    /// @inheritdoc IDiamondFactoryPackage
    function facetCuts() public view returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](4);
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
            facetAddress: address(CALL_TARGET_REGISTRY_QUERY_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: CALL_TARGET_REGISTRY_QUERY_FACET.facetFuncs()
        });
        facetCuts_[3] = IDiamond.FacetCut({
            facetAddress: address(CALL_TARGET_REGISTRY_MANAGEMENT_FACET),
            action: IDiamond.FacetCutAction.Add,
            functionSelectors: CALL_TARGET_REGISTRY_MANAGEMENT_FACET.facetFuncs()
        });
    }

    // end::facetCuts-calltarget[]

    // tag::diamondConfig-calltarget[]
    /// @notice Returns the full diamond configuration (facet cuts + interfaces) for instantiating a Diamond from this package.
    /// @return config The DiamondConfig struct containing cuts and interfaces.
    /// @custom:signature diamondConfig()
    /// @custom:selector 0x65d375b3
    /// @inheritdoc IDiamondFactoryPackage
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    // end::diamondConfig-calltarget[]

    // tag::calcSalt-calltarget[]
    /// @notice Computes the CREATE3 salt for a given package deployment args (used for deterministic proxy address).
    /// @param pkgArgs The encoded PkgArgs for the deployment.
    /// @return salt The derived bytes32 salt (hash of pkgArgs).
    /// @custom:signature calcSalt(bytes)
    /// @custom:selector 0xd82be56e
    /// @inheritdoc IDiamondFactoryPackage
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        return pkgArgs._hash();
    }

    // end::calcSalt-calltarget[]

    // tag::processArgs-calltarget[]
    /// @notice Processes (and here, passthrough) the package args prior to use in deployment/calc.
    /// @param pkgArgs The raw PkgArgs bytes.
    /// @return processedPkgArgs The processed bytes (identity in this impl).
    /// @custom:signature processArgs(bytes)
    /// @custom:selector 0x87c3adb3
    /// @inheritdoc IDiamondFactoryPackage
    function processArgs(bytes memory pkgArgs) public pure returns (bytes memory processedPkgArgs) {
        return pkgArgs;
    }

    // end::processArgs-calltarget[]

    // tag::updatePkg-calltarget[]
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

    // end::updatePkg-calltarget[]

    // tag::initAccount-calltarget[]
    /// @notice Initializes the deployed Diamond proxy account (called via delegatecall by factory). Sets up MultiStepOwnable ownership.
    /// @param initArgs The encoded PkgArgs containing the initial owner.
    /// @custom:signature initAccount(bytes)
    /// @custom:selector 0x870d4838
    /// @inheritdoc IDiamondFactoryPackage
    function initAccount(bytes memory initArgs) public {
        (PkgArgs memory accountInit) = abi.decode(initArgs, (PkgArgs));
        MultiStepOwnableRepo._initialize(accountInit.owner, 1 days);
    }

    // end::initAccount-calltarget[]

    // tag::postDeploy-calltarget[]
    /// @notice Post-deployment hook (no-op for this package; returns true).
    /// @param account (unused) The address of the deployed proxy.
    /// @return True to indicate success.
    /// @custom:signature postDeploy(address)
    /// @custom:selector 0x70068fcf
    /// @inheritdoc IDiamondFactoryPackage
    function postDeploy(address account) public pure returns (bool) {
        return true;
    }
    // end::postDeploy-calltarget[]
}
// end::CallTargetRegistryDFPkg[]
