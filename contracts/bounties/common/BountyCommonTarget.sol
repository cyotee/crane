// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IBountyCommon} from "@crane/contracts/bounties/common/IBountyCommon.sol";
import {BountyRepo} from "@crane/contracts/bounties/common/BountyRepo.sol";
import {BountyBoardConfigRepo} from "@crane/contracts/bounties/common/BountyBoardConfigRepo.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@crane/contracts/utils/SafeERC20.sol";
import {ICallTargetRegistryQuery} from "@crane/contracts/interfaces/ICallTargetRegistryQuery.sol";
import {IArbitrator} from "@crane/contracts/interfaces/IArbitrator.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";
import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";

contract BountyCommonTarget is IBountyCommon, MultiStepOwnableModifiers {
    using SafeERC20 for IERC20;

    event BountyCreated(uint256 indexed bountyId, BountyRepo.BountyType bType, address indexed issuer, address indexed funder);
    event BountyFunded(uint256 indexed bountyId, address indexed contributor, address token, uint256 amount);
    event BountyCanceled(uint256 indexed bountyId);
    event BountyClosed(uint256 indexed bountyId);
    event ContributionWithdrawn(uint256 indexed bountyId, address indexed contributor, address token, uint256 amount);
    event DeliverableSubmitted(uint256 indexed bountyId, address indexed submitter, string[] uris);
    event DeliverableApproved(uint256 indexed bountyId, address indexed approver, address recipient, uint256 subIndex, uint256[] amounts);
    event DisputeCreated(uint256 indexed bountyId, uint256 indexed disputeId, uint256 subIndex, address raisedBy);

    // --- Config / Arbitrator ---

    function getCurrentArbitrator() public view returns (address) {
        return BountyBoardConfigRepo._resolveArbitrator();
    }

    // --- Bounty views (common) ---

    function getBounty(uint256 bountyId)
        public
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
        )
    {
        BountyRepo.Bounty storage b = BountyRepo._bounty(BountyRepo._layoutStruct(), bountyId);
        id = b.id;
        bType = uint8(b.bType);
        access = uint8(b.access);
        issuer = b.issuer;
        funder = b.funder;
        status = uint8(b.status);
        specUri = b.specUri;
        encryptionPubKeyUri = b.encryptionPubKeyUri;
        createdAt = b.createdAt;
        deadline = b.deadline;
    }

    function getTotalContributed(uint256 bountyId, address token) public view returns (uint256) {
        return BountyRepo._getTotalContributed(BountyRepo._layoutStruct(), bountyId, token);
    }

    function getDisbursed(uint256 bountyId, address token) public view returns (uint256) {
        return BountyRepo._getDisbursed(BountyRepo._layoutStruct(), bountyId, token);
    }

    function getRemaining(uint256 bountyId, address token) public view returns (uint256) {
        return BountyRepo._getRemaining(BountyRepo._layoutStruct(), bountyId, token);
    }

    function getContribution(uint256 bountyId, address contributor, address token) public view returns (uint256) {
        return BountyRepo._getContribution(BountyRepo._layoutStruct(), bountyId, contributor, token);
    }

    // --- Funding ---

    function fundBounty(uint256 bountyId, address token, uint256 amount) public {
        require(amount > 0, "amount=0");
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, bountyId);
        require(b.id == bountyId, "no bounty");
        require(b.status == BountyRepo.BountyStatus.Open, "not open");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        BountyRepo._addContribution(rs, bountyId, msg.sender, token, amount);

        emit BountyFunded(bountyId, msg.sender, token, amount);
    }

    function cancelBounty(uint256 bountyId) public {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, bountyId);
        require(b.id == bountyId, "no bounty");
        require(b.status == BountyRepo.BountyStatus.Open, "not open");
        require(msg.sender == b.issuer || msg.sender == b.funder || msg.sender == MultiStepOwnableRepo._owner(), "not authorized");

        BountyRepo._setStatus(rs, bountyId, BountyRepo.BountyStatus.Canceled);
        emit BountyCanceled(bountyId);
    }

    function withdrawContribution(uint256 bountyId, address token) public {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, bountyId);
        require(b.id == bountyId, "no bounty");

        bool isFunder = msg.sender == b.funder;
        bool isClosedOrCanceled = b.status == BountyRepo.BountyStatus.Closed || b.status == BountyRepo.BountyStatus.Canceled;
        require(isFunder ? isClosedOrCanceled : true, "funder withdraw only post close/cancel");

        uint256 amt = BountyRepo._getContribution(rs, bountyId, msg.sender, token);
        require(amt > 0, "no contrib");

        uint256 remaining = BountyRepo._getRemaining(rs, bountyId, token);
        require(amt <= remaining, "insufficient remaining");

        // Debit: reduce contrib and total, increase disbursed
        BountyRepo._subtractContribution(rs, bountyId, msg.sender, token, amt);
        BountyRepo._addDisbursed(rs, bountyId, token, amt);

        IERC20(token).safeTransfer(msg.sender, amt);

        emit ContributionWithdrawn(bountyId, msg.sender, token, amt);
    }

    // --- Closed management ---

    function setAllowedSubmitter(uint256 bountyId, address submitter, bool allowed) public onlyOwner {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, bountyId);
        require(b.id == bountyId, "no bounty");
        if (allowed) {
            BountyRepo._addAllowedSubmitter(rs, bountyId, submitter);
        } else {
            BountyRepo._removeAllowedSubmitter(rs, bountyId, submitter);
        }
    }

    // --- Disputes ---

    function createDispute(uint256 bountyId, uint256 subIndex, uint256 choices, bytes calldata extraData)
        public
        payable
        returns (uint256 disputeId)
    {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, bountyId);
        require(b.id == bountyId, "no bounty");
        // basic auth: issuer, funder, or a submitter/anyone for open? For now allow issuer or current submit context. Broad for v1.
        require(msg.sender == b.issuer || msg.sender == b.funder || BountyRepo._isSubmitterAllowed(rs, bountyId, msg.sender), "not allowed to dispute");

        address arb = getCurrentArbitrator();
        require(arb != address(0), "no arbitrator");

        uint256 cost = IArbitrator(arb).arbitrationCost(extraData);
        require(msg.value >= cost, "insufficient fee");

        disputeId = IArbitrator(arb).createDispute{value: cost}(choices, extraData);

        BountyRepo.DisputeInfo memory info = BountyRepo.DisputeInfo({
            bountyId: bountyId,
            subIndex: subIndex,
            raisedBy: msg.sender
        });
        BountyRepo._setDisputeInfo(rs, disputeId, info);

        emit DisputeCreated(bountyId, disputeId, subIndex, msg.sender);
    }

    function rule(uint256 disputeId, uint256 ruling) external override {
        address arb = getCurrentArbitrator();
        require(msg.sender == arb, "only arbitrator");
        require(ruling != 0, "no decision");

        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        BountyRepo.DisputeInfo memory info = BountyRepo._getDisputeInfo(rs, disputeId);
        require(info.bountyId != 0, "unknown dispute");

        BountyRepo.Bounty storage b = BountyRepo._bounty(rs, info.bountyId);
        // Simple policy: ruling==1 favor claimant (release to raisedBy or designated worker), 2 favor issuer (refund main to funder)
        // For v1, on 1 we pay the remaining pot to the raiser (simplified; real impl per-type would select recipient)
        // On 2 refund remaining to funder (per token loop in caller or here for main tokens? simplified single token awareness later)
        // Real per-type facets can override or we use events + state for off-chain follow up. Here we do a basic transfer.

        if (ruling == 1) {
            // favor the one who raised (worker side) - pay all remaining of all? simplistic: caller should handle specific.
            // For demo we leave funds and mark; sophisticated would transfer known reward.
            // To keep token-agnostic, we do nothing on-chain here beyond emit; actual release via separate or type facet.
            // For minimal working: transfer 0, just close.
            BountyRepo._markClosed(rs, info.bountyId);
        } else if (ruling == 2) {
            // favor issuer: allow funder to withdraw freely by marking closed
            BountyRepo._markClosed(rs, info.bountyId);
        }

        emit Ruling(msg.sender, disputeId, ruling);
    }

    // Internal helpers for type facets to use (not exposed via interface necessarily)
    function _recordPayout(uint256 bountyId, address token, uint256 amount, address recipient) internal {
        require(amount > 0, "amt=0");
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        uint256 remaining = BountyRepo._getRemaining(rs, bountyId, token);
        require(amount <= remaining, "over pay");

        BountyRepo._addDisbursed(rs, bountyId, token, amount);
        IERC20(token).safeTransfer(recipient, amount);
    }

    function _createBountyRecord(
        BountyRepo.BountyType bType,
        address funder,
        string memory specUri,
        string memory encryptionPubKeyUri,
        uint256 deadline,
        BountyRepo.BountyAccess access
    ) internal returns (uint256 id) {
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        id = BountyRepo._incrementBountyId(rs);
        BountyRepo._initializeBounty(
            rs,
            id,
            bType,
            msg.sender,
            funder == address(0) ? msg.sender : funder,
            specUri,
            encryptionPubKeyUri,
            deadline,
            access
        );
        emit BountyCreated(id, bType, msg.sender, funder == address(0) ? msg.sender : funder);
    }

    function _addInitialFunding(uint256 id, address[] memory tokens, uint256[] memory amounts) internal {
        require(tokens.length == amounts.length, "len mismatch");
        BountyRepo.Storage storage rs = BountyRepo._layoutStruct();
        for (uint256 i = 0; i < tokens.length; i++) {
            if (amounts[i] == 0) continue;
            address t = tokens[i];
            uint256 a = amounts[i];
            IERC20(t).safeTransferFrom(msg.sender, address(this), a);
            BountyRepo._addContribution(rs, id, msg.sender, t, a); // credit initial to sender; adjust if needed
            emit BountyFunded(id, msg.sender, t, a);
        }
    }
}
