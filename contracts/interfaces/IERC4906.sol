// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "./IERC165.sol";
import {IERC721} from "./IERC721.sol";

/**
 * @title ERC-721 Metadata Update Extension
 * @notice Native Crane implementation - no external dependencies.
 * @dev See https://eips.ethereum.org/EIPS/eip-4906
 */
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}
