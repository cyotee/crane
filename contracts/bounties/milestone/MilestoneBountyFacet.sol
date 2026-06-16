// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MilestoneBountyTarget} from "@crane/contracts/bounties/milestone/MilestoneBountyTarget.sol";
import {IMilestoneBounty} from "@crane/contracts/bounties/milestone/IMilestoneBounty.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {FacetBase} from "@crane/contracts/factories/diamondPkg/FacetBase.sol";

contract MilestoneBountyFacet is MilestoneBountyTarget, FacetBase {
    function facetName() public pure override returns (string memory name) {
        return type(MilestoneBountyFacet).name;
    }

    function facetInterfaces() public pure override returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IMilestoneBounty).interfaceId;
    }

    function facetFuncs() public pure override returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IMilestoneBounty.createMilestoneBounty.selector;
        funcs[1] = IMilestoneBounty.submitMilestone.selector;
        funcs[2] = IMilestoneBounty.approveMilestone.selector;
    }
}
