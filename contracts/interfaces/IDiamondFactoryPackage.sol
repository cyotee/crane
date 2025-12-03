// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IDiamond} from "contracts/interfaces/IDiamond.sol";

interface IDiamondFactoryPackage {
    /**
     * @dev Structs are better than tuples.
     */
    struct DiamondConfig {
        IDiamond.FacetCut[] facetCuts;
        bytes4[] interfaces;
    }

    /**
     * @dev ONLY includes interface expected to be called through a proxy.
     * @dev DOES NOT include ANY interface expected to be called directly.
     * @dev Defines the functions in THIS contract mapped into deployed proxies.
     * @return interfaces The ERC165 interface IDs exposed by this Facet.
     * @custom:selector 0x2ea80826
     */
    function facetInterfaces() external view returns (bytes4[] memory interfaces);

    /**
     * @return facetCuts_ The IDiamond.FacetCut array to configuring a proxy with this package.
     * @custom:selector 0xa4b3ad35
     */
    function facetCuts() external view returns (IDiamond.FacetCut[] memory facetCuts_);

    /**
     * @return config Unified function to retrieved `facetInterfaces()` AND `facetCuts()` in one call.
     * @custom:selector 0x65d375b3
     */
    function diamondConfig() external view returns (DiamondConfig memory config);

    /**
     * @custom:selector 0xd82be56e
     */
    function calcSalt(bytes memory pkgArgs) external view returns (bytes32 salt);

    /**
     * @dev Provides a preprocessing hook for packages to normalize and/or decorate user provided arguments.
     * @dev User provided arguments may be returned unaltered if no processing is required.
     * @dev This returns the salt distinct from the arguments to allow for simpler salt calculations.
     * @notice The returned initArgs will be used by a DomainController to calculate the CREATE2 salt to be used when instantiating a DomainMemberProxy.
     * @param pkgArgs The ABI encoded arguments the user is providing to the package.
     * return initArgs The arguments to be used to initialize the chain state for a new DomainMemberProxy instance.
     * @custom:selector 0x87c3adb3
     */
    function processArgs(bytes memory pkgArgs) external returns (bytes memory processedPkgArgs);

    /**
     * @dev Updates the package with new arguments.
     * @dev This is used to update the package with new arguments after the initial deployment.
     * @param expectedProxy The address of the proxy to update.
     * @param pkgArgs The ABI encoded arguments the user is providing to the package.
     * @return success Whether the update was successful.
     * @custom:selector 0xa9089235
     */
    function updatePkg(address expectedProxy, bytes memory pkgArgs) external returns (bool);

    /**
     * @dev A standardized proxy initialization function.
     * @custom:selector 0x87d48380
     */
    function initAccount(bytes memory initArgs) external;

    // TODO Make return bytes to pass post deploy results to account.
    /**
     * @custom:selector 0x70068fcf
     */
    function postDeploy(address account) external returns (bool);
}
