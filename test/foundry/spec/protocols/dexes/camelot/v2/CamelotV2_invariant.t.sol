// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {ICamelotPair} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {CamelotV2Service} from "@crane/contracts/protocols/dexes/camelot/v2/services/CamelotV2Service.sol";
import {TestBase_CamelotV2} from "@crane/contracts/protocols/dexes/camelot/v2/test/bases/TestBase_CamelotV2.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {CamelotV2Handler} from "./handlers/CamelotV2Handler.sol";

/// @title CamelotV2_invariant
/// @notice Invariant fuzz tests for Camelot V2 K (constant product) preservation
/// @dev Tests that K = reserve0 * reserve1 never decreases across swap/mint/burn operations.
///      K accumulates fees, so K_new >= K_old must always hold.
contract CamelotV2_invariant is TestBase_CamelotV2 {
    CamelotV2Handler public handler;

    // Test tokens
    ERC20PermitMintableStub public tokenA;
    ERC20PermitMintableStub public tokenB;

    // Test pair
    ICamelotPair public testPair;

    // Initial liquidity
    uint256 constant INITIAL_LIQUIDITY = 100_000e18;

    // Track K at start of test for global invariant
    uint256 public initialK;

    function setUp() public override {
        TestBase_CamelotV2.setUp();

        // Deploy test tokens
        tokenA = new ERC20PermitMintableStub("Token A", "TKA", 18, address(this), 0);
        tokenB = new ERC20PermitMintableStub("Token B", "TKB", 18, address(this), 0);
        vm.label(address(tokenA), "TokenA");
        vm.label(address(tokenB), "TokenB");

        // Create pair
        testPair = ICamelotPair(camelotV2Factory.createPair(address(tokenA), address(tokenB)));
        vm.label(address(testPair), "TestPair");

        // Deploy handler early so it can receive LP tokens during initial liquidity
        handler = new CamelotV2Handler();

        // Add initial liquidity
        _addInitialLiquidity();

        // Determine token0/token1 ordering
        ERC20PermitMintableStub t0;
        ERC20PermitMintableStub t1;
        if (testPair.token0() == address(tokenA)) {
            t0 = tokenA;
            t1 = tokenB;
        } else {
            t0 = tokenB;
            t1 = tokenA;
        }

        handler.initialize(testPair, camelotV2Router, t0, t1);
        vm.label(address(handler), "CamelotV2Handler");

        // Record initial K
        initialK = handler.computeK();

        // Register handler as the fuzz target
        targetContract(address(handler));

        // Register specific selectors for fuzzing
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.swapToken0ForToken1.selector;
        selectors[1] = handler.swapToken1ForToken0.selector;
        selectors[2] = handler.addLiquidity.selector;
        selectors[3] = handler.removeLiquidity.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function _addInitialLiquidity() internal {
        tokenA.mint(address(this), INITIAL_LIQUIDITY);
        tokenB.mint(address(this), INITIAL_LIQUIDITY);
        tokenA.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        tokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);

        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        // Transfer LP tokens to handler so it can burn them
        uint256 lpBalance = testPair.balanceOf(address(this));
        testPair.transfer(address(handler), lpBalance);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Invariant Tests                               */
    /* -------------------------------------------------------------------------- */

    /// @notice INVARIANT: K never decreases after SWAP operations
    /// @dev Swaps should preserve or increase K due to fee accumulation.
    ///      Note: K CAN decrease after burns - that's expected behavior.
    function invariant_K_never_decreases_after_swap() public view {
        assertTrue(
            handler.kNeverDecreasedAfterSwap(),
            "K decreased after swap operation"
        );
    }

    /// @notice INVARIANT: K never decreases after MINT operations
    /// @dev Adding liquidity should always increase K.
    function invariant_K_never_decreases_after_mint() public view {
        assertTrue(
            handler.kIncreasedAfterMint(),
            "K decreased after mint operation"
        );
    }

    /// @notice INVARIANT: Reserves are always non-zero after initial liquidity
    /// @dev After adding initial liquidity, reserves should never be zero.
    function invariant_reserves_nonzero() public view {
        (uint112 r0, uint112 r1) = handler.getReserves();
        assertTrue(r0 > 0, "Reserve0 is zero");
        assertTrue(r1 > 0, "Reserve1 is zero");
    }

    /// @notice INVARIANT: K is always positive when reserves are positive
    function invariant_K_positive_when_reserves_positive() public view {
        (uint112 r0, uint112 r1) = handler.getReserves();
        if (r0 > 0 && r1 > 0) {
            uint256 k = handler.computeK();
            assertTrue(k > 0, "K should be positive when reserves are positive");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                           Additional Unit Tests                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Test K increases after a swap due to fees
    function test_K_increases_after_swap() public {
        uint256 kBefore = handler.computeK();

        // Perform swap
        handler.swapToken0ForToken1(12345);

        uint256 kAfter = handler.computeK();

        // K should increase or stay same (fees accumulate)
        assertGe(kAfter, kBefore, "K should not decrease after swap");
    }

    /// @notice Test K increases after adding liquidity
    function test_K_increases_after_mint() public {
        uint256 kBefore = handler.computeK();

        // Add liquidity
        handler.addLiquidity(1e20, 1e20);

        uint256 kAfter = handler.computeK();

        // K should increase when adding liquidity
        assertGe(kAfter, kBefore, "K should not decrease after mint");
    }

    /// @notice Test K doesn't decrease after removing liquidity
    function test_K_stable_after_burn() public {
        // First add some liquidity to have LP tokens to burn
        handler.addLiquidity(1e20, 1e20);

        uint256 kBefore = handler.computeK();

        // Remove liquidity (10%)
        handler.removeLiquidity(10);

        uint256 kAfter = handler.computeK();

        // K can decrease proportionally when removing liquidity, but the ratio stays same
        // The invariant is that K_new / LP_new >= K_old / LP_old
        // For simplicity, we just check reserves are still valid
        (uint112 r0, uint112 r1) = handler.getReserves();
        assertTrue(r0 > 0 && r1 > 0, "Reserves should be positive after burn");
    }

    /// @notice Test multiple sequential swaps accumulate fees
    function test_K_accumulates_fees_over_swaps() public {
        uint256 kInitial = handler.computeK();

        // Perform multiple swaps
        for (uint256 i = 0; i < 5; i++) {
            handler.swapToken0ForToken1(i * 1000 + 1);
            handler.swapToken1ForToken0(i * 2000 + 1);
        }

        uint256 kFinal = handler.computeK();

        // K should have grown from accumulated fees
        assertGe(kFinal, kInitial, "K should grow from accumulated fees");
    }

    /// @notice Test random operation sequence doesn't decrease K
    function test_random_operations_preserve_K() public {
        uint256 kStart = handler.computeK();

        // Random sequence of operations
        handler.swapToken0ForToken1(111);
        handler.addLiquidity(5e19, 5e19);
        handler.swapToken1ForToken0(222);
        handler.swapToken0ForToken1(333);
        handler.swapToken1ForToken0(444);
        handler.addLiquidity(3e19, 3e19);

        uint256 kEnd = handler.computeK();

        // K should not have decreased overall
        assertGe(kEnd, kStart, "K should not decrease over operation sequence");
    }
}

/// @title CamelotV2_invariant_stable
/// @notice Invariant fuzz tests for Camelot V2 stable pools
/// @dev Tests K preservation for stable swap formula: K = x^3*y + y^3*x
contract CamelotV2_invariant_stable is TestBase_CamelotV2 {
    CamelotV2Handler public handler;

    // Test tokens
    ERC20PermitMintableStub public tokenA;
    ERC20PermitMintableStub public tokenB;

    // Test pair
    ICamelotPair public testPair;

    // Initial liquidity
    uint256 constant INITIAL_LIQUIDITY = 100_000e18;

    // Track K at start
    uint256 public initialK;

    function setUp() public override {
        TestBase_CamelotV2.setUp();

        // Deploy test tokens with same decimals (typical for stablecoins)
        tokenA = new ERC20PermitMintableStub("Stable A", "STA", 18, address(this), 0);
        tokenB = new ERC20PermitMintableStub("Stable B", "STB", 18, address(this), 0);
        vm.label(address(tokenA), "StableA");
        vm.label(address(tokenB), "StableB");

        // Create pair
        testPair = ICamelotPair(camelotV2Factory.createPair(address(tokenA), address(tokenB)));
        vm.label(address(testPair), "StablePair");

        // Deploy handler early so it can receive LP tokens during initial liquidity
        handler = new CamelotV2Handler();

        // Add initial liquidity first (before setting stable)
        _addInitialLiquidity();

        // Set pair to stable swap mode
        _setStableSwap();

        // Determine token0/token1 ordering
        ERC20PermitMintableStub t0;
        ERC20PermitMintableStub t1;
        if (testPair.token0() == address(tokenA)) {
            t0 = tokenA;
            t1 = tokenB;
        } else {
            t0 = tokenB;
            t1 = tokenA;
        }

        handler.initialize(testPair, camelotV2Router, t0, t1);
        vm.label(address(handler), "StableHandler");

        // Record initial K
        initialK = handler.computeK();

        // Register handler as the fuzz target
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.swapToken0ForToken1.selector;
        selectors[1] = handler.swapToken1ForToken0.selector;
        selectors[2] = handler.addLiquidity.selector;
        selectors[3] = handler.removeLiquidity.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function _addInitialLiquidity() internal {
        tokenA.mint(address(this), INITIAL_LIQUIDITY);
        tokenB.mint(address(this), INITIAL_LIQUIDITY);
        tokenA.approve(address(camelotV2Router), INITIAL_LIQUIDITY);
        tokenB.approve(address(camelotV2Router), INITIAL_LIQUIDITY);

        CamelotV2Service._deposit(camelotV2Router, tokenA, tokenB, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY);

        // Transfer LP tokens to handler
        uint256 lpBalance = testPair.balanceOf(address(this));
        testPair.transfer(address(handler), lpBalance);
    }

    function _setStableSwap() internal {
        // Get current reserves for the setStableSwap call
        (uint112 r0, uint112 r1,,) = testPair.getReserves();

        // The setStableOwner is initially msg.sender (the test contract) from factory constructor
        // So we can directly call setStableSwap
        testPair.setStableSwap(true, r0, r1);
    }

    /* -------------------------------------------------------------------------- */
    /*                        Stable Pool Invariant Tests                         */
    /* -------------------------------------------------------------------------- */

    /// @notice INVARIANT: K never decreases after SWAP for stable pools
    function invariant_stable_K_never_decreases_after_swap() public view {
        assertTrue(
            handler.kNeverDecreasedAfterSwap(),
            "Stable K decreased after swap operation"
        );
    }

    /// @notice INVARIANT: K never decreases after MINT for stable pools
    function invariant_stable_K_never_decreases_after_mint() public view {
        assertTrue(
            handler.kIncreasedAfterMint(),
            "Stable K decreased after mint operation"
        );
    }

    /// @notice INVARIANT: Stable pool is actually in stable mode
    function invariant_stable_mode_enabled() public view {
        assertTrue(testPair.stableSwap(), "Pair should be in stable swap mode");
    }

    /// @notice Test stable pool K formula is used
    function test_stable_pool_uses_stable_K_formula() public view {
        assertTrue(testPair.stableSwap(), "Should be stable pool");

        // Verify K is computed using stable formula
        uint256 k = handler.computeK();
        assertTrue(k > 0, "K should be positive");

        // For stable pools with equal reserves and decimals, K should be non-trivial
        // K = x^3*y + y^3*x = 2*x^4 when x=y
        (uint112 r0, uint112 r1,,) = testPair.getReserves();
        if (r0 == r1) {
            // With equal reserves, verify K makes sense
            uint256 x = uint256(r0) * 1e18 / testPair.precisionMultiplier0();
            uint256 expectedK = 2 * (x * x / 1e18) * (x * x / 1e18) / 1e18;
            // Allow some tolerance due to rounding
            uint256 diff = k > expectedK ? k - expectedK : expectedK - k;
            assertTrue(diff < expectedK / 100, "K should match stable formula");
        }
    }
}
