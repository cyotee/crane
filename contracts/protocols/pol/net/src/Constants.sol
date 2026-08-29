// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

/// @title Constants — single source of truth (specs/mechanism.md §7)
/// @notice Every number in the specs appears exactly once here as a named
///         constant. Items marked TUNE are `DEFAULT — TUNE BEFORE DEPLOY`;
///         they may be retuned by the human before mainnet, only via the
///         named constant — never a new owner function. The full table is
///         mirrored in contracts/README.md.
library Constants {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant BPS = 10_000;
    /// @dev NET has 9 decimals; 1 whole NET = 1e9 base units.
    uint256 internal constant NET_UNIT = 1e9;

    // ── Emissions (IMMUTABLE at deploy — specs/mechanism.md §2) ──
    uint256 internal constant EPOCH_LENGTH = 8 hours;
    /// @dev R_MAX = 0.45% per epoch, as WAD.
    uint256 internal constant R_MAX_WAD = 0.0045e18;
    /// @dev K = 1.75 premium for full emissions, as WAD.
    uint256 internal constant K_WAD = 1.75e18;
    /// @dev mechanism §2 (FINAL): min spacing between oracle checkpoints.
    uint256 internal constant CHECKPOINT_MIN_INTERVAL = 30 minutes;
    /// @dev mechanism §2 (FINAL): a TWAP read is valid only over a window in
    ///      [TWAP_MIN_WINDOW, TWAP_MAX_WINDOW]; outside the band, dependent
    ///      operations fail closed (Distributor mints 0; market ops revert).
    uint256 internal constant TWAP_MIN_WINDOW = 30 minutes;
    uint256 internal constant TWAP_MAX_WINDOW = 4 hours;
    uint256 internal constant STAKING_WARMUP_EPOCHS = 0; // TUNE

    // ── Trading tax (specs/tax.md, specs/mechanism.md §4) ──
    uint256 internal constant TAX_TOTAL_BPS = 500;
    /// @dev Revised 2026-07-12 (was 300): decay starts at 4%/1%.
    uint256 internal constant TAX_TEAM_START_BPS = 400;
    /// @dev Coupling: must exceed the v2 LP fee (30 bps) + max-clip price
    ///      impact (~50 bps at TAX_SWAP_MAX_CLIP_BPS = 50), or convert()
    ///      reverts under normal conditions. Keep DEV ≥ CLIP + 40 bps.
    uint256 internal constant TAX_SWAP_MAX_DEV_BPS = 100; // TUNE
    uint256 internal constant TAX_SWAP_MAX_CLIP_BPS = 50; // TUNE
    /// @dev Q7: delay before a queued tax exemption takes effect.
    uint256 internal constant EXEMPT_DELAY = 2 days; // TUNE

    // ── pTEAM (IMMUTABLE — specs/mechanism.md §5) ──
    uint256 internal constant VEST_DURATION = 30 days;
    uint256 internal constant PTEAM_CAP_BPS = 1500;
    uint256 internal constant PTEAM_STRIKE_WAD = 1e18;

    // ── Genesis (specs/genesis.md) ──
    uint256 internal constant GENESIS_PRICE_WAD = 3e18; // TUNE
    /// @dev Revised 2026-07-12 (was 300k / 10k / 100k).
    uint256 internal constant GENESIS_HARD_CAP_WAD = 50_000e18; // TUNE
    uint256 internal constant GENESIS_WALLET_CAP_WAD = 2_000e18; // TUNE
    uint256 internal constant GENESIS_MIN_RAISE_WAD = 15_000e18; // TUNE
    uint256 internal constant GENESIS_VEST = 5 days; // TUNE
    uint256 internal constant GENESIS_DEADLINE = 7 days; // TUNE (FINAL 2026-07-12)
    uint256 internal constant TREASURY_SPLIT_BPS = 7000; // TUNE

    // ── Treasury / Morpho (specs/treasury.md §2) ──
    uint256 internal constant MORPHO_CAP_BPS = 7000; // TUNE
    uint256 internal constant MORPHO_HAIRCUT_BPS = 200; // TUNE

    // ── Market making (specs/treasury.md §4, FINAL 2026-07-12) ──
    /// @dev InverseBond standing bid: payout = backing × (1 − spread).
    uint256 internal constant INVERSE_SPREAD_BPS = 150; // TUNE
    /// @dev Per-epoch fill capacity, bps of liquid (non-Morpho) reserves;
    ///      recomputed fresh each epoch, no rollover.
    uint256 internal constant INVERSE_EPOCH_CAP_BPS = 100; // TUNE
    uint256 internal constant PREMIUM_THRESHOLD_WAD = 2e18; // TUNE
    /// @dev 25 bps of pool NET reserves PER EXECUTION (treasury §4 FINAL).
    uint256 internal constant PREMIUM_CLIP_BPS = 25; // TUNE
    uint256 internal constant PREMIUM_MIN_INTERVAL = 1 hours;
    /// @dev D3: named bound for PremiumSeller's TWAP-bounded slippage.
    uint256 internal constant PREMIUM_MAX_DEV_BPS = 100; // TUNE

    // ── BondDepository (Q11 resolution) ──
    uint256 internal constant BOND_VEST = 2 days;
    uint256 internal constant BOND_DISCOUNT_BPS = 300; // TUNE (Q11)
    /// @dev Per-epoch payout cap as bps of totalSupply (scales with supply).
    uint256 internal constant BOND_EPOCH_CAP_BPS = 25; // TUNE (Q11)
}
