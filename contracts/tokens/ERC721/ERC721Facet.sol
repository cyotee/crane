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

// tag::ERC721Facet[]
/**
 * @title ERC721Facet - Reusable Diamond facet implementing ERC-721 standard (IERC721) per Facet-Target-Repo.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Directly implements IERC721 (delegates to ERC721Repo for storage). Implements IFacet to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 * @custom:contractlistipfs
 */
contract ERC721Facet is IFacet, IERC721 {
    bytes4 private constant _SAFE_TRANSFER_FROM_WITH_DATA_SELECTOR =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant _SAFE_TRANSFER_FROM_SELECTOR =
        bytes4(keccak256("safeTransferFrom(address,address,uint256)"));

    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares a canonical nonunique name for the exposing facet.
     * @return name The name of the facet.
     * @custom:selector 0x5b6f4d01
     * @custom:signature facetName()
     */
    function facetName() public pure returns (string memory name) {
        return type(ERC721Facet).name;
    }
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the interfaces implemented by the exposing facet for use in a composing proxy.
     * @return interfaces The interface IDs implemented by the facet.
     * @custom:selector 0x2ea80826
     * @custom:signature facetInterfaces()
     */
    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC721).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the function selectors implemented by the exposing facet for use in a composing proxy.
     * @return funcs The function selectors implemented by the facet.
     * @custom:selector 0x574a4cff
     * @custom:signature facetFuncs()
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
     * @notice Declares comprehensive metadata about the exposing facet.
     * @dev Exposed to allow for single call retrieval of all facet metadata.
     * @return name The name of the facet.
     * @return interfaces The interface IDs implemented by the facet.
     * @return functions The function selectors implemented by the facet.
     * @custom:selector 0xf10d7a75
     * @custom:signature facetMetadata()
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

    /* -------------------------------------------------------------------------- */
    /*                                 IERC721                                    */
    /* -------------------------------------------------------------------------- */

    // tag::balanceOf(address)[]
    /**
     * @inheritdoc IERC721
     * @notice Returns the number of tokens in `owner`'s account.
     * @param owner address of the account to query
     * @return The number of tokens owned by the account.
     */
    function balanceOf(address owner) public view virtual returns (uint256) {
        return ERC721Repo._balanceOf(owner);
    }
    // end::balanceOf(address)[]

    // tag::ownerOf(uint256)[]
    /**
     * @inheritdoc IERC721
     * @notice Returns the owner of the `tokenId` token.
     * @param tokenId identifier of the token to query
     * @return owner address of the owner of the token.
     */
    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        return ERC721Repo._ownerOf(tokenId);
    }
    // end::ownerOf(uint256)[]

    // tag::safeTransferFrom(address-address-uint256-bytes)[]
    /**
     * @inheritdoc IERC721
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     * @dev The data parameter may be used to carry additional information for the recipient contract.
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     * @param data additional data with no specified format, sent in call to `to`
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public payable virtual {
        ERC721Repo._safeTransferFrom(from, to, tokenId, data);
    }
    // end::safeTransferFrom(address-address-uint256-bytes)[]

    // tag::safeTransferFrom(address-address-uint256)[]
    /**
     * @inheritdoc IERC721
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable virtual {
        ERC721Repo._safeTransferFrom(from, to, tokenId);
    }
    // end::safeTransferFrom(address-address-uint256)[]

    // tag::transferFrom(address-address-uint256)[]
    /**
     * @inheritdoc IERC721
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev Caller must own or be approved for the token.
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) public payable virtual {
        ERC721Repo._transferFrom(from, to, tokenId);
    }
    // end::transferFrom(address-address-uint256)[]

    // tag::approve(address,uint256)[]
    /**
     * @inheritdoc IERC721
     * @notice Gives permission to `to` to transfer `tokenId` token to another account.
     * @dev The approval is cleared when the token is transferred.
     * @param to address to be approved for the given token ID
     * @param tokenId identifier of the token to be approved
     */
    function approve(address to, uint256 tokenId) public payable virtual {
        ERC721Repo._approve(to, tokenId);
    }
    // end::approve(address,uint256)[]

    // tag::setApprovalForAll(address,bool)[]
    /**
     * @inheritdoc IERC721
     * @notice Approve or remove `operator` as an operator for the caller.
     * @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     * @param operator address to add to the set of authorized operators
     * @param approved true if the operator is approved, false to revoke approval
     */
    function setApprovalForAll(address operator, bool approved) public virtual {
        ERC721Repo._setApprovalForAll(operator, approved);
    }
    // end::setApprovalForAll(address,bool)[]

    // tag::getApproved(uint256)[]
    /**
     * @inheritdoc IERC721
     * @notice Returns the account approved for `tokenId` token.
     * @param tokenId identifier of the token to query the approval of
     * @return operator address currently approved for the token
     */
    function getApproved(uint256 tokenId) public view virtual returns (address) {
        return ERC721Repo._getApproved(tokenId);
    }
    // end::getApproved(uint256)[]

    // tag::isApprovedForAll(address,address)[]
    /**
     * @inheritdoc IERC721
     * @notice Returns if the `operator` is allowed to manage all of the assets of `owner`.
     * @param owner address of the owner of the assets
     * @param operator address of the approved operator
     * @return true if the operator is approved, false otherwise
     */
    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return ERC721Repo._isApprovedForAll(owner, operator);
    }
    // end::isApprovedForAll(address,address)[]
}
// end::ERC721Facet[]
