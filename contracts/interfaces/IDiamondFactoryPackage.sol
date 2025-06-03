// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IDiamond
} from "./IDiamond.sol";

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
     */
    function facetInterfaces()
    external view returns(bytes4[] memory interfaces);

    /**
     * @return facetCuts_ The IDiamond.FacetCut array to configuring a proxy with this package.
     */
    function facetCuts()
    external view returns(IDiamond.FacetCut[] memory facetCuts_);

    /**
     * @return config Unified function to retrieved `facetInterfaces()` AND `facetCuts()` in one call.
     */
    function diamondConfig()
    external view returns(DiamondConfig memory config);

    function calcSalt(
        bytes memory pkgArgs
    ) external view returns(bytes32 salt);

    /**
     * @dev Provides a preprocessing hook for packages to normalize and/or decorate user provided arguments.
     * @dev User provided arguments may be returned unaltered if no processing is required.
     * @dev This returns the salt distinct from the arguments to allow for simpler salt calculations.
     * @notice The returned initArgs will be used by a DomainController to calculate the CREATE2 salt to be used when instantiating a DomainMemberProxy.
     * @param pkgArgs The ABI encoded arguments the user is providing to the package.
     * return initArgs The arguments to be used to initialize the chain state for a new DomainMemberProxy instance.
     */
    function processArgs(
        bytes memory pkgArgs
    ) external returns(
        // bytes32 salt,
        bytes memory processedPkgArgs
    );

    /**
     * @dev A standardized proxy initialization function.
     */
    function initAccount(
        bytes memory initArgs
    ) external;

    // TODO Make return bytes to pass post deploy results to account.
    function postDeploy(address account)
    external returns(bytes memory postDeployData);

}