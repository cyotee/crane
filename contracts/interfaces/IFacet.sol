// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

interface IFacet {
    function facetName() external view returns (string memory name);

    /**
     * @custom:selector 0x2ea80826
     */
    function facetInterfaces() external view returns (bytes4[] memory interfaces);

    /**
     * @custom:selector 0x574a4cff
     */
    function facetFuncs() external view returns (bytes4[] memory funcs);

    function facetMetadata()
        external
        view
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions);
}
