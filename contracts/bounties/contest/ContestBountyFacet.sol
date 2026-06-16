// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ContestBountyTarget} from "@crane/contracts/bounties/contest/ContestBountyTarget.sol";
import {IContestBounty} from "@crane/contracts/bounties/contest/IContestBounty.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {FacetBase} from "@crane/contracts/factories/diamondPkg/FacetBase.sol";

contract ContestBountyFacet is ContestBountyTarget, FacetBase {
    function facetName() public pure override returns (string memory name) {
        return type(ContestBountyFacet).name;
    }

    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IContestBounty).interfaceId;
    }

    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IContestBounty.createContestBounty.selector;
        funcs[1] = IContestBounty.submitForContest.selector;
        funcs[2] = IContestBounty.assignPrizes.selector;
    }
}
