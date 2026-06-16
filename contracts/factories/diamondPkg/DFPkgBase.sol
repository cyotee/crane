// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";

// tag::DFPkgBase[]
/**
 * @title DFPkgBase
 * @notice Abstract base providing common default / virtual implementations for IDiamondFactoryPackage.
 *         Concrete DFPkgs (e.g. Create3FactoryDFPkg, ERC20DFPkg) extend this to supply package-specific
 *         metadata, facet bundles, salt calc, and lifecycle hooks (initAccount / postDeploy).
 * @dev Inheritors MUST override packageName, facet* virtuals, facetCuts, and initAccount at minimum.
 *      Non-virtual methods here provide shared convenience (packageMetadata, diamondConfig) and safe
 *      defaults (processArgs passthrough, update/post no-op). PkgInit/PkgArgs live on the I*DFPkg interface
 *      per AGENTS.md critical rule.
 * @author Crane Framework
 */
abstract contract DFPkgBase is IDiamondFactoryPackage {
    using BetterEfficientHashLib for bytes;

    // tag::packageName()[]
    /// @notice Returns the human-readable name of this package.
    /// @return name_ Package name (e.g. "SomeDFPkg" from concrete override).
    /// @custom:signature packageName()
    /// @custom:selector 0xabc8b346
    /// @inheritdoc IDiamondFactoryPackage
    function packageName() public view virtual returns (string memory name_);
    // end::packageName()[]

    // tag::facetInterfaces()[]
    /// @notice Returns ERC165 interface IDs that THIS package's logic exposes when attached to a proxy.
    /// @dev ONLY interfaces expected to be called through the proxy (not direct calls on the pkg itself).
    /// @return interfaces Array of interface IDs registered on deployed Diamond proxies.
    /// @custom:signature facetInterfaces()
    /// @custom:selector 0x2ea80826
    /// @inheritdoc IDiamondFactoryPackage
    function facetInterfaces() public view virtual returns (bytes4[] memory interfaces);
    // end::facetInterfaces()[]

    // tag::facetAddresses()[]
    /// @notice Returns the addresses of the facet contracts referenced by this package.
    /// @return facetAddresses Deployed facet addresses (immutable after pkg construction).
    /// @custom:signature facetAddresses()
    /// @custom:selector 0x52ef6b2c
    /// @inheritdoc IDiamondFactoryPackage
    function facetAddresses() public view virtual returns (address[] memory facetAddresses);
    // end::facetAddresses()[]

    // tag::packageMetadata()[]
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
    // end::packageMetadata()[]

    // tag::facetCuts()[]
    /// @notice Returns the facet cuts (add/replace/remove) to apply when deploying a proxy from this package.
    /// @return facetCuts_ The cuts to pass to DiamondCut.
    /// @custom:signature facetCuts()
    /// @custom:selector 0xa4b3ad35
    /// @inheritdoc IDiamondFactoryPackage
    function facetCuts() public view virtual returns (IDiamond.FacetCut[] memory facetCuts_);
    // end::facetCuts()[]

    // tag::diamondConfig()[]
    /// @notice Convenience method returning both cuts and interfaces in a single struct.
    /// @return config DiamondConfig with facetCuts and interfaces.
    /// @custom:signature diamondConfig()
    /// @custom:selector 0x65d375b3
    /// @inheritdoc IDiamondFactoryPackage
    function diamondConfig() public view returns (DiamondConfig memory config) {
        config = IDiamondFactoryPackage.DiamondConfig({facetCuts: facetCuts(), interfaces: facetInterfaces()});
    }
    // end::diamondConfig()[]

    // tag::calcSalt(bytes)[]
    /// @notice Computes the deterministic salt for proxy deployment given package args.
    /// @param pkgArgs ABI-encoded package-specific arguments (often PkgArgs struct).
    /// @return salt Salt used for CREATE3 address derivation of the proxy.
    /// @custom:signature calcSalt(bytes)
    /// @custom:selector 0xd82be56e
    /// @inheritdoc IDiamondFactoryPackage
    function calcSalt(bytes memory pkgArgs) public view virtual returns (bytes32 salt) {
        return pkgArgs._hash();
    }
    // end::calcSalt(bytes)[]

    // tag::processArgs(bytes)[]
    /// @notice Optional preprocessing hook to normalize or decorate user-provided arguments.
    /// @dev May return args unchanged. Used to derive salt distinctly from init state.
    /// @param pkgArgs Raw user-provided arguments.
    /// @return processedPkgArgs Arguments to use for salt calc and later initAccount.
    /// @custom:signature processArgs(bytes)
    /// @custom:selector 0x87c3adb3
    /// @inheritdoc IDiamondFactoryPackage
    function processArgs(bytes memory pkgArgs) public virtual returns (bytes memory processedPkgArgs) {
        return pkgArgs;
    }
    // end::processArgs(bytes)[]

    // tag::updatePkg(address,bytes)[]
    /// @notice Allows updating package configuration for an already-deployed proxy (if supported).
    /// @dev Default no-op returns true (virtual for potential overrides in concrete DFPkgs).
    /// @param expectedProxy The proxy address expected to be updated (safety check; unused in default).
    /// @param pkgArgs New arguments (unused in default).
    /// @return success True if update succeeded.
    /// @custom:signature updatePkg(address,bytes)
    /// @custom:selector 0xa9089235
    /// @inheritdoc IDiamondFactoryPackage
    function updatePkg(
        address expectedProxy,
        bytes memory pkgArgs
    )
        public
        virtual
        returns (bool)
    {
        return true;
    }
    // end::updatePkg(address,bytes)[]

    // tag::initAccount(bytes)[]
    /// @notice Standardized initialization entrypoint called via delegatecall on the new proxy during deployment.
    /// @dev The DiamondPackageCallBackFactory calls this after creating the proxy and applying cuts.
    ///      Concrete impls typically decode args, perform cuts via IDiamondCut, call own _initialize etc.
    ///      Marked virtual with no body (must be implemented by inheritors).
    /// @param initArgs ABI-encoded initialization data (derived from processed pkgArgs).
    /// @custom:signature initAccount(bytes)
    /// @custom:selector 0x870d4838
    /// @inheritdoc IDiamondFactoryPackage
    function initAccount(
        bytes memory initArgs
    )
        public
        virtual;
    // end::initAccount(bytes)[]

    // tag::postDeploy(address)[]
    /// @notice Optional post-deployment hook called after initAccount.
    /// @dev Can be used for wiring external references, emitting events, or additional setup.
    ///      Default no-op returns true (virtual for overrides).
    /// @param account The newly deployed proxy address.
    /// @return success True if post-deploy completed successfully.
    /// @custom:signature postDeploy(address)
    /// @custom:selector 0x70068fcf
    /// @inheritdoc IDiamondFactoryPackage
    function postDeploy(
        address account
    )
        public
        virtual
        returns (bool)
    {
        return true;
    }
    // end::postDeploy(address)[]
}
// end::DFPkgBase[]
