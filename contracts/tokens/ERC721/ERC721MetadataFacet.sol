// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IERC721Metadata} from "@crane/contracts/interfaces/IERC721Metadata.sol";
import {ERC721MetadataRepo} from "@crane/contracts/tokens/ERC721/ERC721MetadataRepo.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

contract ERC721MetadataFacet is IFacet, IERC721Metadata {

    /* ------------------------------- IFacet ------------------------------- */

    // tag::facetName()[]
    /**
     * @inheritdoc IFacet
     */
    function facetName() public pure returns (string memory) {
        return type(ERC721MetadataFacet).name;
    }
    // end::facetName[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public pure returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(IERC721Metadata).interfaceId;
    }
    // end::facetInterfaces()[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
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

    /* --------------------------- IERC721Metadata -------------------------- */

    function name() external view returns (string memory) {
        return ERC721MetadataRepo._name();
    }

    function symbol() external view returns (string memory) {
        return ERC721MetadataRepo._symbol();
    }

    function tokenURI(uint256 tokenId) external view returns (string memory finalUri_) {
        ERC721MetadataRepo.Storage storage layout = ERC721MetadataRepo._layout();
        string storage baseUri = ERC721MetadataRepo._baseURI(layout);
        if (bytes(baseUri).length > 0) {
            finalUri_ = baseUri;
        }
        string storage tokenUri = ERC721MetadataRepo._tokenURI(layout, tokenId);
        if (bytes(tokenUri).length > 0) {
            finalUri_ = string.concat(finalUri_, tokenUri);
        }
    }
}
