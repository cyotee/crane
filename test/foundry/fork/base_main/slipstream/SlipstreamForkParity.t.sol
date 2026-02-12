// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {CLFactory} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/CLFactory.sol";
import {CLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/CLPool.sol";
import {TestBase_SlipstreamFork} from
    "@crane/contracts/protocols/dexes/aerodrome/slipstream/test/bases/TestBase_SlipstreamFork.sol";
import {ICLPool} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLPool.sol";
import {ICLFactory} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/ICLFactory.sol";
import {ICLMintCallback} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/callback/ICLMintCallback.sol";
import {ICLSwapCallback} from "@crane/contracts/protocols/dexes/aerodrome/slipstream/interfaces/callback/ICLSwapCallback.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v3/libraries/TickMath.sol";
import {MockERC20} from "@crane/contracts/test/mocks/MockERC20.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

contract SlipstreamCallbackHarness is ICLMintCallback, ICLSwapCallback {
    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external {
        (address token0, address token1) = abi.decode(data, (address, address));
        if (amount0Owed > 0) require(IERC20(token0).transfer(msg.sender, amount0Owed), "mintCallback: t0");
        if (amount1Owed > 0) require(IERC20(token1).transfer(msg.sender, amount1Owed), "mintCallback: t1");
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        (address token0, address token1) = abi.decode(data, (address, address));
        if (amount0Delta > 0) require(IERC20(token0).transfer(msg.sender, uint256(amount0Delta)), "swapCallback: t0");
        if (amount1Delta > 0) require(IERC20(token1).transfer(msg.sender, uint256(amount1Delta)), "swapCallback: t1");
    }
}

/// @title Slipstream Fork Parity Tests
/// @notice Compares production Slipstream behavior to our ported CLFactory/CLPool on a Base mainnet fork
/// @dev Run with: forge test --match-path "test/foundry/fork/base_main/slipstream/*"
contract SlipstreamForkParityTest is TestBase_SlipstreamFork {
    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    int24 internal constant PARITY_TICK_SPACING = 200;
    uint160 internal constant INITIAL_SQRT_PRICE_X96 = uint160(1) << 96; // tick = 0
    uint128 internal constant TEST_LIQUIDITY = 1_000_000;

    CLPool internal localPoolImplementation;
    CLFactory internal localFactory;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    ICLPool internal productionPool;
    ICLPool internal localPool;

    SlipstreamCallbackHarness internal callback;

    function setUp() public override {
        super.setUp();

        if (!forkEnabled) return;
        assertForkActive();

        callback = new SlipstreamCallbackHarness();
        vm.label(address(callback), "SlipstreamCallbackHarness");

        // Deploy test tokens on fork
        tokenA = new MockERC20("TokenA", "TKA", 18);
        tokenB = new MockERC20("TokenB", "TKB", 6);
        vm.label(address(tokenA), "SlipstreamTestTokenA");
        vm.label(address(tokenB), "SlipstreamTestTokenB");

        // Fund callback harness (used to pay pool callbacks)
        tokenA.mint(address(callback), 1e30);
        tokenB.mint(address(callback), 1e30);

        // Deploy our local (ported) CL stack on the fork
        localPoolImplementation = new CLPool();
        vm.label(address(localPoolImplementation), "LocalSlipstreamCLPoolImpl");

        // Reuse production voter for registry address wiring; local pools won't have gauges anyway.
        localFactory = new CLFactory(address(productionFactory.voter()), address(0), address(localPoolImplementation));
        vm.label(address(localFactory), "LocalSlipstreamCLFactory");

        (productionPool, localPool) = _createMatchingPools(address(tokenA), address(tokenB), PARITY_TICK_SPACING);
    }

    function _createMatchingPools(address token0, address token1, int24 tickSpacing)
        internal
        returns (ICLPool productionPool_, ICLPool localPool_)
    {
        // Create pool on production factory
        address prod = productionFactory.createPool(token0, token1, tickSpacing, INITIAL_SQRT_PRICE_X96);
        productionPool_ = ICLPool(prod);
        vm.label(prod, "ProductionSlipstreamPool");

        // Create pool on local factory
        address loc = localFactory.createPool(token0, token1, tickSpacing, INITIAL_SQRT_PRICE_X96);
        localPool_ = ICLPool(loc);
        vm.label(loc, "LocalSlipstreamPool");

        // Sanity: token ordering must match
        assertEq(localPool_.token0(), productionPool_.token0());
        assertEq(localPool_.token1(), productionPool_.token1());
    }

    function _positionKey(address owner, int24 tickLower, int24 tickUpper) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(owner, tickLower, tickUpper));
    }

    function _mintViaCallback(ICLPool pool, int24 tickLower, int24 tickUpper, uint128 liquidityAmount)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        (amount0, amount1) = ICLPool(pool).mint(
            address(this),
            tickLower,
            tickUpper,
            liquidityAmount,
            abi.encode(pool.token0(), pool.token1())
        );
    }

    function _swapExactInput(ICLPool pool, bool zeroForOne, uint256 amountIn) internal returns (uint256 amountOut) {
        uint160 limit = zeroForOne ? TickMath.MIN_SQRT_RATIO + 1 : TickMath.MAX_SQRT_RATIO - 1;
        (int256 amount0Delta, int256 amount1Delta) = ICLPool(pool).swap(
            address(this),
            zeroForOne,
            int256(amountIn),
            limit,
            abi.encode(pool.token0(), pool.token1())
        );
        amountOut = zeroForOne ? uint256(-amount1Delta) : uint256(-amount0Delta);
    }

    /* -------------------------------------------------------------------------- */
    /*                                Parity Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_Parity_createPool_initialize() public onlyFork {
        assertForkActive();

        // Pool invariants after createPool+initialize
        assertEq(productionPool.tickSpacing(), PARITY_TICK_SPACING);
        assertEq(localPool.tickSpacing(), PARITY_TICK_SPACING);

        (uint160 prodPrice, int24 prodTick,,,, bool prodUnlocked) = productionPool.slot0();
        (uint160 locPrice, int24 locTick,,,, bool locUnlocked) = localPool.slot0();
        assertEq(prodPrice, INITIAL_SQRT_PRICE_X96, "prod sqrtPrice");
        assertEq(locPrice, INITIAL_SQRT_PRICE_X96, "local sqrtPrice");
        assertEq(locPrice, prodPrice, "sqrtPrice parity");
        assertEq(locTick, prodTick, "tick parity");
        assertTrue(prodUnlocked && locUnlocked, "unlocked");

        // Fee should match for identical tickSpacing pools
        assertEq(localPool.fee(), productionPool.fee(), "fee parity");
    }

    function test_Parity_mint_burn_collect() public onlyFork {
        assertForkActive();

        int24 tickLower = -400;
        int24 tickUpper = 400;

        // Mint identical liquidity
        {
            (uint256 prod0, uint256 prod1) = callbackMint(productionPool, tickLower, tickUpper, TEST_LIQUIDITY);
            (uint256 loc0, uint256 loc1) = callbackMint(localPool, tickLower, tickUpper, TEST_LIQUIDITY);
            assertEq(loc0, prod0, "mint amount0 parity");
            assertEq(loc1, prod1, "mint amount1 parity");
            assertEq(localPool.liquidity(), productionPool.liquidity(), "liquidity parity");
        }

        // Burn half
        {
            (uint256 prodBurn0, uint256 prodBurn1) = productionPool.burn(tickLower, tickUpper, TEST_LIQUIDITY / 2);
            (uint256 locBurn0, uint256 locBurn1) = localPool.burn(tickLower, tickUpper, TEST_LIQUIDITY / 2);
            assertEq(locBurn0, prodBurn0, "burn amount0 parity");
            assertEq(locBurn1, prodBurn1, "burn amount1 parity");
        }

        // Collect owed amounts
        {
            (uint128 prodCol0, uint128 prodCol1) = productionPool.collect(
                address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max
            );
            (uint128 locCol0, uint128 locCol1) = localPool.collect(
                address(this), tickLower, tickUpper, type(uint128).max, type(uint128).max
            );
            assertEq(uint256(locCol0), uint256(prodCol0), "collect amount0 parity");
            assertEq(uint256(locCol1), uint256(prodCol1), "collect amount1 parity");
        }

        // Position liquidity must match
        {
            bytes32 key = _positionKey(address(this), tickLower, tickUpper);
            (uint128 prodLiq,,,,) = productionPool.positions(key);
            (uint128 locLiq,,,,) = localPool.positions(key);
            assertEq(locLiq, prodLiq, "position liquidity parity");
        }
    }

    function callbackMint(ICLPool pool, int24 tickLower, int24 tickUpper, uint128 liquidityAmount)
        internal
        returns (uint256 amount0, uint256 amount1)
    {
        vm.startPrank(address(callback));
        (amount0, amount1) = _mintViaCallback(pool, tickLower, tickUpper, liquidityAmount);
        vm.stopPrank();
    }

    function callbackSwap(ICLPool pool, bool zeroForOne, uint256 amountIn) internal returns (uint256 amountOut) {
        vm.startPrank(address(callback));
        amountOut = _swapExactInput(pool, zeroForOne, amountIn);
        vm.stopPrank();
    }

    function test_Parity_swap_bothDirections() public onlyFork {
        assertForkActive();

        // Add liquidity around current tick
        int24 tickLower = -400;
        int24 tickUpper = 400;
        callbackMint(productionPool, tickLower, tickUpper, TEST_LIQUIDITY);
        callbackMint(localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        uint256 amountIn = 1e12;
        uint256 prodOut0to1 = callbackSwap(productionPool, true, amountIn);
        uint256 locOut0to1 = callbackSwap(localPool, true, amountIn);
        assertEq(locOut0to1, prodOut0to1, "swap 0->1 parity");

        uint256 prodOut1to0 = callbackSwap(productionPool, false, amountIn);
        uint256 locOut1to0 = callbackSwap(localPool, false, amountIn);
        assertEq(locOut1to0, prodOut1to0, "swap 1->0 parity");
    }

    function test_Parity_swap_tickCrossing() public onlyFork {
        assertForkActive();

        // Multiple positions to ensure tick crossing behavior is exercised.
        int24 tickLower1 = -800;
        int24 tickUpper1 = 800;
        int24 tickLower2 = -200;
        int24 tickUpper2 = 200;

        callbackMint(productionPool, tickLower1, tickUpper1, TEST_LIQUIDITY);
        callbackMint(productionPool, tickLower2, tickUpper2, TEST_LIQUIDITY);
        callbackMint(localPool, tickLower1, tickUpper1, TEST_LIQUIDITY);
        callbackMint(localPool, tickLower2, tickUpper2, TEST_LIQUIDITY);

        (, int24 tickBeforeProd,,,,) = productionPool.slot0();
        (, int24 tickBeforeLoc,,,,) = localPool.slot0();
        assertEq(tickBeforeLoc, tickBeforeProd, "tick before parity");

        // Large swap to force price movement across initialized ticks.
        uint256 amountIn = 1e18;
        uint256 prodOut = callbackSwap(productionPool, true, amountIn);
        uint256 locOut = callbackSwap(localPool, true, amountIn);
        assertEq(locOut, prodOut, "tick-cross swap output parity");

        (, int24 tickAfterProd,,,,) = productionPool.slot0();
        (, int24 tickAfterLoc,,,,) = localPool.slot0();
        assertEq(tickAfterLoc, tickAfterProd, "tick after parity");

        int24 tickDelta = tickAfterProd - tickBeforeProd;
        if (tickDelta < 0) tickDelta = -tickDelta;
        assertTrue(tickDelta >= PARITY_TICK_SPACING, "expected tick crossing");
    }

    function test_Parity_observe_cardinality() public onlyFork {
        assertForkActive();

        // Grow observation capacity on both pools
        productionPool.increaseObservationCardinalityNext(8);
        localPool.increaseObservationCardinalityNext(8);

        // Write at least two observations separated in time (mint-in-range writes an observation).
        int24 tickLower = -400;
        int24 tickUpper = 400;

        vm.warp(block.timestamp + 10);
        callbackMint(productionPool, tickLower, tickUpper, TEST_LIQUIDITY);
        callbackMint(localPool, tickLower, tickUpper, TEST_LIQUIDITY);

        vm.warp(block.timestamp + 120);
        callbackMint(productionPool, tickLower, tickUpper, TEST_LIQUIDITY / 10);
        callbackMint(localPool, tickLower, tickUpper, TEST_LIQUIDITY / 10);

        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = 60;
        secondsAgos[1] = 0;

        (int56[] memory prodTicks, uint160[] memory prodSecs) = productionPool.observe(secondsAgos);
        (int56[] memory locTicks, uint160[] memory locSecs) = localPool.observe(secondsAgos);

        assertEq(locTicks.length, prodTicks.length, "tickCumulatives len");
        assertEq(locSecs.length, prodSecs.length, "secondsPerLiq len");
        for (uint256 i = 0; i < prodTicks.length; i++) {
            assertEq(locTicks[i], prodTicks[i], "tickCumulative parity");
            assertEq(locSecs[i], prodSecs[i], "secondsPerLiquidity parity");
        }
    }
}
