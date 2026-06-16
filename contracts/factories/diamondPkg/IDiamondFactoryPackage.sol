// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";

// tag::IDiamondFactoryPackage[]
/// @title IDiamondFactoryPackage
/// @author Crane Framework
/// @notice Interface for Diamond Factory Packages (DFPkgs) that bundle facets and initialization logic
/// for deterministic, reusable Diamond proxy deployments via CREATE3 + callback factories.
/// @dev DFPkgs enable one-time deployment of logic (facets) and cheap reproducible proxy instances.
/// Critical rule: PkgInit and PkgArgs structs MUST be defined in the *interface*, not the implementing contract.
/// @custom:interfaceid 0x00000000 // computed by XOR of all external selectors when implemented
interface IDiamondFactoryPackage {
    /* -------------------------------------------------------------------------- */
    /*                                    Types                                   */
    /* -------------------------------------------------------------------------- */

    // tag::DiamondConfig[]
    /// @dev Bundles facet cuts and exposed interfaces for a single `diamondConfig()` call.
    /// @dev Structs preferred over tuples for clarity and ABI stability.
    struct DiamondConfig {
        IDiamond.FacetCut[] facetCuts;
        bytes4[] interfaces;
    }
    // end::DiamondConfig[]

    /* -------------------------------------------------------------------------- */
    /*                             Package Metadata                               */
    /* -------------------------------------------------------------------------- */

    // tag::packageName[]
    /// @notice Returns the human-readable name of this package.
    /// @return name_ Package name (e.g. "ERC20DFPkg").
    /// @custom:signature packageName()
    /// @custom:selector 0xabc8b346
    function packageName() external view returns (string memory name_);
    // end::packageName[]

    // tag::facetInterfaces[]
    /// @notice Returns ERC165 interface IDs that THIS package's logic exposes when attached to a proxy.
    /// @dev ONLY interfaces expected to be called through the proxy (not direct calls on the pkg itself).
    /// @return interfaces Array of interface IDs registered on deployed Diamond proxies.
    /// @custom:signature facetInterfaces()
    /// @custom:selector 0x2ea80826
    function facetInterfaces() external view returns (bytes4[] memory interfaces);
    // end::facetInterfaces[]

    // tag::facetAddresses[]
    /// @notice Returns the addresses of the facet contracts referenced by this package.
    /// @return facetAddresses Deployed facet addresses (immutable after pkg construction).
    /// @custom:signature facetAddresses()
    /// @custom:selector 0x52ef6b2c
    function facetAddresses() external view returns (address[] memory facetAddresses);
    // end::facetAddresses[]

    // tag::packageMetadata[]
    /// @notice Returns combined metadata for the package in one call.
    /// @return name_ Package name.
    /// @return interfaces Exposed interface IDs (for proxies).
    /// @return facets Referenced facet contract addresses.
    /// @custom:signature packageMetadata()
    /// @custom:selector 0xf45469e7
    function packageMetadata()
        external
        view
        returns (string memory name_, bytes4[] memory interfaces, address[] memory facets);
    // end::packageMetadata[]

    /* -------------------------------------------------------------------------- */
    /*                           Diamond Configuration                            */
    /* -------------------------------------------------------------------------- */

    // tag::facetCuts[]
    /// @notice Returns the facet cuts (add/replace/remove) to apply when deploying a proxy from this package.
    /// @return facetCuts_ The cuts to pass to DiamondCut.
    /// @custom:signature facetCuts()
    /// @custom:selector 0xa4b3ad35
    function facetCuts() external view returns (IDiamond.FacetCut[] memory facetCuts_);
    // end::facetCuts[]

    // tag::diamondConfig[]
    /// @notice Convenience method returning both cuts and interfaces in a single struct.
    /// @return config DiamondConfig with facetCuts and interfaces.
    /// @custom:signature diamondConfig()
    /// @custom:selector 0x65d375b3
    function diamondConfig() external view returns (DiamondConfig memory config);
    // end::diamondConfig[]

    /* -------------------------------------------------------------------------- */
    /*                              Salt & Arguments                              */
    /* -------------------------------------------------------------------------- */

    // tag::calcSalt[]
    /// @notice Computes the deterministic salt for proxy deployment given package args.
    /// @param pkgArgs ABI-encoded package-specific arguments (often PkgArgs struct).
    /// @return salt Salt used for CREATE2 address derivation of the proxy.
    /// @custom:signature calcSalt(bytes)
    /// @custom:selector 0xd82be56e
    function calcSalt(bytes memory pkgArgs) external view returns (bytes32 salt);
    // end::calcSalt[]

    // tag::processArgs[]
    /// @notice Optional preprocessing hook to normalize or decorate user-provided arguments.
    /// @dev May return args unchanged. Used to derive salt distinctly from init state.
    /// @param pkgArgs Raw user-provided arguments.
    /// @return processedPkgArgs Arguments to use for salt calc and later initAccount.
    /// @custom:signature processArgs(bytes)
    /// @custom:selector 0x87c3adb3
    function processArgs(bytes memory pkgArgs) external returns (bytes memory processedPkgArgs);
    // end::processArgs[]

    /* -------------------------------------------------------------------------- */
    /*                         Proxy Lifecycle Hooks                              */
    /* -------------------------------------------------------------------------- */

    // tag::updatePkg[]
    /// @notice Allows updating package configuration for an already-deployed proxy (if supported).
    /// @param expectedProxy The proxy address expected to be updated (safety check).
    /// @param pkgArgs New arguments.
    /// @return success True if update succeeded.
    /// @custom:signature updatePkg(address,bytes)
    /// @custom:selector 0xa9089235
    function updatePkg(address expectedProxy, bytes memory pkgArgs) external returns (bool);
    // end::updatePkg[]

    // tag::initAccount[]
    /// @notice Standardized initialization entrypoint called via delegatecall on the new proxy during deployment.
    /// @dev The DiamondPackageCallBackFactory calls this after creating the proxy and applying cuts.
    /// @dev Implementations typically decode args, perform cuts via IDiamondCut, call own _initialize etc.
    /// @param initArgs ABI-encoded initialization data (derived from processed pkgArgs).
    /// @custom:signature initAccount(bytes)
    /// @custom:selector 0x870d4838
    function initAccount(bytes memory initArgs) external;
    // end::initAccount[]

    // tag::postDeploy[]
    /// @notice Optional post-deployment hook called after initAccount.
    /// @dev Can be used for wiring external references, emitting events, or additional setup.
    /// @dev TODO: Consider returning bytes for richer post-deploy results.
    /// @param account The newly deployed proxy address.
    /// @return success True if post-deploy completed successfully.
    /// @custom:signature postDeploy(address)
    /// @custom:selector 0x70068fcf
    function postDeploy(address account) external returns (bool);
    // end::postDeploy[]
}
// end::IDiamondFactoryPackage[]
