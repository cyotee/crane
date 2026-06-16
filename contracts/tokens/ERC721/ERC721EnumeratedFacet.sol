// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC721Enumerated} from "@crane/contracts/interfaces/IERC721Enumerated.sol";
import {ERC721EnumeratedRepo} from "@crane/contracts/tokens/ERC721/ERC721EnumeratedRepo.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {IERC721Enumerated} from "@crane/contracts/interfaces/IERC721Enumerated.sol";

// tag::ERC721EnumeratedFacet[]
/**
 * @title ERC721EnumeratedFacet - Reusable Diamond facet implementing ERC-721 enumeration extensions (IERC721Enumerated) per Facet-Target-Repo.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Directly implements IERC721Enumerated (delegates to ERC721EnumeratedRepo for storage and enumeration). Also overrides select IERC721 transfer functions.
 *      Implements IFacet to declare supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 * @custom:contractlistipfs
 */
contract ERC721EnumeratedFacet is IFacet, IERC721Enumerated {
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
        return type(ERC721EnumeratedFacet).name;
    }
    // end::facetName()[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the interfaces implemented by the exposing facet for use in a composing proxy.
     * @return facetInterfaces_ The interface IDs implemented by the facet.
     * @custom:selector 0x2ea80826
     * @custom:signature facetInterfaces()
     */
    function facetInterfaces() public pure returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(IERC721Enumerated).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares the function selectors implemented by the exposing facet for use in a composing proxy.
     * @return facetFuncs_ The function selectors implemented by the facet.
     * @custom:selector 0x574a4cff
     * @custom:signature facetFuncs()
     */
    function facetFuncs() public pure returns (bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](7);
        facetFuncs_[0] = IERC721Enumerated.tokenIds.selector;
        facetFuncs_[1] = IERC721Enumerated.ownedIds.selector;
        facetFuncs_[3] = IERC721Enumerated.globalOperatorOf.selector;
        facetFuncs_[4] = _SAFE_TRANSFER_FROM_WITH_DATA_SELECTOR;
        facetFuncs_[5] = _SAFE_TRANSFER_FROM_SELECTOR;
        facetFuncs_[6] = IERC721.transferFrom.selector;
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
    /*                          IERC721 Overrides / Transfers                     */
    /* -------------------------------------------------------------------------- */

    // tag::safeTransferFrom(address-address-uint256-bytes)[]
    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`, with data for receiver callback.
     * @dev Implements transfer logic from IERC721 (for enumeration side-effects via repo).
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     * @param data additional data
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        ERC721EnumeratedRepo._safeTransferFrom(from, to, tokenId, data);
    }
    // end::safeTransferFrom(address-address-uint256-bytes)[]

    // tag::safeTransferFrom(address-address-uint256)[]
    /**
     * @notice Safely transfers `tokenId` token from `from` to `to`.
     * @dev Implements transfer logic from IERC721 (for enumeration side-effects via repo).
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        ERC721EnumeratedRepo._safeTransferFrom(from, to, tokenId);
    }
    // end::safeTransferFrom(address-address-uint256)[]

    // tag::transferFrom(address-address-uint256)[]
    /**
     * @notice Transfers `tokenId` token from `from` to `to`.
     * @dev Implements transfer logic from IERC721 (for enumeration side-effects via repo).
     * @param from address to transfer the token from
     * @param to address to transfer the token to
     * @param tokenId identifier of the token to transfer
     */
    function transferFrom(address from, address to, uint256 tokenId) external {
        ERC721EnumeratedRepo._transferFrom(from, to, tokenId);
    }
    // end::transferFrom(address-address-uint256)[]

    /* -------------------------------------------------------------------------- */
    /*                           IERC721Enumerated                                */
    /* -------------------------------------------------------------------------- */

    // tag::tokenIds()[]
    /**
     * @inheritdoc IERC721Enumerated
     * @notice Returns the list of all token IDs tracked by this enumeration.
     * @return array of all token identifiers
     */
    function tokenIds() external view returns (uint256[] memory) {
        return ERC721EnumeratedRepo._tokenIds();
    }
    // end::tokenIds()[]

    // tag::ownedIds(address)[]
    /**
     * @inheritdoc IERC721Enumerated
     * @notice Returns the list of token IDs owned by the given owner.
     * @param owner address of the owner to query
     * @return array of token identifiers owned by the owner
     */
    function ownedIds(address owner) external view returns (uint256[] memory) {
        return ERC721EnumeratedRepo._ownedIds(owner);
    }
    // end::ownedIds(address)[]

    // tag::globalOperatorOf(address)[]
    /**
     * @inheritdoc IERC721Enumerated
     * @notice Returns the global operator address configured for the given owner (if any).
     * @param owner address of the owner
     * @return the global operator address
     */
    function globalOperatorOf(address owner) external view returns (address) {
        return ERC721EnumeratedRepo._globalOperatorOf(owner);
    }
    // end::globalOperatorOf(address)[]
}
// end::ERC721EnumeratedFacet[]
