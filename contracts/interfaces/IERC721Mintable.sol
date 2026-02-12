// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import {IERC721} from "contracts/crane/interfaces/IERC721.sol";

interface IERC721Mintable {
    function mint(address to) external returns (uint256 tokenId);

    function mintWithURI(address to, string memory tokenUri) external returns (uint256 tokenId);

    function burn(uint256 tokenId) external returns (bool);
}
