// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {TestBase_IFacet} from "@crane/contracts/factories/diamondPkg/TestBase_IFacet.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IERC721} from "@crane/contracts/interfaces/IERC721.sol";
import {ERC721Facet} from "@crane/contracts/tokens/ERC721/ERC721Facet.sol";

/**
 * @title ERC721Facet_IFacet_Test
 * @notice Tests ERC721Facet IFacet interface compliance
 */
contract ERC721Facet_IFacet_Test is TestBase_IFacet {

    bytes4 private constant _SAFE_TRANSFER_FROM_WITH_DATA_SELECTOR =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant _SAFE_TRANSFER_FROM_SELECTOR =
        bytes4(keccak256("safeTransferFrom(address,address,uint256)"));

    function facetTestInstance() public override returns (IFacet) {
        return IFacet(address(new ERC721Facet()));
    }

    function controlFacetName() public pure override returns (string memory) {
        return "ERC721Facet";
    }

    function controlFacetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC721).interfaceId;
    }

    function controlFacetFuncs() public pure override returns (bytes4[] memory funcs) {
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
}
