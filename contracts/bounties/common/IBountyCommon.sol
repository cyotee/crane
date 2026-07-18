// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IArbitrable} from "@crane/contracts/interfaces/IArbitrable.sol";

/**
 * @title IBountyCommon
 * @notice Common functions available on any Bounty Board diamond (shared across types).
 */
interface IBountyCommon is IArbitrable {
    // --- Views ---
    function getBounty(uint256 bountyId)
        external
        view
        returns (
            uint256 id,
            uint8 bType,
            uint8 access,
            address issuer,
            address funder,
            uint8 status,
            string memory specUri,
            string memory encryptionPubKeyUri,
            uint256 createdAt,
            uint256 deadline
        );

    function getTotalContributed(uint256 bountyId, address token) external view returns (uint256);
    function getDisbursed(uint256 bountyId, address token) external view returns (uint256);
    function getRemaining(uint256 bountyId, address token) external view returns (uint256);
    function getContribution(uint256 bountyId, address contributor, address token) external view returns (uint256);
    function getCurrentArbitrator() external view returns (address);

    // --- Funding / Lifecycle (callable by appropriate parties) ---
    function fundBounty(uint256 bountyId, address token, uint256 amount) external;
    function cancelBounty(uint256 bountyId) external;
    function withdrawContribution(uint256 bountyId, address token) external;

    // --- Closed bounties ---
    function setAllowedSubmitter(uint256 bountyId, address submitter, bool allowed) external;

    // --- Disputes ---
    function createDispute(uint256 bountyId, uint256 subIndex, uint256 choices, bytes calldata extraData)
        external
        payable
        returns (uint256 disputeId);

    // rule from IArbitrable
}
