// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {IERC721Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {ERC721TargetStub} from "@crane/contracts/tokens/ERC721/ERC721TargetStub.sol";

/**
 * @title ERC721TargetStubHandler
 * @notice Handler for ERC721 invariant testing
 * @dev Tracks minted tokens and owner balances for invariant verification
 */
contract ERC721TargetStubHandler is Test {
    ERC721TargetStub public sut;

    // Track all minted token IDs
    uint256[] internal _tokenIds;
    mapping(uint256 => bool) internal _tokenExists;

    // Track all addresses that have interacted
    address[] internal _actors;
    mapping(address => bool) internal _seenActor;

    // Ghost variables for tracking
    uint256 public ghostTotalMinted;
    uint256 public ghostTotalBurned;

    constructor() {}

    /**
     * @notice Attach the token under test
     */
    function attachToken(ERC721TargetStub token) external {
        sut = token;
        _pushActor(address(this));
    }

    /**
     * @notice Convert seed to small set of addresses
     */
    function addrFromSeed(uint256 seed) public pure returns (address) {
        uint160 v = uint160((seed % 16) + 1);
        return address(v);
    }

    function _pushActor(address a) internal {
        if (!_seenActor[a] && a != address(0)) {
            _seenActor[a] = true;
            _actors.push(a);
        }
    }

    function _pushToken(uint256 tokenId) internal {
        if (!_tokenExists[tokenId]) {
            _tokenExists[tokenId] = true;
            _tokenIds.push(tokenId);
        }
    }

    function _removeToken(uint256 tokenId) internal {
        _tokenExists[tokenId] = false;
    }

    /* ---------------------------------------------------------------------- */
    /*                          Mutating Operations                            */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice Mint a new token to an address
     */
    function mint(uint256 toSeed) external returns (uint256 tokenId) {
        address to = addrFromSeed(toSeed);
        _pushActor(to);

        tokenId = sut.mint(to);
        _pushToken(tokenId);
        ghostTotalMinted++;
    }

    /**
     * @notice Transfer a token
     */
    function transferFrom(uint256 tokenIdSeed, uint256 toSeed) external {
        if (_tokenIds.length == 0) return;

        uint256 tokenId = _tokenIds[tokenIdSeed % _tokenIds.length];
        if (!_tokenExists[tokenId]) return;

        address to = addrFromSeed(toSeed);
        address owner = sut.ownerOf(tokenId);

        _pushActor(to);

        vm.prank(owner);
        if (to == address(0)) {
            vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidOwner.selector, to));
            sut.transferFrom(owner, to, tokenId);
            return;
        }

        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(owner, to, tokenId);
        sut.transferFrom(owner, to, tokenId);
    }

    /**
     * @notice Approve an operator for a token
     */
    function approve(uint256 tokenIdSeed, uint256 operatorSeed) external {
        if (_tokenIds.length == 0) return;

        uint256 tokenId = _tokenIds[tokenIdSeed % _tokenIds.length];
        if (!_tokenExists[tokenId]) return;

        address operator = addrFromSeed(operatorSeed);
        address owner = sut.ownerOf(tokenId);

        _pushActor(operator);

        vm.prank(owner);
        if (operator == address(0)) {
            vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidOperator.selector, operator));
            sut.approve(operator, tokenId);
            return;
        }

        vm.expectEmit(true, true, true, true);
        emit IERC721.Approval(owner, operator, tokenId);
        sut.approve(operator, tokenId);
    }

    /**
     * @notice Set approval for all tokens
     */
    function setApprovalForAll(uint256 ownerSeed, uint256 operatorSeed, bool approved) external {
        address owner = addrFromSeed(ownerSeed);
        address operator = addrFromSeed(operatorSeed);

        _pushActor(owner);
        _pushActor(operator);

        vm.prank(owner);
        if (operator == address(0)) {
            vm.expectRevert(abi.encodeWithSelector(IERC721Errors.ERC721InvalidOperator.selector, operator));
            sut.setApprovalForAll(operator, approved);
            return;
        }

        vm.expectEmit(true, true, false, true);
        emit IERC721.ApprovalForAll(owner, operator, approved);
        sut.setApprovalForAll(operator, approved);
    }

    /**
     * @notice Burn a token
     */
    function burn(uint256 tokenIdSeed) external {
        if (_tokenIds.length == 0) return;

        uint256 tokenId = _tokenIds[tokenIdSeed % _tokenIds.length];
        if (!_tokenExists[tokenId]) return;

        address owner = sut.ownerOf(tokenId);

        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit IERC721.Transfer(owner, address(0), tokenId);
        sut.burn(tokenId);

        _removeToken(tokenId);
        ghostTotalBurned++;
    }

    /* ---------------------------------------------------------------------- */
    /*                          View Functions                                 */
    /* ---------------------------------------------------------------------- */

    function actorCount() external view returns (uint256) {
        return _actors.length;
    }

    function actorAt(uint256 idx) external view returns (address) {
        return _actors[idx];
    }

    function tokenCount() external view returns (uint256) {
        return _tokenIds.length;
    }

    function tokenAt(uint256 idx) external view returns (uint256) {
        return _tokenIds[idx];
    }

    function tokenExists(uint256 tokenId) external view returns (bool) {
        return _tokenExists[tokenId];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return sut.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return sut.ownerOf(tokenId);
    }
}
