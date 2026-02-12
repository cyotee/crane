// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniswapV3Utils} from "@crane/contracts/utils/math/UniswapV3Utils.sol";
import {IUniswapV3Pool} from "@crane/contracts/protocols/dexes/uniswap/v3/interfaces/IUniswapV3Pool.sol";
import {TestBase_UniswapV3} from "@crane/contracts/protocols/dexes/uniswap/v3/test/bases/TestBase_UniswapV3.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";

/// @title Test UniswapV3Utils._quoteExactInputSingle
/// @notice Validates exact input swap quotes against actual V3 pool execution
contract UniswapV3Utils_quoteExactInput_Test is TestBase_UniswapV3 {
    using UniswapV3Utils for *;

    IUniswapV3Pool pool;
    address tokenA;
    address tokenB;

    uint256 constant INITIAL_LIQUIDITY = 1_000e18;
    uint256 constant TEST_AMOUNT = 1e18;

    function setUp() public override {
        super.setUp();

        // Create test tokens
        tokenA = address(new MockERC20("Token A", "TKNA", 18));
        tokenB = address(new MockERC20("Token B", "TKNB", 18));

        vm.label(tokenA, "TokenA");
        vm.label(tokenB, "TokenB");

        // Create pool with 0.3% fee at 1:1 price
        pool = createPoolOneToOne(tokenA, tokenB, FEE_MEDIUM);

        // Add liquidity in wide range around current tick
        int24 tickSpacing = getTickSpacing(FEE_MEDIUM);
        int24 tickLower = nearestUsableTick(-60000, tickSpacing);  // Wide range
        int24 tickUpper = nearestUsableTick(60000, tickSpacing);

        mintPosition(pool, address(this), tickLower, tickUpper, uint128(INITIAL_LIQUIDITY));
    }

    /* -------------------------------------------------------------------------- */
    /*                          Quote vs Actual Swap Tests                        */
    /* -------------------------------------------------------------------------- */

    /// @notice Test exact input quote matches actual swap (token0 -> token1)
    function test_quoteExactInput_zeroForOne_matchesActualSwap() public {
        uint256 amountIn = TEST_AMOUNT;

        // Get current pool state
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Get quote from UniswapV3Utils
        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true  // token0 -> token1
        );

        // Execute actual swap
        uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));

        // Quote should match actual within rounding tolerance (±1 wei)
        assertApproxEqAbs(quotedOut, actualOut, 1, "Quote mismatch for zeroForOne");
    }

    /// @notice Test exact input quote matches actual swap (token1 -> token0)
    function test_quoteExactInput_oneForZero_matchesActualSwap() public {
        uint256 amountIn = TEST_AMOUNT;

        // Get current pool state
        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Get quote from UniswapV3Utils
        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            false  // token1 -> token0
        );

        // Execute actual swap
        uint256 actualOut = swapExactInput(pool, false, amountIn, address(this));

        // Quote should match actual within rounding tolerance
        assertApproxEqAbs(quotedOut, actualOut, 1, "Quote mismatch for oneForZero");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Tick Overload Tests                             */
    /* -------------------------------------------------------------------------- */

    /// @notice Test tick overload produces same result as sqrtPrice version
    function test_quoteExactInput_tickOverload_matchesSqrtPriceVersion() public {
        uint256 amountIn = TEST_AMOUNT;

        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        // Quote using sqrtPriceX96
        uint256 quotedWithSqrtPrice = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        // Quote using tick
        uint256 quotedWithTick = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            tick,
            liquidity,
            FEE_MEDIUM,
            true
        );

        // Should be identical
        assertEq(quotedWithSqrtPrice, quotedWithTick, "Tick overload mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Fee Tier Tests                                  */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote correctness across different fee tiers
    function test_quoteExactInput_differentFeeTiers() public {
        uint256 amountIn = TEST_AMOUNT;

        // Test each standard fee tier
        uint24[3] memory feeTiers = [FEE_LOW, FEE_MEDIUM, FEE_HIGH];

        for (uint256 i = 0; i < feeTiers.length; i++) {
            uint24 fee = feeTiers[i];

            // Create pool for this fee tier
            IUniswapV3Pool testPool = createPoolOneToOne(
                address(new MockERC20("A", "A", 18)),
                address(new MockERC20("B", "B", 18)),
                fee
            );

            // Add liquidity
            int24 tickSpacing = getTickSpacing(fee);
            mintPosition(
                testPool,
                address(this),
                nearestUsableTick(-60000, tickSpacing),
                nearestUsableTick(60000, tickSpacing),
                uint128(INITIAL_LIQUIDITY)
            );

            // Get quote
            (uint160 sqrtPriceX96, , , , , , ) = testPool.slot0();
            uint128 liquidity = testPool.liquidity();

            uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
                amountIn,
                sqrtPriceX96,
                liquidity,
                fee,
                true
            );

            // Execute actual swap
            uint256 actualOut = swapExactInput(testPool, true, amountIn, address(this));

            // Validate
            assertApproxEqAbs(quotedOut, actualOut, 1, string(abi.encodePacked("Fee tier ", vm.toString(fee))));
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                            Amount Variation Tests                          */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quotes for various swap amounts
    /// @dev _quoteExactInputSingle is a single-tick quote function, so amounts must stay
    ///      within the current tick. For amounts that might cross ticks, use UniswapV3Quoter.
    function test_quoteExactInput_variousAmounts() public {
        // Test amounts relative to liquidity - keep small to stay within single tick
        // With 1000e18 liquidity, amounts up to ~1-5% of liquidity stay in tick
        uint256[4] memory amounts;
        amounts[0] = 1e18;       // Tiny: 0.1% of liquidity
        amounts[1] = 5e18;       // Small: 0.5% of liquidity
        amounts[2] = 10e18;      // Medium: 1% of liquidity
        amounts[3] = 50e18;      // Larger but still within single tick: 5% of liquidity

        for (uint256 i = 0; i < amounts.length; i++) {
            uint256 amountIn = amounts[i];

            // Get current pool state (fresh for each swap to ensure accuracy)
            (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
            uint128 liquidity = pool.liquidity();

            // Get quote
            uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
                amountIn,
                sqrtPriceX96,
                liquidity,
                FEE_MEDIUM,
                true
            );

            // Execute actual swap (reset pool state after each)
            uint256 snapshotId = vm.snapshot();
            uint256 actualOut = swapExactInput(pool, true, amountIn, address(this));
            vm.revertTo(snapshotId);

            // Validate - single tick quote should match within 1 wei for small amounts
            assertApproxEqAbs(
                quotedOut,
                actualOut,
                1,
                string(abi.encodePacked("Amount ", vm.toString(amountIn)))
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                              Edge Cases                                    */
    /* -------------------------------------------------------------------------- */

    /// @notice Test quote with dust amount (1 wei)
    function test_quoteExactInput_dustAmount() public {
        uint256 amountIn = 1;  // 1 wei

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            amountIn,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        // For such a small amount, output might be 0 due to fees
        // Just verify it doesn't revert and returns a sensible value
        assertTrue(quotedOut <= amountIn, "Output should not exceed input for 1 wei");
    }

    /// @notice Test quote with zero amount returns zero
    function test_quoteExactInput_zeroAmount() public {
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint128 liquidity = pool.liquidity();

        uint256 quotedOut = UniswapV3Utils._quoteExactInputSingle(
            0,
            sqrtPriceX96,
            liquidity,
            FEE_MEDIUM,
            true
        );

        assertEq(quotedOut, 0, "Zero input should give zero output");
    }
}

/// @notice Mock ERC20 for testing
contract MockERC20 is IERC20PermitProxy {
    // Put mappings first to make Foundry's `deal(token, ...)` more likely to locate and update balances.
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function permit(address, address, uint256, uint256, uint8, bytes32, bytes32) external pure {
        revert("Not implemented");
    }

    function nonces(address) external pure returns (uint256) {
        return 0;
    }

    function DOMAIN_SEPARATOR() external pure returns (bytes32) {
        return bytes32(0);
    }

    function eip712Domain()
        external
        view
        returns (
            bytes1 fields,
            string memory name_,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            bytes1(0x0f),
            name,
            "1",
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}
