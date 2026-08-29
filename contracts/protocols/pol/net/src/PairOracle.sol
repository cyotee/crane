// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";

/// @title PairOracle — canonical-pair TWAP (specs/mechanism.md §2, FINAL)
/// @notice Uniswap v2 cumulative-price oracle over the canonical NET/USDG
///         pair. `checkpoint()` is permissionless with a minimum 30-minute
///         spacing (CHECKPOINT_MIN_INTERVAL); `Staking.rebase()` also
///         checkpoints each 8h epoch. A TWAP read is valid ONLY over a window
///         between TWAP_MIN_WINDOW (30 min) and TWAP_MAX_WINDOW (4 h):
///         outside the band every dependent operation fails closed — the
///         Distributor mints nothing, InverseBond and PremiumSeller refuse to
///         settle. Spot price is never used; anyone can revive a stale oracle
///         with one poke plus a 30-minute wait.
contract PairOracle is IPairOracle {
    error WindowOutOfBand();
    error NoObservation();
    error ZeroPrice();
    error RingSizeMismatch();

    struct Observation {
        uint32 timestamp;
        uint256 priceCumulative;
    }

    /// @dev Ring sized to hold a full max window of 30-min observations, ×2
    ///      (= TWAP_MAX_WINDOW / CHECKPOINT_MIN_INTERVAL × 2; asserted in the
    ///      constructor since array lengths need a literal).
    uint256 private constant SLOTS = 16;

    IUniswapV2Pair public immutable pairContract;
    /// @notice True when NET is token0 of the pair.
    bool public immutable netIsToken0;
    /// @dev Scale factor from UQ112 raw ratio to WAD USDG per whole NET:
    ///      10^(18 + netDecimals − usdgDecimals).
    uint256 public immutable priceScale;

    Observation[SLOTS] public observations;
    uint64 public lastCheckpointAt;

    constructor(address pair_, address net_, address usdg_) {
        if (SLOTS != (Constants.TWAP_MAX_WINDOW / Constants.CHECKPOINT_MIN_INTERVAL) * 2) {
            revert RingSizeMismatch();
        }
        pairContract = IUniswapV2Pair(pair_);
        netIsToken0 = IUniswapV2Pair(pair_).token0() == net_;
        priceScale = 10 ** (18 + 9 - IERC20Metadata(usdg_).decimals());
    }

    function pair() external view returns (address) {
        return address(pairContract);
    }

    function twapMinWindow() external pure returns (uint256) {
        return Constants.TWAP_MIN_WINDOW;
    }

    function twapMaxWindow() external pure returns (uint256) {
        return Constants.TWAP_MAX_WINDOW;
    }

    /// @inheritdoc IPairOracle
    function checkpoint() public {
        (uint112 r0, uint112 r1,) = pairContract.getReserves();
        if (r0 == 0 || r1 == 0) return; // pre-liquidity: never record garbage
        if (block.timestamp - lastCheckpointAt < Constants.CHECKPOINT_MIN_INTERVAL) return;
        lastCheckpointAt = uint64(block.timestamp);
        // Ring-buffer slot index, not randomness: timestamp-bucketed so a
        // slot is only overwritten after the full ring duration (8h) has
        // passed and the observation is out of the TWAP validity band anyway.
        // slither-disable-next-line weak-prng
        uint256 slot = (block.timestamp / Constants.CHECKPOINT_MIN_INTERVAL) % SLOTS;
        observations[slot] = Observation({
            timestamp: uint32(block.timestamp), priceCumulative: _currentCumulative()
        });
        emit Checkpointed(observations[slot].priceCumulative, uint32(block.timestamp));
    }

    /// @inheritdoc IPairOracle
    function twapNetUsdg() external view returns (uint256) {
        // Newest observation aged at least TWAP_MIN_WINDOW.
        uint256 bestTs = 0;
        uint256 bestCum = 0;
        for (uint256 i = 0; i < SLOTS; i++) {
            Observation storage obs = observations[i];
            uint256 ts = obs.timestamp;
            if (ts == 0) continue;
            if (block.timestamp - ts < Constants.TWAP_MIN_WINDOW) continue;
            if (ts > bestTs) {
                bestTs = ts;
                bestCum = obs.priceCumulative;
            }
        }
        if (bestTs == 0) revert NoObservation();
        uint256 elapsed = block.timestamp - bestTs;
        // Fail-closed band (mechanism §2): stale oracle pauses dependents.
        if (elapsed > Constants.TWAP_MAX_WINDOW) revert WindowOutOfBand();

        uint256 cumNow = _currentCumulative();
        uint256 avgUQ112;
        unchecked {
            // v2 cumulatives are designed to overflow-wrap.
            avgUQ112 = (cumNow - bestCum) / elapsed;
        }
        uint256 priceWad = FixedPointMath.mulDiv(avgUQ112, priceScale, 1 << 112);
        if (priceWad == 0) revert ZeroPrice();
        return priceWad;
    }

    /// @dev Counterfactual current cumulative price of NET in the quote
    ///      token, extrapolated from the last on-pair update (flashloan-
    ///      resistant: only time-weighted history enters the average).
    function _currentCumulative() internal view returns (uint256 cum) {
        cum =
            netIsToken0 ? pairContract.price0CumulativeLast() : pairContract.price1CumulativeLast();
        (uint112 r0, uint112 r1, uint32 tsLast) = pairContract.getReserves();
        uint32 nowTs = uint32(block.timestamp);
        if (tsLast != nowTs && r0 != 0 && r1 != 0) {
            uint32 delta;
            unchecked {
                delta = nowTs - tsLast;
            }
            (uint112 quoteReserve, uint112 netReserve) = netIsToken0 ? (r1, r0) : (r0, r1);
            unchecked {
                cum += (uint256(quoteReserve) << 112) / netReserve * delta;
            }
        }
    }
}
