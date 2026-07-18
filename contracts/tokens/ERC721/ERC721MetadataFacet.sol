// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC721Metadata} from "@crane/contracts/interfaces/IERC721Metadata.sol";
import {ERC721MetadataRepo} from "@crane/contracts/tokens/ERC721/ERC721MetadataRepo.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

// tag::ERC721MetadataFacet[]
/**
 * @title ERC721MetadataFacet - Reusable (abstract) Diamond facet implementing ERC-721 Metadata extension (IERC721Metadata) per Facet-Target-Repo.
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Directly implements IERC721Metadata (delegates to ERC721MetadataRepo for storage). Implements IFacet to declare
 *      supported interfaces and functions for use with Diamond loupes, DFPkgs, registries, and composition.
 *      Intended to be inherited for metadata-enabled ERC721 facets.
 * @custom:contractlistipfs
 */
abstract contract ERC721MetadataFacet is IFacet, IERC721Metadata {
    /* -------------------------------------------------------------------------- */
    /*                                   IFacet                                   */
    /* -------------------------------------------------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares a canonical nonunique name for the exposing facet.
     * @return The name of the facet.
     * @custom:selector 0x5b6f4d01
     * @custom:signature facetName()
     */
    function facetName() public pure returns (string memory) {
        return type(ERC721MetadataFacet).name;
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
        facetInterfaces_[0] = type(IERC721Metadata).interfaceId;
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
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = IERC721Metadata.name.selector;
        facetFuncs_[1] = IERC721Metadata.symbol.selector;
        facetFuncs_[2] = IERC721Metadata.tokenURI.selector;
    }

    // end::facetFuncs()[]

    // tag::facetMetadata()[]
    /**
     * @inheritdoc IFacet
     * @notice Declares comprehensive metadata about the exposing facet.
     * @dev Exposed to allow for single call retrieval of all facet metadata.
     * @return name_ The name of the facet.
     * @return interfaces The interface IDs implemented by the facet.
     * @return functions The function selectors implemented by the facet.
     * @custom:selector 0xf10d7a75
     * @custom:signature facetMetadata()
     */
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

    // end::facetMetadata()[]

    /* -------------------------------------------------------------------------- */
    /*                             IERC721Metadata                                */
    /* -------------------------------------------------------------------------- */

    // tag::name()[]
    /**
     * @inheritdoc IERC721Metadata
     * @notice Returns the token collection name.
     * @return The name of the token collection.
     */
    function name() external view returns (string memory) {
        return ERC721MetadataRepo._name();
    }

    // end::name()[]

    // tag::symbol()[]
    /**
     * @inheritdoc IERC721Metadata
     * @notice Returns the token collection symbol.
     * @return The symbol of the token collection.
     */
    function symbol() external view returns (string memory) {
        return ERC721MetadataRepo._symbol();
    }

    // end::symbol()[]

    // tag::tokenURI(uint256)[]
    /**
     * @inheritdoc IERC721Metadata
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @dev Concatenates base URI (if set) with per-token URI (if set).
     * @param tokenId identifier of the token to query
     * @return finalUri_ the resolved URI for the given token
     */
    function tokenURI(uint256 tokenId) external view returns (string memory finalUri_) {
        ERC721MetadataRepo.Storage storage layoutStruct = ERC721MetadataRepo._layoutStruct();
        string storage baseUri = ERC721MetadataRepo._baseURI(layoutStruct);
        if (bytes(baseUri).length > 0) {
            finalUri_ = baseUri;
        }
        string storage tokenUri = ERC721MetadataRepo._tokenURI(layoutStruct, tokenId);
        if (bytes(tokenUri).length > 0) {
            finalUri_ = string.concat(finalUri_, tokenUri);
        }
    }
    // end::tokenURI(uint256)[]
}
// end::ERC721MetadataFacet[]
