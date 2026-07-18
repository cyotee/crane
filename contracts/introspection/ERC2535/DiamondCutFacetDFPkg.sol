// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterAddress as Address} from "@crane/contracts/utils/BetterAddress.sol";
import {IMultiStepOwnable} from "@crane/contracts/interfaces/IMultiStepOwnable.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {DiamondCutTarget} from "@crane/contracts/introspection/ERC2535/DiamondCutTarget.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "@crane/contracts/interfaces/ICreate3Aware.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

// tag::IDiamondCutFacetDFPkg[]
/// @title IDiamondCutFacetDFPkg
/// @author Crane Framework
/// @notice Interface for the DiamondCutFacetDFPkg (core DFPkg bundling DiamondCut + MultiStepOwnable).
/// @dev PkgInit and PkgArgs structs are defined here (per AGENTS.md critical rule for DFPkgs).
///      This package is used to bootstrap minimal Diamonds with cut and ownership surfaces.
///      See IDiamondFactoryPackage for the inherited base surface.
interface IDiamondCutFacetDFPkg is IDiamondFactoryPackage {
    // tag::PkgInit[]
    /// @dev Constructor args for the DiamondCutFacetDFPkg. Contains the canonical facets
    ///      that will be bundled into the Diamond (Cut + ownership).
    struct PkgInit {
        IFacet diamondCutFacet;
        IFacet multiStepOwnableFacet;
    }

    // end::PkgInit[]

    // tag::PkgArgs[]
    /// @dev Args passed when deploying a Diamond instance via the DFPkg (owner + optional post-cut init).
    struct PkgArgs {
        address owner;
        // bytes diamondCutData;
        IDiamond.FacetCut[] diamondCut;
        bytes4[] supportedInterfaces;
        address initTarget;
        bytes initCalldata;
    }
    // end::PkgArgs[]
}

// end::IDiamondCutFacetDFPkg[]

// TODO Rename to DiamondCutDFPkg
// tag::DiamondCutFacetDFPkg[]
/**
 * @title DiamondCutFacetDFPkg
 * @author Crane Framework
 * @notice Diamond Factory Package bundling the DiamondCut facet and MultiStepOwnable facet
 *         for deterministic deployment of minimal upgradeable Diamonds.
 * @dev Implements IDiamondFactoryPackage. Constructor takes IDiamondCutFacetDFPkg.PkgInit
 *      (structs live on interface per AGENTS.md rule). All proxies from this package receive
 *      the same two facets via facetCuts.
 *      Used by IntrospectionFacetFactoryService and core test/dev bootstraps.
 */
contract DiamondCutFacetDFPkg is IDiamondCutFacetDFPkg {
    using Address for address;

    // IDiamondFactoryPackage immutable SELF;
    IFacet immutable DIAMOND_CUT_FACET;
    IFacet immutable MULTI_STEP_OWNABLE_FACET;

    // tag::constructor(IDiamondCutFacetDFPkg.PkgInit)[]
    /// @notice Constructs the package, capturing the two facet references that will be attached
    ///         to every Diamond deployed from it.
    /// @param pkgInitArgs Contains the deployed diamondCutFacet and multiStepOwnableFacet.
    /// @custom:signature constructor(IDiamondCutFacetDFPkg.PkgInit)
    constructor(PkgInit memory pkgInitArgs) {
        // PkgInit memory pkgInitArgs = abi.decode(create3InitData.initData, (PkgInit));
        // SELF = this;
        DIAMOND_CUT_FACET = pkgInitArgs.diamondCutFacet;
        MULTI_STEP_OWNABLE_FACET = pkgInitArgs.multiStepOwnableFacet;
    }

    // end::constructor(IDiamondCutFacetDFPkg.PkgInit)[]

    // tag::packageName-diamondcutfacetdfpkg[]
    /// @notice Returns the canonical name of this Diamond Factory Package.
    /// @return name_ The package name string.
    /// @custom:signature packageName()
    /// @custom:selector 0xabc8b346
    /// @inheritdoc IDiamondFactoryPackage
    function packageName() public pure returns (string memory name_) {
        return type(DiamondCutFacetDFPkg).name;
    }

    // end::packageName-diamondcutfacetdfpkg[]

    // tag::packageMetadata-diamondcutfacetdfpkg[]
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
        name_ = packageName();
        interfaces = facetInterfaces();
        facets = facetAddresses();
    }

    // end::packageMetadata-diamondcutfacetdfpkg[]

    // tag::facetAddresses-diamondcutfacetdfpkg[]
    /// @notice Returns the addresses of all facet implementations provided by this DFPkg.
    /// @return facetAddresses_ Array of 2 facet addresses in package order (multiStepOwnable, diamondCut).
    /// @custom:signature facetAddresses()
    /// @custom:selector 0x52ef6b2c
    /// @inheritdoc IDiamondFactoryPackage
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](2);
        facetAddresses_[0] = address(DIAMOND_CUT_FACET);
        facetAddresses_[1] = address(MULTI_STEP_OWNABLE_FACET);
    }

    // end::facetAddresses-diamondcutfacetdfpkg[]

    // tag::facetInterfaces-diamondcutfacetdfpkg[]
    /// @notice Returns the ERC-165 interface IDs supported by the facets in this package.
    /// @return interfaces Array of 2 interface IDs corresponding to the bundled facets.
    /// @custom:signature facetInterfaces()
    /// @custom:selector 0x2ea80826
    /// @inheritdoc IDiamondFactoryPackage
    function facetInterfaces() public view virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IMultiStepOwnable).interfaceId;
        interfaces[1] = type(IDiamondCut).interfaceId;
    }

    // end::facetInterfaces-diamondcutfacetdfpkg[]

    // tag::facetCuts-diamondcutfacetdfpkg[]
    /// @notice Returns the facet cuts (add actions) needed to install this package's facets on a Diamond.
    /// @return facetCuts_ Array of 2 FacetCut structs for DiamondCut.
    /// @custom:signature facetCuts()
    /// @custom:selector 0xa4b3ad35
    /// @inheritdoc IDiamondFactoryPackage
    function facetCuts() public view virtual override returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](2);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(MULTI_STEP_OWNABLE_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: MULTI_STEP_OWNABLE_FACET.facetFuncs()
        });
        facetCuts_[1] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(DIAMOND_CUT_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: DIAMOND_CUT_FACET.facetFuncs()
        });
    }

    // end::facetCuts-diamondcutfacetdfpkg[]

    // tag::diamondConfig-diamondcutfacetdfpkg[]
    /// @notice Returns the full diamond configuration (facet cuts + interfaces) for instantiating a Diamond from this package.
    /// @return config The DiamondConfig struct containing cuts and interfaces.
    /// @custom:signature diamondConfig()
    /// @custom:selector 0x65d375b3
    /// @inheritdoc IDiamondFactoryPackage
    function diamondConfig() public view virtual returns (IDiamondFactoryPackage.DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    // end::diamondConfig-diamondcutfacetdfpkg[]

    // tag::calcSalt-diamondcutfacetdfpkg[]
    /// @notice Computes the CREATE3 salt for a given package deployment args (used for deterministic proxy address).
    /// @param pkgArgs The encoded PkgArgs for the deployment.
    /// @return salt The derived bytes32 salt (hash of pkgArgs).
    /// @custom:signature calcSalt(bytes)
    /// @custom:selector 0xd82be56e
    /// @inheritdoc IDiamondFactoryPackage
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        salt = keccak256(abi.encode(pkgArgs));
    }

    // end::calcSalt-diamondcutfacetdfpkg[]

    // tag::processArgs-diamondcutfacetdfpkg[]
    /// @notice Processes (and here, passthrough) the package args prior to use in deployment/calc.
    /// @param pkgArgs The raw PkgArgs bytes.
    /// @return processedPkgArgs The processed bytes (identity in this impl).
    /// @custom:signature processArgs(bytes)
    /// @custom:selector 0x87c3adb3
    /// @inheritdoc IDiamondFactoryPackage
    function processArgs(bytes memory pkgArgs)
        public
        pure
        returns (
            // bytes32 salt,
            bytes memory processedPkgArgs
        )
    {
        // salt = keccak256(abi.encode(pkgArgs));
        processedPkgArgs = pkgArgs;
    }

    // end::processArgs-diamondcutfacetdfpkg[]

    // tag::updatePkg-diamondcutfacetdfpkg[]
    /// @notice Hook for post-deploy package update validation (returns true, no-op here).
    /// @return True (update always accepted for this package).
    /// @custom:signature updatePkg(address,bytes)
    /// @custom:selector 0xa9089235
    /// @inheritdoc IDiamondFactoryPackage
    function updatePkg(
        address, // expectedProxy,
        bytes memory // pkgArgs
    )
        public
        virtual
        returns (bool)
    {
        return true;
    }

    // end::updatePkg-diamondcutfacetdfpkg[]

    // tag::initAccount-diamondcutfacetdfpkg[]
    /// @notice Initializes the deployed Diamond proxy account (called via delegatecall by factory).
    ///         Sets up MultiStepOwnable ownership, applies optional diamondCut, and registers interfaces.
    /// @param initArgs The encoded PkgArgs containing the initial owner, optional diamondCut, supportedInterfaces, initTarget and initCalldata.
    /// @custom:signature initAccount(bytes)
    /// @custom:selector 0x870d4838
    /// @inheritdoc IDiamondFactoryPackage
    function initAccount(bytes memory initArgs) public virtual override {
        (PkgArgs memory accountInit) = abi.decode(initArgs, (PkgArgs));
        MultiStepOwnableRepo._initialize(accountInit.owner, 1 days);
        if (accountInit.diamondCut.length > 0) {
            ERC2535Repo._diamondCut(accountInit.diamondCut, accountInit.initTarget, accountInit.initCalldata);
        }
        if (accountInit.supportedInterfaces.length > 0) {
            ERC165Repo._registerInterfaces(accountInit.supportedInterfaces);
        }
    }

    // end::initAccount-diamondcutfacetdfpkg[]

    // tag::postDeploy-diamondcutfacetdfpkg[]
    /// @notice Post-deployment hook (no-op for this package; returns true).
    /// @return True to indicate success.
    /// @custom:signature postDeploy(address)
    /// @custom:selector 0x70068fcf
    /// @inheritdoc IDiamondFactoryPackage
    function postDeploy(address) public virtual returns (bool) {
        return true;
    }
    // end::postDeploy-diamondcutfacetdfpkg[]
}
// end::DiamondCutFacetDFPkg[]
