// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {SingleFinalBountyTarget} from "@crane/contracts/bounties/single/SingleFinalBountyTarget.sol";
import {ISingleFinalBounty} from "@crane/contracts/bounties/single/ISingleFinalBounty.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {FacetBase} from "@crane/contracts/factories/diamondPkg/FacetBase.sol";

contract SingleFinalBountyFacet is SingleFinalBountyTarget, FacetBase {
    function facetName() public pure override returns (string memory name) {
        return type(SingleFinalBountyFacet).name;
    }

    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ISingleFinalBounty).interfaceId;
    }

    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](4);
        funcs[0] = ISingleFinalBounty.createSingleBounty.selector;
        funcs[1] = ISingleFinalBounty.submitDeliverable.selector;
        funcs[2] = ISingleFinalBounty.approveDeliverable.selector;
        // common selectors provided by BountyCommonFacet
    }
}
