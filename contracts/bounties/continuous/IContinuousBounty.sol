// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IBountyCommon} from "@crane/contracts/bounties/common/IBountyCommon.sol";

// tag::IContinuousBounty[]
/**
 * @title IContinuousBounty - Interface for continuous/recurring bounties paying per approved delivery.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Declares creation, submission, and approval flows for continuous bounties (as opposed to contest, milestone, or single-final).
 *         Extends IBountyCommon for shared bounty lifecycle, funding, disputes, and arbitrator integration.
 * @dev This interface surface is exposed on Diamond proxies composed with ContinuousBountyFacet (via its DFPkg).
 *      Custom NatSpec values (interfaceid/selector/signature) are omitted per CENTRALLY_COMPUTED_NATSPEC_VALUES.md
 *      (no entries for IContinuousBounty symbols; do not fabricate). Follows IMultiStepOwnable/IOperable/ICallTarget* gold for tags.
 */
interface IContinuousBounty is IBountyCommon {
    /* -------------------------------------------------------------------------- */
    /*                                  Functions                                 */
    /* -------------------------------------------------------------------------- */

    // tag::createContinuousBounty(string-uint256-uint256-address-uint256-uint8-address[]-uint256[])[]
    /**
     * @notice Creates a continuous bounty which pays a fixed `paymentPerDelivery` for each approved delivery.
     * @param specUri URI pointing to the bounty specification/requirements.
     * @param paymentPerDelivery The amount (per funded token unit) disbursed to submitter upon each approval.
     * @param submissionTimer Time window (seconds) allowed for submissions after creation or prior approval?
     * @param funder The address providing the initial funding (or 0 for issuer-funded later).
     * @param deadline Timestamp after which no further activity is allowed.
     * @param access Access control flag (0=open, 1=closed/allow-listed submitters via common).
     * @param tokens ERC20 tokens for initial funding.
     * @param amounts Corresponding amounts for each token.
     * @return bountyId The ID of the newly created continuous bounty.
     * @custom:emits BountyCreated (from IBountyCommon)
     */
    function createContinuousBounty(
        string memory specUri,
        uint256 paymentPerDelivery,
        uint256 submissionTimer,
        address funder,
        uint256 deadline,
        uint8 access,
        address[] memory tokens,
        uint256[] memory amounts
    ) external returns (uint256 bountyId);
    // end::createContinuousBounty(string-uint256-uint256-address-uint256-uint8-address[]-uint256[])[]

    // tag::submitDelivery(uint256-string[])[]
    /**
     * @notice Submits one or more deliverable URIs against a continuous bounty.
     * @dev Only allowed submitters (open or pre-approved via setAllowedSubmitter on common).
     * @param bountyId The ID of the continuous bounty.
     * @param deliverableUris URIs describing the submitted work/deliverables.
     * @custom:emits DeliverableSubmitted (from common target)
     */
    function submitDelivery(uint256 bountyId, string[] memory deliverableUris) external;
    // end::submitDelivery(uint256-string[])[]

    // tag::approveDelivery(uint256)[]
    /**
     * @notice Approves the latest (or pending) delivery for the continuous bounty, triggering payout of paymentPerDelivery.
     * @dev Restricted to issuer or owner.
     * @param bountyId The ID of the continuous bounty.
     * @custom:emits DeliverableApproved (from common target); may close or advance the continuous record.
     */
    function approveDelivery(uint256 bountyId) external;
    // end::approveDelivery(uint256)[]
}
// end::IContinuousBounty[]
