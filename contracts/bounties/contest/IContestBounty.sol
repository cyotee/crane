// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IBountyCommon} from "@crane/contracts/bounties/common/IBountyCommon.sol";

// tag::IContestBounty[]
/**
 * @title IContestBounty - Contest bounty creation, submission, and prize assignment interface.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Interface for contest-style bounties supporting multiple prize tiers.
 *         Creators define prize amounts and a set of deliverables are judged by issuer (or owner).
 *         Inherits common bounty lifecycle (fund/cancel/views/disputes) + IArbitrable.rule .
 * @dev Follows gold interface standards (IMultiStepOwnable.sol, IOperable.sol, IReentrancyLock.sol).
 *      No @custom:selector / @custom:signature / @custom:interfaceid inserted here because
 *      CENTRALLY_COMPUTED_NATSPEC_VALUES.md (read ONLY) has no entries for IContestBounty symbols;
 *      values computed for doc history in gap report only. Use type(IContestBounty).interfaceId at runtime.
 */
interface IContestBounty is IBountyCommon {
    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::createContestBounty(string-uint256[]-address-uint256-uint8-address[]-uint256[])[]
    /**
     * @notice Creates a new contest bounty with fixed prize structure.
     * @param specUri URI pointing to the full contest specification, requirements and judging criteria.
     * @param prizeAmounts Array of prize tier amounts (order should align with intended winner ranking; semantics defined by issuer).
     * @param funder The designated funder account (may receive contribution events); pass msg.sender or explicit.
     * @param deadline Unix timestamp after which the bounty is no longer accepting work (enforced by impl).
     * @param access Access mode: 0 = Open (anyone may submit), 1 = Closed (restricted via setAllowedSubmitter).
     * @param tokens Tokens to seed initial funding for the bounty (length must match amounts).
     * @param amounts Token amounts to contribute at creation time.
     * @return bountyId Newly allocated bounty identifier (incremental per board).
     * @custom:emits BountyCreated(uint256 indexed, BountyType, address indexed, address indexed)
     * @custom:emits BountyFunded(uint256 indexed, address indexed, address, uint256)
     */
    function createContestBounty(
        string memory specUri,
        uint256[] memory prizeAmounts,
        address funder,
        uint256 deadline,
        uint8 access,
        address[] memory tokens,
        uint256[] memory amounts
    ) external returns (uint256 bountyId);
    // end::createContestBounty(string-uint256[]-address-uint256-uint8-address[]-uint256[])[]

    // tag::submitForContest(uint256-string[])[]
    /**
     * @notice Submits one or more deliverables (e.g. links to work product) against an open contest bounty.
     * @dev Caller must be allowed submitter (for closed access) per BountyRepo checks. Multiple submissions possible until closed.
     * @param bountyId Identifier of the contest bounty.
     * @param deliverableUris URIs describing or pointing to the submitted deliverables for this entry.
     * @custom:emits DeliverableSubmitted(uint256 indexed, address indexed, string[])
     */
    function submitForContest(uint256 bountyId, string[] memory deliverableUris) external;
    // end::submitForContest(uint256-string[])[]

    // tag::assignPrizes(uint256-address[])[]
    /**
     * @notice Finalizes a contest by assigning prizes to one or more winners and marks the bounty closed.
     *         Only the original issuer or the board owner (MultiStepOwnable) may call.
     * @param bountyId The contest bounty to close and pay out.
     * @param winners Recipient addresses; caller is responsible for ensuring length/ordering matches prizeAmounts.
     * @custom:emits BountyClosed(uint256 indexed)
     */
    function assignPrizes(uint256 bountyId, address[] memory winners) external;
    // end::assignPrizes(uint256-address[])[]
}
// end::IContestBounty[]
