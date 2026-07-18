// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IGreeter} from "@crane/contracts/test/stubs/greeter/IGreeter.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {GreeterFacet} from "@crane/contracts/test/stubs/greeter/GreeterFacet.sol";
import {GreeterLayout, GreeterRepo} from "@crane/contracts/test/stubs/greeter/GreeterRepo.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

// tag::IGreeterDFPkg[]
/// @title IGreeterDFPkg
/// @notice Interface declaring the PkgInit/PkgArgs structs for the GreeterDFPkg (core stub DFPkg for LR-7 smoke tests and DevEnv).
/// @dev Pkg* structs MUST live on the I*DFPkg (per AGENTS.md). This package bundles a single GreeterFacet for simple Diamond proxy deployment with greeting storage.
/// @author Crane Framework
interface IGreeterDFPkg is IDiamondFactoryPackage {
    // tag::PkgInit[]
    /// @dev Constructor args for the GreeterDFPkg. Provides the reusable diamond factory (for callback deploy) and the Greeter facet implementation to attach.
    struct PkgInit {
        IDiamondPackageCallBackFactory diamondPackageFactory;
        IFacet greeterFacet;
    }

    // end::PkgInit[]

    // tag::PkgArgs[]
    /// @dev Deployment args (user-provided) for a Greeter proxy. The initMessage becomes the initial greeting.
    struct PkgArgs {
        string message;
    }
    // end::PkgArgs[]
}

// end::IGreeterDFPkg[]

// tag::GreeterDFPkg[]
/**
 * @title GreeterDFPkg
 * @notice Diamond Factory Package (stub) bundling the GreeterFacet for deterministic deployment of simple greeting-enabled Diamond proxies.
 *         Used as the core example in LR-7 smoke tests / DevEnv (via CraneTest + InitDevService).
 * @dev Extends GreeterFacet (to surface IFacet + greeting logic on the package itself for convenience) and implements IDiamondFactoryPackage.
 *      Constructor captures immutable facet + factory refs. The extra deployGreeter convenience uses the callback factory.
 *      PkgInit/PkgArgs on the companion IGreeterDFPkg interface.
 * @author Crane Framework
 */
contract GreeterDFPkg is GreeterFacet, IGreeterDFPkg {
    using BetterEfficientHashLib for bytes;

    IGreeterDFPkg immutable SELF;

    // tag::DIAMOND_FACTORY()[]
    /// @notice The IDiamondPackageCallBackFactory used to deploy proxy instances from this package.
    /// @dev Exposed as public immutable (getter auto-generated).
    IDiamondPackageCallBackFactory public immutable DIAMOND_FACTORY;
    // end::DIAMOND_FACTORY()[]

    // tag::GREETER_FACET()[]
    /// @notice The Greeter facet implementation attached to every Diamond deployed by this package.
    /// @dev Exposed as public immutable (getter auto-generated). Used in facetCuts / facetAddresses.
    IFacet public immutable GREETER_FACET;

    // end::GREETER_FACET()[]

    // tag::constructor(IGreeterDFPkg.PkgInit)[]
    /**
     * @notice Constructs the GreeterDFPkg capturing the diamond package callback factory and greeter facet.
     * @dev Stores as immutables for use in facetCuts / deploy / metadata. SELF captured for factory.deploy.
     * @param pkgInit The PkgInit (must provide non-zero addresses in real use per LR-7).
     */
    constructor(PkgInit memory pkgInit) {
        SELF = this;
        DIAMOND_FACTORY = pkgInit.diamondPackageFactory;
        GREETER_FACET = pkgInit.greeterFacet;
    }

    // end::constructor(IGreeterDFPkg.PkgInit)[]

    // tag::deployGreeter(string)[]
    /// @notice Convenience that deploys a Greeter Diamond proxy instance via the callback factory, initialized with the given message.
    /// @param initMessage The initial greeting message stored in the new proxy (via initAccount).
    /// @return instance The deployed IGreeter (Diamond proxy).
    /// @custom:signature deployGreeter(string)
    /// @custom:selector 0x9d391531
    function deployGreeter(string memory initMessage) public returns (IGreeter instance) {
        return IGreeter(DIAMOND_FACTORY.deploy(SELF, abi.encode(IGreeterDFPkg.PkgArgs({message: initMessage}))));
    }

    // end::deployGreeter(string)[]

    // tag::packageName-greeterdfpkg[]
    /// @notice Returns the human-readable name of this package.
    /// @return name_ Package name (e.g. "GreeterDFPkg").
    /// @custom:signature packageName()
    /// @custom:selector 0xabc8b346
    /// @inheritdoc IDiamondFactoryPackage
    function packageName() public pure returns (string memory name_) {
        return type(GreeterDFPkg).name;
    }

    // end::packageName-greeterdfpkg[]

    // tag::packageMetadata-greeterdfpkg[]
    /// @notice Returns combined metadata for the package in one call.
    /// @return name_ Package name.
    /// @return interfaces Exposed interface IDs (for proxies).
    /// @return facets Referenced facet contract addresses.
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

    // end::packageMetadata-greeterdfpkg[]

    // tag::facetAddresses-greeterdfpkg[]
    /// @notice Returns the addresses of the facet contracts referenced by this package.
    /// @return facetAddresses_ Deployed facet addresses (immutable after pkg construction).
    /// @custom:signature facetAddresses()
    /// @custom:selector 0x52ef6b2c
    /// @inheritdoc IDiamondFactoryPackage
    function facetAddresses() public view returns (address[] memory facetAddresses_) {
        facetAddresses_ = new address[](1);
        facetAddresses_[0] = address(GREETER_FACET);
    }

    // end::facetAddresses-greeterdfpkg[]

    // tag::facetInterfaces-greeterdfpkg[]
    /// @notice Returns ERC165 interface IDs that THIS package's logic exposes when attached to a proxy.
    /// @dev ONLY interfaces expected to be called through the proxy (not direct calls on the pkg itself). Delegates to GreeterFacet (which declares IGreeter).
    /// @return interfaces Array of interface IDs registered on deployed Diamond proxies.
    /// @custom:signature facetInterfaces()
    /// @custom:selector 0x2ea80826
    /// @inheritdoc IDiamondFactoryPackage
    function facetInterfaces()
        public
        pure
        virtual
        override(GreeterFacet, IDiamondFactoryPackage)
        returns (bytes4[] memory interfaces)
    {
        return GreeterFacet.facetInterfaces();
    }

    // end::facetInterfaces-greeterdfpkg[]

    // tag::facetCuts-greeterdfpkg[]
    /// @notice Returns the facet cuts (add/replace/remove) to apply when deploying a proxy from this package.
    /// @return facetCuts_ The cuts to pass to DiamondCut.
    /// @custom:signature facetCuts()
    /// @custom:selector 0xa4b3ad35
    /// @inheritdoc IDiamondFactoryPackage
    function facetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_) {
        facetCuts_ = new IDiamond.FacetCut[](1);
        facetCuts_[0] = IDiamond.FacetCut({
            // address facetAddress;
            facetAddress: address(GREETER_FACET),
            // FacetCutAction action;
            action: IDiamond.FacetCutAction.Add,
            // bytes4[] functionSelectors;
            functionSelectors: GREETER_FACET.facetFuncs()
        });
    }

    // end::facetCuts-greeterdfpkg[]

    // tag::diamondConfig-greeterdfpkg[]
    /// @notice Convenience method returning both cuts and interfaces in a single struct.
    /// @return config DiamondConfig with facetCuts and interfaces.
    /// @custom:signature diamondConfig()
    /// @custom:selector 0x65d375b3
    /// @inheritdoc IDiamondFactoryPackage
    function diamondConfig() public view virtual returns (IDiamondFactoryPackage.DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }

    // end::diamondConfig-greeterdfpkg[]

    // tag::calcSalt-greeterdfpkg[]
    /// @notice Computes the deterministic salt for proxy deployment given package args.
    /// @param pkgArgs ABI-encoded package-specific arguments (often PkgArgs struct).
    /// @return salt Salt used for CREATE3 address derivation of the proxy.
    /// @custom:signature calcSalt(bytes)
    /// @custom:selector 0xd82be56e
    /// @inheritdoc IDiamondFactoryPackage
    function calcSalt(bytes memory pkgArgs) public pure returns (bytes32 salt) {
        salt = abi.encode(pkgArgs)._hash();
    }

    // end::calcSalt-greeterdfpkg[]

    // tag::processArgs-greeterdfpkg[]
    /// @notice Optional preprocessing hook to normalize or decorate user-provided arguments.
    /// @dev May return args unchanged. Used to derive salt distinctly from init state.
    /// @param pkgArgs Raw user-provided arguments.
    /// @return processedPkgArgs Arguments to use for salt calc and later initAccount.
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

    // end::processArgs-greeterdfpkg[]

    // tag::updatePkg-greeterdfpkg[]
    /// @notice Allows updating package configuration for an already-deployed proxy (if supported).
    /// @dev Default no-op returns true (virtual for potential overrides in concrete DFPkgs). First param (expectedProxy) and second (pkgArgs) are unused in this default impl.
    /// @return success True if update succeeded.
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

    // end::updatePkg-greeterdfpkg[]

    // tag::initAccount-greeterdfpkg[]
    /**
     * @notice Standardized initialization entrypoint called via delegatecall on the new proxy during deployment.
     * @dev Decodes the PkgArgs and calls into GreeterRepo to set the initial message. Invoked by DiamondPackageCallBackFactory.
     * @param initArgs ABI-encoded initialization data (derived from processed pkgArgs).
     * @custom:signature initAccount(bytes)
     * @custom:selector 0x870d4838
     * @inheritdoc IDiamondFactoryPackage
     */
    function initAccount(bytes memory initArgs) public {
        PkgArgs memory pkgArgs = abi.decode(initArgs, (PkgArgs));
        GreeterRepo._setMessage(pkgArgs.message);
    }

    // end::initAccount-greeterdfpkg[]

    // tag::postDeploy-greeterdfpkg[]
    /// @notice Optional post-deployment hook called after initAccount.
    /// @dev Can be used for wiring external references, emitting events, or additional setup.
    ///      Default no-op returns true (virtual for overrides). The account param is unused in this default impl.
    /// @return success True if post-deploy completed successfully.
    /// @custom:signature postDeploy(address)
    /// @custom:selector 0x70068fcf
    /// @inheritdoc IDiamondFactoryPackage
    // account
    function postDeploy(address) public virtual returns (bool) {
        return true;
    }
    // end::postDeploy-greeterdfpkg[]
}
// end::GreeterDFPkg[]
