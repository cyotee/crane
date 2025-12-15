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

contract ERC721EnumeratedFacet is IFacet, IERC721Enumerated {
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
        return type(ERC721EnumeratedFacet).name;
    }
    // end::facetName[]

    // tag::facetInterfaces()[]
    /**
     * @inheritdoc IFacet
     */
    function facetInterfaces() public pure returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(IERC721Enumerated).interfaceId;
    }
    // end::facetInterfaces[]

    // tag::facetFuncs()[]
    /**
     * @inheritdoc IFacet
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

    /* -------------------------- IERC721 Overrides ------------------------- */

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external {
        ERC721EnumeratedRepo._safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external {
        ERC721EnumeratedRepo._safeTransferFrom(from, to, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId) external {
        ERC721EnumeratedRepo._transferFrom(from, to, tokenId);
    }

    /* --------------------------- IERC721Enumerated -------------------------- */

    function tokenIds() external view returns (uint256[] memory) {
        return ERC721EnumeratedRepo._tokenIds();
    }

    function ownedIds(address owner) external view returns (uint256[] memory) {
        return ERC721EnumeratedRepo._ownedIds(owner);
    }

    function globalOperatorOf(address owner) external view returns (address) {
        return ERC721EnumeratedRepo._globalOperatorOf(owner);
    }
}
