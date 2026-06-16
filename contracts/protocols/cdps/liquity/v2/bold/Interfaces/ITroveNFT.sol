// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {
    IERC721Metadata
} from "@crane/contracts/external/openzeppelin-contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./ITroveManager.sol";

interface ITroveNFT is IERC721, IERC721Metadata {
    function mint(address _owner, uint256 _troveId) external;
    function burn(uint256 _troveId) external;
}
