// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

// import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC721Repo} from "@crane/contracts/tokens/ERC721/ERC721Repo.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

contract ERC721Facet is IFacet, IERC721 {

    bytes4 private constant _SAFE_TRANSFER_FROM_WITH_DATA_SELECTOR =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant _SAFE_TRANSFER_FROM_SELECTOR =
        bytes4(keccak256("safeTransferFrom(address,address,uint256)"));

    /* ------------------------------- IFacet ------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     */
    function facetName() public pure returns (string memory name) {
        return type(ERC721Facet).name;
    }
    // end::facetName[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC721).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     */
    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](9);
        funcs[0] = IERC721.balanceOf.selector;
        funcs[1] = IERC721.ownerOf.selector;
        funcs[2] = _SAFE_TRANSFER_FROM_WITH_DATA_SELECTOR;
        funcs[3] = _SAFE_TRANSFER_FROM_SELECTOR;
        funcs[4] = IERC721.transferFrom.selector;
        funcs[5] = IERC721.approve.selector;
        funcs[6] = IERC721.setApprovalForAll.selector;
        funcs[7] = IERC721.getApproved.selector;
        funcs[8] = IERC721.isApprovedForAll.selector;
    }
    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     */
    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    // end::facetMetadata()[]
    /* ------------------------------- IERC721 ------------------------------ */

    function balanceOf(address owner) public view virtual returns (uint256) {
        return ERC721Repo._balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return ERC721Repo._ownerOf(tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public payable virtual {
        ERC721Repo._safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual {
        ERC721Repo._safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable virtual {
        ERC721Repo._transferFrom(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public payable virtual {
        ERC721Repo._approve(to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        ERC721Repo._setApprovalForAll(operator, approved);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return ERC721Repo._getApproved(tokenId);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return ERC721Repo._isApprovedForAll(owner, operator);
    }
}
