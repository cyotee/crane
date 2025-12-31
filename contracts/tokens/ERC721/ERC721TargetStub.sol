// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC721Repo} from "@crane/contracts/tokens/ERC721/ERC721Repo.sol";
import {ERC721Target} from "@crane/contracts/tokens/ERC721/ERC721Target.sol";

/**
 * @title ERC721TargetStub
 * @notice Test stub for ERC721 with exposed mint and burn functions
 */
contract ERC721TargetStub is ERC721Target {

    /**
     * @notice Mints a new token to the specified address
     * @param to The address to mint the token to
     * @return tokenId The ID of the newly minted token
     */
    function mint(address to) external returns (uint256 tokenId) {
        return ERC721Repo._mint(to);
    }

    /**
     * @notice Burns a token
     * @param tokenId The ID of the token to burn
     */
    function burn(uint256 tokenId) external {
        ERC721Repo._burn(tokenId);
    }

    /**
     * @notice Burns a token with owner verification
     * @param owner The expected owner of the token
     * @param tokenId The ID of the token to burn
     */
    function burn(address owner, uint256 tokenId) external {
        ERC721Repo._burn(owner, tokenId);
    }
}
