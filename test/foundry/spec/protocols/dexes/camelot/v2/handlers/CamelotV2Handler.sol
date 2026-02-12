// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

/// @title CamelotV2Handler
/// @notice Handler contract for Camelot V2 invariant fuzz testing
/// @dev Exposes swap, mint, and burn operations for the fuzzer to call.
///      Tracks K values before/after operations for invariant verification.
///
///      K INVARIANT BEHAVIOR BY OPERATION:
///      - Swaps:  K_new >= K_old  (trading fees accumulate in reserves)
///      - Mints:  K_new > K_old   (new liquidity increases both reserves)
///      - Burns:  K_new < K_old   (removing liquidity reduces reserves proportionally)
///
///      The handler only asserts K non-decrease for swaps and mints. Burns legitimately
///      reduce K because burning LP tokens removes a proportional share of both reserves.
contract CamelotV2Handler is Test {
    ICamelotPair public pair;
    ICamelotV2Router public router;
    ERC20PermitMintableStub public token0;
    ERC20PermitMintableStub public token1;

    // Tracked K values for invariant verification
    uint256 public kBefore;
    uint256 public kAfter;

    // Last operation type for context-aware invariants
    enum OpType { NONE, SWAP, MINT, BURN }
    OpType public lastOpType;

    // Operation counters for debugging
    uint256 public swapCount;
    uint256 public mintCount;
    uint256 public burnCount;

    // Ghost state tracking
    uint256 public minKSeen;
    uint256 public maxKSeen;

    // Track K before any burns to verify fees accumulated via swaps
    uint256 public kBeforeFirstBurn;
    bool public hasRecordedKBeforeFirstBurn;

    // Burn proportional invariant tracking
    uint256 public burnKBefore;
    uint256 public burnKAfter;
    uint256 public burnLpBurned;
    uint256 public burnReserve0Before;
    uint256 public burnReserve1Before;
    uint256 public burnReserve0After;
    uint256 public burnReserve1After;
    uint256 public burnHandlerLpBefore;
    uint256 public burnHandlerLpAfter;
    bool public burnProportionalViolation;
    bool public burnRatioViolation;
    bool public burnLpBalanceViolation;

    // Constants
    uint256 constant MIN_LIQUIDITY = 1e15; // Minimum amount for operations
    uint256 constant MAX_LIQUIDITY = 1e24; // Maximum amount for operations
    uint256 constant FEE_DENOMINATOR = 100000;

    constructor() {}

    /// @notice Attach the pair and router after deployment
    function initialize(
        ICamelotPair pair_,
        ICamelotV2Router router_,
        ERC20PermitMintableStub token0_,
        ERC20PermitMintableStub token1_
    ) external {
        pair = pair_;
        router = router_;
        token0 = token0_;
        token1 = token1_;
    }

    /// @notice Compute K from current reserves using the pair's formula
    function computeK() public view returns (uint256 k) {
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        if (pair.stableSwap()) {
            // Stable swap: K = x^3*y + y^3*x (normalized)
            uint256 pm0 = pair.precisionMultiplier0();
            uint256 pm1 = pair.precisionMultiplier1();
            uint256 x = uint256(r0) * 1e18 / pm0;
            uint256 y = uint256(r1) * 1e18 / pm1;
            uint256 a = (x * y) / 1e18;
            uint256 b = (x * x / 1e18) + (y * y / 1e18);
            k = (a * b) / 1e18;
        } else {
            // Non-stable: K = reserve0 * reserve1
            k = uint256(r0) * uint256(r1);
        }
    }

    /// @notice Record K before an operation
    function _recordKBefore() internal {
        kBefore = computeK();
        if (kBefore > 0 && (minKSeen == 0 || kBefore < minKSeen)) {
            minKSeen = kBefore;
        }
    }

    /// @notice Record K after an operation and update max
    function _recordKAfter() internal {
        kAfter = computeK();
        if (kAfter > maxKSeen) {
            maxKSeen = kAfter;
        }
    }

    /// @notice Normalize fuzz input to valid swap amount
    function _normalizeSwapAmount(uint256 seed) internal view returns (uint256) {
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        uint256 minReserve = r0 < r1 ? r0 : r1;
        // Swap between 0.1% and 10% of the smaller reserve
        uint256 minSwap = minReserve / 1000;
        uint256 maxSwap = minReserve / 10;
        if (maxSwap <= minSwap) return 0;
        return minSwap + (seed % (maxSwap - minSwap));
    }

    /// @notice Normalize fuzz input to valid liquidity amount
    function _normalizeLiquidityAmount(uint256 seed) internal pure returns (uint256) {
        // Bound to reasonable liquidity range
        return MIN_LIQUIDITY + (seed % (MAX_LIQUIDITY - MIN_LIQUIDITY));
    }

    /* -------------------------------------------------------------------------- */
    /*                            Fuzzable Operations                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Swap token0 for token1
    /// @param amountSeed Fuzz seed for swap amount
    function swapToken0ForToken1(uint256 amountSeed) external {
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        if (r0 == 0 || r1 == 0) return; // Skip if no liquidity

        uint256 amountIn = _normalizeSwapAmount(amountSeed);
        if (amountIn == 0) return;

        _recordKBefore();

        // Mint tokens and approve
        token0.mint(address(this), amountIn);
        token0.approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(token0);
        path[1] = address(token1);

        try router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // Accept any amount out
            path,
            address(this),
            address(0), // No referrer
            block.timestamp + 300
        ) {
            swapCount++;
            lastOpType = OpType.SWAP;
        } catch {
            // Swap failed, that's ok for fuzzing
        }

        _recordKAfter();
    }

    /// @notice Swap token1 for token0
    /// @param amountSeed Fuzz seed for swap amount
    function swapToken1ForToken0(uint256 amountSeed) external {
        (uint112 r0, uint112 r1,,) = pair.getReserves();
        if (r0 == 0 || r1 == 0) return; // Skip if no liquidity

        uint256 amountIn = _normalizeSwapAmount(amountSeed);
        if (amountIn == 0) return;

        _recordKBefore();

        // Mint tokens and approve
        token1.mint(address(this), amountIn);
        token1.approve(address(router), amountIn);

        address[] memory path = new address[](2);
        path[0] = address(token1);
        path[1] = address(token0);

        try router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            0, // Accept any amount out
            path,
            address(this),
            address(0), // No referrer
            block.timestamp + 300
        ) {
            swapCount++;
            lastOpType = OpType.SWAP;
        } catch {
            // Swap failed, that's ok for fuzzing
        }

        _recordKAfter();
    }

    /// @notice Add liquidity to the pair
    /// @param amount0Seed Fuzz seed for token0 amount
    /// @param amount1Seed Fuzz seed for token1 amount
    function addLiquidity(uint256 amount0Seed, uint256 amount1Seed) external {
        uint256 amount0 = _normalizeLiquidityAmount(amount0Seed);
        uint256 amount1 = _normalizeLiquidityAmount(amount1Seed);

        _recordKBefore();

        // Mint tokens
        token0.mint(address(this), amount0);
        token1.mint(address(this), amount1);
        token0.approve(address(router), amount0);
        token1.approve(address(router), amount1);

        try router.addLiquidity(
            address(token0),
            address(token1),
            amount0,
            amount1,
            0, // Accept any amount
            0, // Accept any amount
            address(this),
            block.timestamp + 300
        ) {
            mintCount++;
            lastOpType = OpType.MINT;
        } catch {
            // Mint failed, that's ok for fuzzing
        }

        _recordKAfter();
    }

    /// @notice Remove liquidity from the pair (burn operation)
    /// @dev K will decrease after this operation. This is expected AMM behavior:
    ///      burning LP tokens removes a proportional share of both reserves,
    ///      so K_new = reserve0_new * reserve1_new < reserve0_old * reserve1_old.
    /// @param percentSeed Fuzz seed for percentage of LP tokens to burn (1-50%)
    function removeLiquidity(uint256 percentSeed) external {
        uint256 lpBalance = pair.balanceOf(address(this));
        if (lpBalance == 0) return;

        // Burn between 1% and 50% of LP tokens
        uint256 percent = 1 + (percentSeed % 50);
        uint256 lpToRemove = (lpBalance * percent) / 100;
        if (lpToRemove == 0) return;

        // Record K before first burn for fee accumulation test
        if (!hasRecordedKBeforeFirstBurn) {
            kBeforeFirstBurn = computeK();
            hasRecordedKBeforeFirstBurn = true;
        }

        _recordKBefore();

        // Record burn proportional state BEFORE
        burnKBefore = kBefore;
        (uint112 rb0, uint112 rb1,,) = pair.getReserves();
        burnReserve0Before = uint256(rb0);
        burnReserve1Before = uint256(rb1);
        burnLpBurned = lpToRemove;
        burnHandlerLpBefore = pair.balanceOf(address(this));

        // Approve router to spend LP tokens
        IERC20(address(pair)).approve(address(router), lpToRemove);

        try router.removeLiquidity(
            address(token0),
            address(token1),
            lpToRemove,
            0, // Accept any amount
            0, // Accept any amount
            address(this),
            block.timestamp + 300
        ) {
            burnCount++;
            lastOpType = OpType.BURN;

            // Record burn proportional state AFTER
            burnHandlerLpAfter = pair.balanceOf(address(this));
            (uint112 ra0, uint112 ra1,,) = pair.getReserves();
            burnReserve0After = uint256(ra0);
            burnReserve1After = uint256(ra1);
        } catch {
            // Burn failed, that's ok for fuzzing
        }

        _recordKAfter();
        if (lastOpType == OpType.BURN) {
            burnKAfter = kAfter;
            _checkBurnProportionalInvariants();
        }
    }

    /// @notice Verify burn proportional invariants after a successful burn
    /// @dev Note: Camelot (Uni V2-style) pair mints protocol fee LP tokens inside
    ///      burn(), which changes totalSupply before the actual burn. We track the
    ///      handler's own LP balance to verify exact burn amount, and use reserve
    ///      changes to verify proportionality.
    function _checkBurnProportionalInvariants() internal {
        // Check 1: Handler's LP balance decreases by exact burn amount
        if (burnHandlerLpAfter != burnHandlerLpBefore - burnLpBurned) {
            burnLpBalanceViolation = true;
        }

        // Check 2: Reserve ratio remains constant (cross-multiply to avoid division)
        // r0_before * r1_after == r1_before * r0_after (within tolerance)
        if (burnReserve0Before > 0 && burnReserve1Before > 0 &&
            burnReserve0After > 0 && burnReserve1After > 0) {
            uint256 crossA = burnReserve0Before * burnReserve1After;
            uint256 crossB = burnReserve1Before * burnReserve0After;
            // Allow 0.1% tolerance for rounding
            uint256 tolerance = crossA / 1000;
            if (crossA > crossB + tolerance || crossB > crossA + tolerance) {
                burnRatioViolation = true;
            }
        }

        // Check 3: K scales proportionally with reserves removed
        // Since reserves are withdrawn proportionally: r_after = r_before * (1 - burned/supplyAtBurn)
        // K_after = r0_after * r1_after = K_before * (1 - burned/supplyAtBurn)^2
        // Equivalently: K_after * r0_before ~= K_before * r0_after (linear proportionality per reserve)
        // More precisely: r0_after/r0_before ~= r1_after/r1_before (both scale same)
        // And K_after/K_before ~= (r0_after/r0_before)^2
        if (burnKBefore > 0 && burnReserve0Before > 0 && burnReserve0After > 0) {
            // K_after * r0_before^2 ~= K_before * r0_after^2
            // Scale down to prevent overflow
            uint256 lhs = (burnKAfter / 1e9) * (burnReserve0Before / 1e3) * (burnReserve0Before / 1e3);
            uint256 rhs = (burnKBefore / 1e9) * (burnReserve0After / 1e3) * (burnReserve0After / 1e3);

            // 0.1% tolerance
            uint256 propTolerance = rhs / 1000;
            if (propTolerance == 0) propTolerance = 1;
            if (lhs > rhs + propTolerance || rhs > lhs + propTolerance) {
                burnProportionalViolation = true;
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            View Functions                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Check if K increased or stayed the same after last SWAP operation
    /// @dev K should only be non-decreasing for swaps. Burns decrease K proportionally.
    function kNeverDecreasedAfterSwap() external view returns (bool) {
        // Only check for swaps
        if (lastOpType != OpType.SWAP) return true;
        if (kBefore == 0) return true;
        // Allow for tiny rounding errors (1 wei)
        return kAfter >= kBefore || (kBefore - kAfter) <= 1;
    }

    /// @notice Check if K increased after last MINT operation
    function kIncreasedAfterMint() external view returns (bool) {
        // Only check for mints
        if (lastOpType != OpType.MINT) return true;
        if (kBefore == 0) return true;
        return kAfter >= kBefore;
    }

    /// @notice Get the last operation type
    function getLastOpType() external view returns (OpType) {
        return lastOpType;
    }

    /// @notice Get reserves from the pair
    function getReserves() external view returns (uint112 r0, uint112 r1) {
        (r0, r1,,) = pair.getReserves();
    }

    /// @notice Get kLast from the pair
    function getKLast() external view returns (uint256) {
        return pair.kLast();
    }

    /// @notice Get total operations performed
    function totalOperations() external view returns (uint256) {
        return swapCount + mintCount + burnCount;
    }

    /// @notice Check if burn proportional K invariant has held
    function burnProportionalKHeld() external view returns (bool) {
        return !burnProportionalViolation;
    }

    /// @notice Check if burn reserve ratio invariant has held
    function burnReserveRatioHeld() external view returns (bool) {
        return !burnRatioViolation;
    }

    /// @notice Check if burn LP balance invariant has held
    function burnLpBalanceExactHeld() external view returns (bool) {
        return !burnLpBalanceViolation;
    }
}
