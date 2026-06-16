// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IBountyCommon} from "@crane/contracts/bounties/common/IBountyCommon.sol";

interface ISingleFinalBounty is IBountyCommon {
    event SingleBountyCreated(uint256 indexed bountyId, address indexed issuer, address indexed funder, string specUri);
    event DeliverableApproved(uint256 indexed bountyId, address indexed approver, address recipient);

    function createSingleBounty(
        string memory specUri,
        string memory encryptionPubKeyUri,
        address funder,
        uint256 deadline,
        uint8 access, // 0=open 1=closed
        address[] memory tokens,
        uint256[] memory amounts
    ) external returns (uint256 bountyId);

    function submitDeliverable(uint256 bountyId, string[] memory deliverableUris) external;

    function approveDeliverable(uint256 bountyId) external;
}
