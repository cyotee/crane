// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {UniswapV2Utils} from "contracts/utils/math/UniswapV2Utils.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

contract ConstProdUtils_quoteWithdrawSwapWithFee_Uniswap is TestBase_ConstProdUtils_Uniswap {
    using ConstProdUtils for uint256;

    uint256 constant LOW_PERCENTAGE = 10;
    uint256 constant MEDIUM_PERCENTAGE = 50;
    uint256 constant HIGH_PERCENTAGE = 90;

    // Uniswap swap fee percent (0.3% expressed in same small-int units used by code path)
    uint256 constant UNISWAP_FEE_PERCENT = 300; // internal denom selection in ConstProdUtils

    function setUp() public override {
        super.setUp();
    }

    function _calculateLPAmount(uint256 totalLP, uint256 percentage) internal pure returns (uint256) {
        return (totalLP * percentage) / 100;
    }

    function _getPoolReserves(address pool)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB, address tokenA, address tokenB)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        (uint112 r0, uint112 r1,) = pair.getReserves();
        address token0 = pair.token0();
        address token1 = pair.token1();
        return (r0, r1, token0, token1);
    }

    // simple trading activity generator for Uniswap pairs to accrue fees
    function _generateTradingActivity(
        IUniswapV2Pair pair,
        address tokenA,
        address tokenB,
        uint256 swapPercentage // basis points of reserves (e.g., 100 = 1%)
    ) internal {
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();

        uint256 swapAmountA = (uint256(reserveA) * swapPercentage) / 10000;
        uint256 swapAmountB = (uint256(reserveB) * swapPercentage) / 10000;

        // allocate balances for trading
        deal(tokenA, address(this), swapAmountA, true);
        deal(tokenB, address(this), swapAmountB, true);

        IERC20(tokenA).approve(address(uniswapV2Router), swapAmountA);
        address[] memory pathAB = new address[](2);
        pathAB[0] = tokenA;
        pathAB[1] = tokenB;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            1,
            pathAB,
            address(this),
            block.timestamp
        );

        uint256 receivedB = IERC20(tokenB).balanceOf(address(this));
        IERC20(tokenB).approve(address(uniswapV2Router), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = tokenB;
        pathBA[1] = tokenA;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            receivedB,
            1,
            pathBA,
            address(this),
            block.timestamp
        );
    }

    function _setupUniswapFees(bool enable) internal {
        if (enable) {
            vm.prank(uniswapV2FeeToSetter);
            uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);
        } else {
            vm.prank(uniswapV2FeeToSetter);
            uniswapV2Factory.setFeeTo(address(0));
        }
    }

    function _performActualWithdrawSwap(address pool, uint256 lpAmount, address tokenA, address tokenB, uint256 /* feePercent */)
        internal
        returns (uint256 actualTokenAAmount)
    {
        IUniswapV2Pair pair = IUniswapV2Pair(pool);
        IUniswapV2Router router = IUniswapV2Router(address(uniswapV2Router));

        uint256 balABefore = IERC20(tokenA).balanceOf(address(this));
        uint256 balBBefore = IERC20(tokenB).balanceOf(address(this));

        pair.transfer(pool, lpAmount);
        (uint256 a0, uint256 a1) = pair.burn(address(this));

        address t0 = pair.token0();
        // map burn outputs to tokenA/tokenB ordering
        uint256 actualA = (tokenA == t0) ? a0 : a1;
        uint256 actualB = (tokenB == t0) ? a0 : a1;

        if (actualB > 0) {
            IERC20(tokenB).approve(address(router), actualB);
            address[] memory path = new address[](2);
            path[0] = tokenB;
            path[1] = tokenA;

            uint256 beforeA = IERC20(tokenA).balanceOf(address(this));
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualB,
                0,
                path,
                address(this),
                block.timestamp + 300
            );
            uint256 afterA = IERC20(tokenA).balanceOf(address(this));
            uint256 receivedA = afterA - beforeA;
            actualTokenAAmount = actualA + receivedA;
        } else {
            actualTokenAAmount = actualA;
        }
    }

    struct TestData {
        address pool;
        uint256 totalLP;
        uint256 lpAmount;
        uint256 reserveA;
        uint256 reserveB;
        address tokenA;
        address tokenB;
        uint256 kLast;
        uint256 ownerFeeShare;
        uint256 quote;
        uint256 actualAmount;
    }

    function _testWithdrawSwapWithFee(IUniswapV2Pair pair, uint256 percentage, bool feesEnabled) internal {
        TestData memory data;
        data.pool = address(pair);
        data.totalLP = pair.totalSupply();
        data.lpAmount = _calculateLPAmount(data.totalLP, percentage);

        (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(data.pool);
        data.kLast = pair.kLast();

        if (feesEnabled) {
            _setupUniswapFees(true);
            _generateTradingActivity(pair, data.tokenA, data.tokenB, 100);
            (data.reserveA, data.reserveB, data.tokenA, data.tokenB) = _getPoolReserves(data.pool);
            data.kLast = pair.kLast();
            data.totalLP = pair.totalSupply();
            (data.reserveA, data.reserveB) = ConstProdUtils._sortReserves(
                data.tokenA,
                pair.token0(),
                uint256(data.reserveA),
                uint256(data.reserveB)
            );
        } else {
            _setupUniswapFees(false);
        }

        uint256 ownerFeeShare = feesEnabled ? 16666 : 0;

        data.quote = UniswapV2Utils._quoteWithdrawSwapFee(
            data.lpAmount,
            data.totalLP,
            data.reserveA,
            data.reserveB,
            UNISWAP_FEE_PERCENT,
            0,
            data.kLast,
            feesEnabled
        );

        data.actualAmount = _performActualWithdrawSwap(data.pool, data.lpAmount, data.tokenA, data.tokenB, UNISWAP_FEE_PERCENT);

        assertEq(data.quote, data.actualAmount, "Quote should match actual execution");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        _testWithdrawSwapWithFee(uniswapBalancedPair, LOW_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        _testWithdrawSwapWithFee(uniswapBalancedPair, MEDIUM_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        _testWithdrawSwapWithFee(uniswapBalancedPair, HIGH_PERCENTAGE, false);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_lowPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        _testWithdrawSwapWithFee(uniswapBalancedPair, LOW_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_mediumPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        _testWithdrawSwapWithFee(uniswapBalancedPair, MEDIUM_PERCENTAGE, true);
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balancedPool_highPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        _testWithdrawSwapWithFee(uniswapBalancedPair, HIGH_PERCENTAGE, true);
    }
    
    function test_withdrawSwapQuote_Uniswap_balancedPool() public {
        _initializeUniswapBalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );
        // Sanity: ensure reserveA corresponds to uniswapBalancedTokenA
        if (uniswapBalancedPair.token0() == address(uniswapBalancedTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = UniswapV2Utils._quoteWithdrawSwapFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300, 0, 0, false
        );

        // Execute actual withdraw + swap
        uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

        uniswapBalancedPair.transfer(address(uniswapBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

        uint256 actualAmountA = amountA;
        uint256 actualAmountB = amountB;

        if (actualAmountB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapBalancedTokenB);
            path[1] = address(uniswapBalancedTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_Uniswap_unbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );
        // Sanity: ensure reserveA corresponds to uniswapUnbalancedTokenA
        if (uniswapUnbalancedPair.token0() == address(uniswapUnbalancedTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

        uint256 lpBalance = uniswapUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = UniswapV2Utils._quoteWithdrawSwapFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300, 0, 0, false
        );

        uint256 initialTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));

        uniswapUnbalancedPair.transfer(address(uniswapUnbalancedPair), ownedLPAmount);
        (uint256 amount0, uint256 amount1) = uniswapUnbalancedPair.burn(address(this));

        uint256 actualAmountA;
        uint256 actualAmountB;
        if (uniswapUnbalancedPair.token0() == address(uniswapUnbalancedTokenA)) {
            actualAmountA = amount0;
            actualAmountB = amount1;
        } else {
            actualAmountA = amount1;
            actualAmountB = amount0;
        }

        if (actualAmountB > 0) {
            uniswapUnbalancedTokenB.approve(address(uniswapV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapUnbalancedTokenB);
            path[1] = address(uniswapUnbalancedTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    function test_withdrawSwapQuote_Uniswap_extremeUnbalancedPool() public {
        _initializeUniswapExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA),
            uniswapExtremeUnbalancedPair.token0(),
            reserve0,
            reserve1
        );
        // Sanity: ensure reserveA corresponds to uniswapExtremeTokenA
        if (uniswapExtremeUnbalancedPair.token0() == address(uniswapExtremeTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }
        uint256 lpTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        uint256 lpBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = UniswapV2Utils._quoteWithdrawSwapFee(
            ownedLPAmount, lpTotalSupply, reserveA, reserveB, 300, 0, 0, false
        );

        uint256 initialTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));


        uniswapExtremeUnbalancedPair.transfer(address(uniswapExtremeUnbalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = uniswapExtremeUnbalancedPair.burn(address(this));


        uint256 actualAmountA;
        uint256 actualAmountB;
        if (uniswapExtremeUnbalancedPair.token0() == address(uniswapExtremeTokenA)) {
            actualAmountA = amountA;
            actualAmountB = amountB;
        } else {
            actualAmountA = amountB;
            actualAmountB = amountA;
        }


        if (actualAmountB > 0) {
            uniswapExtremeTokenB.approve(address(uniswapV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapExtremeTokenB);
            path[1] = address(uniswapExtremeTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Should receive exactly the expected total TokenA amount");
    }

    // Fees-enabled variants: ensure protocol fee minting is handled by the quote
    function test_withdrawSwapQuote_Uniswap_balancedPool_feesEnabled() public {
        vm.prank(uniswapV2FeeToSetter);
        uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);
        _initializeUniswapBalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
        );
        // Sanity: ensure reserveA corresponds to uniswapBalancedTokenA (fees-enabled)
        if (uniswapBalancedPair.token0() == address(uniswapBalancedTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }
        uint256 lpTotalSupply = uniswapBalancedPair.totalSupply();

        uint256 lpBalance = uniswapBalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = UniswapV2Utils._quoteWithdrawSwapFee(
            ownedLPAmount,
            lpTotalSupply,
            reserveA,
            reserveB,
            300,
            1000,
            uniswapBalancedPair.kLast(),
            true
        );

        uint256 initialTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));

        uniswapBalancedPair.transfer(address(uniswapBalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = uniswapBalancedPair.burn(address(this));

        if (amountB > 0) {
            uniswapBalancedTokenB.approve(address(uniswapV2Router), amountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapBalancedTokenB);
            path[1] = address(uniswapBalancedTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Fees-enabled: Should receive exactly expected TokenA amount");
    }

    function test_withdrawSwapQuote_Uniswap_unbalancedPool_feesEnabled() public {
        vm.prank(uniswapV2FeeToSetter);
        uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);
        _initializeUniswapUnbalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapUnbalancedTokenA), uniswapUnbalancedPair.token0(), reserve0, reserve1
        );
        // Sanity: ensure reserveA corresponds to uniswapUnbalancedTokenA (fees-enabled)
        if (uniswapUnbalancedPair.token0() == address(uniswapUnbalancedTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }
        uint256 lpTotalSupply = uniswapUnbalancedPair.totalSupply();

        uint256 lpBalance = uniswapUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = UniswapV2Utils._quoteWithdrawSwapFee(
            ownedLPAmount,
            lpTotalSupply,
            reserveA,
            reserveB,
            300,
            1000,
            uniswapUnbalancedPair.kLast(),
            true
        );

        uint256 initialTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));

        uniswapUnbalancedPair.transfer(address(uniswapUnbalancedPair), ownedLPAmount);
        (uint256 amount0, uint256 amount1) = uniswapUnbalancedPair.burn(address(this));

        uint256 actualAmountA;
        uint256 actualAmountB;
        if (uniswapUnbalancedPair.token0() == address(uniswapUnbalancedTokenA)) {
            actualAmountA = amount0;
            actualAmountB = amount1;
        } else {
            actualAmountA = amount1;
            actualAmountB = amount0;
        }

        if (actualAmountB > 0) {
            uniswapUnbalancedTokenB.approve(address(uniswapV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapUnbalancedTokenB);
            path[1] = address(uniswapUnbalancedTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;

        assertEq(actualTotalTokenA, expectedTotalTokenA, "Fees-enabled: Should receive exactly expected TokenA amount");
    }

    function test_withdrawSwapQuote_Uniswap_extremeUnbalancedPool_feesEnabled() public {
        vm.prank(uniswapV2FeeToSetter);
        uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);
        _initializeUniswapExtremeUnbalancedPools();
        (uint112 reserve0, uint112 reserve1,) = uniswapExtremeUnbalancedPair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(uniswapExtremeTokenA),
            uniswapExtremeUnbalancedPair.token0(),
            reserve0,
            reserve1
        );
        // Sanity: ensure reserveA corresponds to uniswapExtremeTokenA (fees-enabled)
        if (uniswapExtremeUnbalancedPair.token0() == address(uniswapExtremeTokenA)) {
            assertEq(reserveA, uint256(reserve0));
        } else {
            assertEq(reserveA, uint256(reserve1));
        }
        uint256 lpTotalSupply = uniswapExtremeUnbalancedPair.totalSupply();

        uint256 lpBalance = uniswapExtremeUnbalancedPair.balanceOf(address(this));
        uint256 ownedLPAmount = lpBalance / 2;

        uint256 expectedTotalTokenA = UniswapV2Utils._quoteWithdrawSwapFee(
            ownedLPAmount,
            lpTotalSupply,
            reserveA,
            reserveB,
            300,
            1000,
            uniswapExtremeUnbalancedPair.kLast(),
            true
        );

        uint256 initialTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));


        uniswapExtremeUnbalancedPair.transfer(address(uniswapExtremeUnbalancedPair), ownedLPAmount);
        (uint256 amountA, uint256 amountB) = uniswapExtremeUnbalancedPair.burn(address(this));


        uint256 actualAmountA;
        uint256 actualAmountB;
        if (uniswapExtremeUnbalancedPair.token0() == address(uniswapExtremeTokenA)) {
            actualAmountA = amountA;
            actualAmountB = amountB;
        } else {
            actualAmountA = amountB;
            actualAmountB = amountA;
        }


        if (actualAmountB > 0) {
            uniswapExtremeTokenB.approve(address(uniswapV2Router), actualAmountB);
            address[] memory path = new address[](2);
            path[0] = address(uniswapExtremeTokenB);
            path[1] = address(uniswapExtremeTokenA);

            uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                actualAmountB, 1, path, address(this), block.timestamp
            );
        }

        uint256 finalTokenABalance = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 actualTotalTokenA = finalTokenABalance - initialTokenABalance;


        assertEq(actualTotalTokenA, expectedTotalTokenA, "Fees-enabled: Should receive exactly expected TokenA amount");
    }
}
