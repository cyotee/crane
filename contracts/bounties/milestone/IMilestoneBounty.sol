// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IBountyCommon} from "@crane/contracts/bounties/common/IBountyCommon.sol";

interface IMilestoneBounty is IBountyCommon {
    function createMilestoneBounty(
        string memory globalSpecUri,
        string[] memory milestonePrdUris,
        address funder,
        uint256 deadline,
        uint8 access,
        address[] memory tokens,
        uint256[] memory amounts
    ) external returns (uint256 bountyId);
    function submitMilestone(uint256 bountyId, uint256 milestoneIndex, string[] memory deliverableUris) external;
    function approveMilestone(uint256 bountyId, uint256 milestoneIndex) external;
}
