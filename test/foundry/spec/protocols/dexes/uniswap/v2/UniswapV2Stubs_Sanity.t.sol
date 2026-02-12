// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {UniV2Factory} from "@crane/contracts/protocols/dexes/uniswap/v2/stubs/UniV2Factory.sol";
import {UniV2Router02} from "@crane/contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02.sol";
import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";

/// @title UniswapV2Stubs_Sanity
/// @notice Local (non-fork) tests for UniV2Factory and UniV2Router02 stubs
/// @dev Validates that local stubs behave like Uniswap V2 for primitives we depend on
contract UniswapV2Stubs_Sanity is Test {

    /* -------------------------------------------------------------------------- */
    /*                              Test Infrastructure                           */
    /* -------------------------------------------------------------------------- */

    UniV2Factory internal factory;
    UniV2Router02 internal router;
    WETH9 internal weth;

    // Test tokens (18 decimals)
    ERC20PermitMintableStub internal tokenA18;
    ERC20PermitMintableStub internal tokenB18;

    // Test tokens (18/6 decimals)
    ERC20PermitMintableStub internal tokenA18_2;
    ERC20PermitMintableStub internal tokenB6;

    /// @dev Uniswap V2 fee: 0.3% = 3/1000 = 300/100000
    uint256 internal constant UNISWAP_V2_FEE_PERCENT = 300;
    uint256 internal constant UNISWAP_V2_FEE_DENOMINATOR = 100_000;

    /// @dev Initial liquidity amounts
    uint256 internal constant INITIAL_LIQ_A = 100 ether;
    uint256 internal constant INITIAL_LIQ_B = 100 ether;

    function setUp() public {
        // Deploy WETH
        weth = new WETH9();
        vm.label(address(weth), "WETH");

        // Deploy factory and router
        factory = new UniV2Factory(address(this));
        router = new UniV2Router02(address(factory), address(weth));

        vm.label(address(factory), "UniV2Factory");
        vm.label(address(router), "UniV2Router02");

        // Deploy 18/18 decimal tokens
        tokenA18 = new ERC20PermitMintableStub("Token A 18", "TKA18", 18, address(this), 0);
        tokenB18 = new ERC20PermitMintableStub("Token B 18", "TKB18", 18, address(this), 0);

        vm.label(address(tokenA18), "TokenA18");
        vm.label(address(tokenB18), "TokenB18");

        // Deploy 18/6 decimal tokens
        tokenA18_2 = new ERC20PermitMintableStub("Token A 18v2", "TKA182", 18, address(this), 0);
        tokenB6 = new ERC20PermitMintableStub("Token B 6", "TKB6", 6, address(this), 0);

        vm.label(address(tokenA18_2), "TokenA18v2");
        vm.label(address(tokenB6), "TokenB6");
    }

    /* -------------------------------------------------------------------------- */
    /*                  US-CRANE-202.3: Stub Sanity (Local) Tests                 */
    /* -------------------------------------------------------------------------- */

    /// @notice Test 18/18 decimal tokens: swap output equals ConstProdUtils quote
    function test_stub18_18_swapOutputMatchesConstProdQuote() public {
        // Create pair and seed liquidity
        _seedLiquidity18_18();

        address pairAddress = factory.getPair(address(tokenA18), address(tokenB18));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Get reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = pair.token0() == address(tokenA18)
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));

        // Test amount: 1 ether
        uint256 amountIn = 1 ether;

        // Get quote from ConstProdUtils
        uint256 expectedOut = ConstProdUtils._saleQuote(
            amountIn,
            reserveA,
            reserveB,
            UNISWAP_V2_FEE_PERCENT,
            UNISWAP_V2_FEE_DENOMINATOR
        );

        // Execute swap via router
        uint256 actualOut = _executeSwap(address(tokenA18), address(tokenB18), amountIn);

        // Assert exact match
        assertEq(
            expectedOut,
            actualOut,
            "18/18 decimals: Swap output should equal ConstProdUtils quote"
        );
    }

    /// @notice Test 18/6 decimal tokens: swap output equals ConstProdUtils quote
    function test_stub18_6_swapOutputMatchesConstProdQuote() public {
        // Create pair and seed liquidity
        _seedLiquidity18_6();

        address pairAddress = factory.getPair(address(tokenA18_2), address(tokenB6));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Get reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = pair.token0() == address(tokenA18_2)
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));

        // Test amount: 1 ether of 18-decimal token
        uint256 amountIn = 1 ether;

        // Get quote from ConstProdUtils
        uint256 expectedOut = ConstProdUtils._saleQuote(
            amountIn,
            reserveA,
            reserveB,
            UNISWAP_V2_FEE_PERCENT,
            UNISWAP_V2_FEE_DENOMINATOR
        );

        // Execute swap via router
        uint256 actualOut = _executeSwap(address(tokenA18_2), address(tokenB6), amountIn);

        // Assert exact match
        assertEq(
            expectedOut,
            actualOut,
            "18/6 decimals: Swap output should equal ConstProdUtils quote"
        );
    }

    /// @notice Test 18/18 reverse direction: swap output equals ConstProdUtils quote
    function test_stub18_18_reverseSwapOutputMatchesConstProdQuote() public {
        // Create pair and seed liquidity
        _seedLiquidity18_18();

        address pairAddress = factory.getPair(address(tokenA18), address(tokenB18));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Get reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = pair.token0() == address(tokenA18)
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));

        // Test amount: swap B -> A
        uint256 amountIn = 1 ether;

        // Get quote from ConstProdUtils (reversed: B in, A out)
        uint256 expectedOut = ConstProdUtils._saleQuote(
            amountIn,
            reserveB,  // in reserve
            reserveA,  // out reserve
            UNISWAP_V2_FEE_PERCENT,
            UNISWAP_V2_FEE_DENOMINATOR
        );

        // Execute swap via router (B -> A)
        uint256 actualOut = _executeSwap(address(tokenB18), address(tokenA18), amountIn);

        // Assert exact match
        assertEq(
            expectedOut,
            actualOut,
            "18/18 decimals reverse: Swap output should equal ConstProdUtils quote"
        );
    }

    /// @notice Test 18/6 reverse direction: swap output equals ConstProdUtils quote
    function test_stub18_6_reverseSwapOutputMatchesConstProdQuote() public {
        // Create pair and seed liquidity
        _seedLiquidity18_6();

        address pairAddress = factory.getPair(address(tokenA18_2), address(tokenB6));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Get reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = pair.token0() == address(tokenA18_2)
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));

        // Test amount: swap B (6 decimals) -> A (18 decimals)
        uint256 amountIn = 100 * 1e6; // 100 tokens with 6 decimals

        // Get quote from ConstProdUtils (reversed: B in, A out)
        uint256 expectedOut = ConstProdUtils._saleQuote(
            amountIn,
            reserveB,  // in reserve
            reserveA,  // out reserve
            UNISWAP_V2_FEE_PERCENT,
            UNISWAP_V2_FEE_DENOMINATOR
        );

        // Execute swap via router (B6 -> A18)
        uint256 actualOut = _executeSwap(address(tokenB6), address(tokenA18_2), amountIn);

        // Assert exact match
        assertEq(
            expectedOut,
            actualOut,
            "18/6 decimals reverse: Swap output should equal ConstProdUtils quote"
        );
    }

    /// @notice Test router getAmountsOut matches ConstProdUtils quote
    function test_stubRouterGetAmountsOutMatchesConstProdQuote() public {
        _seedLiquidity18_18();

        address pairAddress = factory.getPair(address(tokenA18), address(tokenB18));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Get reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = pair.token0() == address(tokenA18)
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));

        uint256 amountIn = 1 ether;

        // Get quote from router
        address[] memory path = new address[](2);
        path[0] = address(tokenA18);
        path[1] = address(tokenB18);
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        uint256 routerQuote = amounts[1];

        // Get quote from ConstProdUtils
        uint256 constProdQuote = ConstProdUtils._saleQuote(
            amountIn,
            reserveA,
            reserveB,
            UNISWAP_V2_FEE_PERCENT,
            UNISWAP_V2_FEE_DENOMINATOR
        );

        assertEq(
            routerQuote,
            constProdQuote,
            "Router getAmountsOut should match ConstProdUtils quote"
        );
    }

    /// @notice Test router getAmountsIn matches ConstProdUtils quote
    function test_stubRouterGetAmountsInMatchesConstProdQuote() public {
        _seedLiquidity18_18();

        address pairAddress = factory.getPair(address(tokenA18), address(tokenB18));
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);

        // Get reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = pair.token0() == address(tokenA18)
            ? (uint256(reserve0), uint256(reserve1))
            : (uint256(reserve1), uint256(reserve0));

        uint256 amountOut = 1 ether;

        // Get quote from router
        address[] memory path = new address[](2);
        path[0] = address(tokenA18);
        path[1] = address(tokenB18);
        uint256[] memory amounts = router.getAmountsIn(amountOut, path);
        uint256 routerQuote = amounts[0];

        // Get quote from ConstProdUtils
        uint256 constProdQuote = ConstProdUtils._purchaseQuote(
            amountOut,
            reserveA,
            reserveB,
            UNISWAP_V2_FEE_PERCENT,
            UNISWAP_V2_FEE_DENOMINATOR
        );

        // Should match within 1 wei (rounding)
        assertApproxEqAbs(
            routerQuote,
            constProdQuote,
            1,
            "Router getAmountsIn should match ConstProdUtils quote"
        );
    }

    /// @notice Test pair creation succeeds
    function test_stubPairCreation() public {
        // Create pair
        address pairAddress = factory.createPair(address(tokenA18), address(tokenB18));

        // Verify pair exists
        assertTrue(pairAddress != address(0), "Pair should be created");
        assertEq(
            factory.getPair(address(tokenA18), address(tokenB18)),
            pairAddress,
            "Factory should return pair address"
        );
        assertEq(
            factory.getPair(address(tokenB18), address(tokenA18)),
            pairAddress,
            "Factory should return same pair for reversed tokens"
        );
    }

    /// @notice Test liquidity provision works
    function test_stubLiquidityProvision() public {
        // Mint tokens
        tokenA18.mint(address(this), 100 ether);
        tokenB18.mint(address(this), 100 ether);

        // Approve router
        tokenA18.approve(address(router), 100 ether);
        tokenB18.approve(address(router), 100 ether);

        // Add liquidity
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA18),
            address(tokenB18),
            100 ether,
            100 ether,
            0,
            0,
            address(this),
            block.timestamp + 1
        );

        assertTrue(amountA > 0, "Should use some tokenA");
        assertTrue(amountB > 0, "Should use some tokenB");
        assertTrue(liquidity > 0, "Should mint LP tokens");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Helper Functions                              */
    /* -------------------------------------------------------------------------- */

    function _seedLiquidity18_18() internal {
        // Mint tokens
        tokenA18.mint(address(this), INITIAL_LIQ_A);
        tokenB18.mint(address(this), INITIAL_LIQ_B);

        // Approve router
        tokenA18.approve(address(router), INITIAL_LIQ_A);
        tokenB18.approve(address(router), INITIAL_LIQ_B);

        // Add liquidity (creates pair if needed)
        router.addLiquidity(
            address(tokenA18),
            address(tokenB18),
            INITIAL_LIQ_A,
            INITIAL_LIQ_B,
            0,
            0,
            address(this),
            block.timestamp + 1
        );
    }

    function _seedLiquidity18_6() internal {
        // For 18/6 decimals, scale B appropriately
        uint256 liqA = INITIAL_LIQ_A;       // 100 ether (18 decimals)
        uint256 liqB = 100 * 1e6;           // 100 units (6 decimals)

        // Mint tokens
        tokenA18_2.mint(address(this), liqA);
        tokenB6.mint(address(this), liqB);

        // Approve router
        tokenA18_2.approve(address(router), liqA);
        tokenB6.approve(address(router), liqB);

        // Add liquidity
        router.addLiquidity(
            address(tokenA18_2),
            address(tokenB6),
            liqA,
            liqB,
            0,
            0,
            address(this),
            block.timestamp + 1
        );
    }

    function _executeSwap(address tokenIn, address tokenOut, uint256 amountIn)
        internal
        returns (uint256 amountOut)
    {
        // Mint tokens to swap
        ERC20PermitMintableStub(tokenIn).mint(address(this), amountIn);

        // Approve router
        IERC20PermitProxy(tokenIn).approve(address(router), amountIn);

        // Build path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Execute swap
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            0, // Accept any output
            path,
            address(this),
            block.timestamp + 1
        );

        amountOut = amounts[1];
    }
}
