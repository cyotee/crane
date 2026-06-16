// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BountyCommonTarget} from "@crane/contracts/bounties/common/BountyCommonTarget.sol";
import {IBountyCommon} from "@crane/contracts/bounties/common/IBountyCommon.sol";
import {IArbitrable} from "@crane/contracts/interfaces/IArbitrable.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {FacetBase} from "@crane/contracts/factories/diamondPkg/FacetBase.sol";

contract BountyCommonFacet is BountyCommonTarget, FacetBase {
    function facetName() public pure override returns (string memory name) {
        return type(BountyCommonFacet).name;
    }

    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IBountyCommon).interfaceId;
        interfaces[1] = type(IArbitrable).interfaceId;
    }

    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](12);
        funcs[0] = IBountyCommon.getBounty.selector;
        funcs[1] = IBountyCommon.getTotalContributed.selector;
        funcs[2] = IBountyCommon.getDisbursed.selector;
        funcs[3] = IBountyCommon.getRemaining.selector;
        funcs[4] = IBountyCommon.getContribution.selector;
        funcs[5] = IBountyCommon.getCurrentArbitrator.selector;
        funcs[6] = IBountyCommon.fundBounty.selector;
        funcs[7] = IBountyCommon.cancelBounty.selector;
        funcs[8] = IBountyCommon.withdrawContribution.selector;
        funcs[9] = IBountyCommon.setAllowedSubmitter.selector;
        funcs[10] = IBountyCommon.createDispute.selector;
        funcs[11] = IArbitrable.rule.selector;
    }
}
