// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {
    IERC165
} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {
    ERC165Storage
} from "./ERC165Storage.sol";

contract ERC165Target is IERC165, ERC165Storage {

    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return isSupported whether interface is supported
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual returns (bool isSupported) {
        return _erc165().isSupportedInterface[interfaceId];
    }

}