// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";
import {IDistributor} from "@crane/contracts/protocols/pol/net/src/interfaces/IDistributor.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {Wired} from "@crane/contracts/protocols/pol/net/src/abstract/Wired.sol";

/// @title Staking — NET ⇄ sNET (shareholder dividend program)
/// @notice 8h epochs, permissionless `rebase()` (specs/mechanism.md §2–3):
///         distributes the previous epoch's reward via sNET rebase, then
///         checkpoints the TWAP oracle and pulls the next epoch's
///         Distributor mint. One epoch advances per call; back-to-back calls
///         catch up if epochs were missed. Enabled by GenesisBond.finalize().
contract Staking is IStaking, Wired {
    error NotEnabled();
    error AlreadyEnabled();
    error NotGenesisBond();
    error TransferFailed();
    error ThirdPartyWarmup();

    IERC20 public immutable net;
    IsNET public immutable sNet;
    /// @notice Warmup in epochs (DEFAULT 0 — TUNE BEFORE DEPLOY). Constructor
    ///         arg (from Constants in deploy scripts) for testability.
    uint256 public immutable warmupEpochs;

    IDistributor public distributor;
    IPairOracle public oracle;
    address public genesisBond;

    bool public enabled;

    struct EpochState {
        uint64 length;
        uint64 number;
        uint64 end;
        uint256 distribute;
    }

    EpochState private _epoch;

    struct WarmupEntry {
        uint256 gons;
        uint64 releaseEpoch;
    }

    mapping(address => WarmupEntry) public warmup;

    constructor(address net_, address sNet_, uint256 warmupEpochs_) {
        net = IERC20(_nonZero(net_));
        sNet = IsNET(_nonZero(sNet_));
        warmupEpochs = warmupEpochs_;
    }

    /// @notice One-time wiring (Distributor ↔ Staking are mutually
    ///         referential). Frozen afterwards; on the emissions path this is
    ///         the only address set, and it cannot be re-set (invariant §6.7).
    function wire(address distributor_, address oracle_, address genesisBond_) external wiring {
        distributor = IDistributor(_nonZero(distributor_));
        oracle = IPairOracle(_nonZero(oracle_));
        genesisBond = _nonZero(genesisBond_);
    }

    /// @inheritdoc IStaking
    function enable() external {
        _checkWired();
        if (msg.sender != genesisBond) revert NotGenesisBond();
        if (enabled) revert AlreadyEnabled();
        enabled = true;
        _epoch = EpochState({
            length: uint64(Constants.EPOCH_LENGTH),
            number: 1,
            end: uint64(block.timestamp + Constants.EPOCH_LENGTH),
            distribute: 0
        });
    }

    /// @inheritdoc IStaking
    function epoch() external view returns (uint64, uint64, uint64, uint256) {
        return (_epoch.length, _epoch.number, _epoch.end, _epoch.distribute);
    }

    /// @inheritdoc IStaking
    function stake(address to, uint256 amount) external returns (uint256) {
        if (!enabled) revert NotEnabled();
        _rebaseIfDue();
        if (!net.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        if (warmupEpochs == 0) {
            _sendSNet(to, amount);
        } else {
            // Third-party stakes may not touch someone else's warmup clock:
            // a dust stake would otherwise re-arm `releaseEpoch` forever.
            if (to != msg.sender) revert ThirdPartyWarmup();
            WarmupEntry storage entry = warmup[to];
            entry.gons += sNet.gonsForBalance(amount);
            entry.releaseEpoch = uint64(_epoch.number + warmupEpochs);
        }
        emit Staked(msg.sender, to, amount);
        return amount;
    }

    /// @notice Claims sNET matured past warmup (no-op path when warmup is 0).
    function claim(address to) external returns (uint256) {
        if (!enabled) revert NotEnabled();
        _rebaseIfDue();
        WarmupEntry memory entry = warmup[to];
        if (entry.gons == 0 || _epoch.number < entry.releaseEpoch) return 0;
        delete warmup[to];
        uint256 amount = sNet.balanceForGons(entry.gons);
        _sendSNet(to, amount);
        return amount;
    }

    /// @inheritdoc IStaking
    function unstake(address to, uint256 amount) external returns (uint256) {
        if (!enabled) revert NotEnabled();
        _rebaseIfDue();
        if (!sNet.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        if (!net.transfer(to, amount)) revert TransferFailed();
        emit Unstaked(msg.sender, to, amount);
        return amount;
    }

    /// @inheritdoc IStaking
    function rebase() public {
        if (!enabled) revert NotEnabled();
        _rebaseIfDue();
    }

    function _rebaseIfDue() internal {
        if (block.timestamp < _epoch.end) return;
        // Distribute only when someone is staked; otherwise the queued NET
        // stays queued (never stranded) until stakers return.
        uint256 circulating = sNet.totalSupply() - sNet.balanceOf(address(this));
        uint256 distributed = 0;
        if (circulating > 0) {
            distributed = _epoch.distribute;
            sNet.rebase(distributed, _epoch.number);
            _epoch.distribute = 0;
        }
        emit Rebased(_epoch.number, distributed);
        _epoch.end += _epoch.length;
        _epoch.number += 1;
        // Keep the oracle live even if all keepers stall (D1).
        oracle.checkpoint();
        _epoch.distribute += distributor.distribute();
    }

    /// @inheritdoc IStaking
    function totalStaked() external view returns (uint256) {
        return sNet.totalSupply() - sNet.balanceOf(address(this));
    }

    function _sendSNet(address to, uint256 amount) internal {
        if (!sNet.transfer(to, amount)) revert TransferFailed();
    }
}
