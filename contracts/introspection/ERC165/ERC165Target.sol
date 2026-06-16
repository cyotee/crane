// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";

// tag::ERC165Target[]
/**
 * @title ERC165Target - Target contract implementing IERC165.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Exposes supportsInterface by delegating to ERC165Repo.
 * @dev Follows Facet-Target-Repo. Delegates entirely to ERC165Repo._supportsInterface.
 *      Inherited by ERC165Facet.
 */
contract ERC165Target is IERC165 {
    /* ------ ERC165 ------ */

    // tag::supportsInterface(bytes4)[]
    /**
     * @inheritdoc IERC165
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return isSupported whether interface is supported
     * @custom:selector 0x01ffc9a7
     * @custom:signature "supportsInterface(bytes4)"
     * @dev Delegates to ERC165Repo._supportsInterface(interfaceId).
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool isSupported) {
        return ERC165Repo._supportsInterface(interfaceId);
    }
    // end::supportsInterface(bytes4)[]
}
// end::ERC165Target[]
