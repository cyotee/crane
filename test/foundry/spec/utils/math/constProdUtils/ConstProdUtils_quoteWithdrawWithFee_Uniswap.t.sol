// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_quoteWithdrawWithFee_Uniswap is TestBase_ConstProdUtils_Uniswap {
    uint256 constant TEST_LP_AMOUNT = 1000e18;

    function setUp() public override {
        TestBase_ConstProdUtils_Uniswap.setUp();
    }

    function test_quoteWithdrawWithFee_Uniswap_balanced_simple() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        // generate trading activity so protocol fee paths can run
        _executeUniswapTradesToGenerateFees(uniswapBalancedTokenA, uniswapBalancedTokenB);

        // Mint tokens and add small liquidity to obtain LP
        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        assertTrue(lpReceived > 0, "got lp");

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            16666,
            false
        );

        // Execute withdrawal
        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    function test_quoteWithdrawWithFee_Uniswap_unbalanced_simple() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        // generate trading activity so protocol fee paths can run
        _executeUniswapTradesToGenerateFees(uniswapUnbalancedTokenA, uniswapUnbalancedTokenB);

        // Mint tokens and add small liquidity to obtain LP
        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), pair.token0(), r0, r1);

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            16666,
            false
        );

        // Execute withdrawal
        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    function test_quoteWithdrawWithFee_Uniswap_extreme_unbalanced_simple() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        // generate trading activity so protocol fee paths can run
        _executeUniswapTradesToGenerateFees(uniswapExtremeTokenA, uniswapExtremeTokenB);

        // Mint tokens and add small liquidity to obtain LP
        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenA), pair.token0(), r0, r1);

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            16666,
            false
        );

        // Execute withdrawal
        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    // Additional Token-A extract tests (low percentage)
    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_lowPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        // Mint tokens and add small liquidity to obtain LP
        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        assertTrue(lpReceived > 0, "got lp");

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        // low percentage fee
        uint256 lowPercent = 5;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            lowPercent,
            false
        );

        // Execute withdrawal
        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_lowPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        // Mint tokens and add small liquidity to obtain LP
        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        assertTrue(lpReceived > 0, "got lp");

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        // low percentage fee
        uint256 lowPercent = 5;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            lowPercent,
            true
        );

        // Execute withdrawal
        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    // Medium and High percentage Token-A extract tests for all pools
    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_mediumPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        // Mint tokens and add small liquidity to obtain LP
        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            false
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    // Token-B extract tests (low/medium/high percentages × fees off/on) across pools
    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_lowPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenB), pair.token0(), r0, r1);

        uint256 lowPercent = 5;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            lowPercent,
            false
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_lowPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenB), pair.token0(), r0, r1);

        uint256 lowPercent = 5;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            lowPercent,
            true
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    // Medium and High percentage Token-B tests (balanced)
    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_mediumPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenB), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            false
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_mediumPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenB), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            true
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_highPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenB), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            false
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_highPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenB), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            true
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    // Unbalanced pool Token-B tests
    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_lowPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenB), pair.token0(), r0, r1);

        uint256 lowPercent = 5;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            lowPercent,
            false
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_lowPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenB), pair.token0(), r0, r1);

        uint256 lowPercent = 5;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            lowPercent,
            true
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_mediumPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenB), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            false
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_mediumPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenB), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            true
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_highPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenB), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            false
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_highPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenB), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            true
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    // Extreme pool Token-B tests
    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_lowPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenB), pair.token0(), r0, r1);

        uint256 lowPercent = 5;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            lowPercent,
            false
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_lowPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenB), pair.token0(), r0, r1);

        uint256 lowPercent = 5;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            lowPercent,
            true
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_mediumPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenB), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            false
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_mediumPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenB), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            true
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_highPercentage_feesDisabled_extractTokenB() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenB), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            false
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_highPercentage_feesEnabled_extractTokenB() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenB), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            true
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterB - beforeB, "quotedA == actualA");
        assertEq(quotedB, afterA - beforeA, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_mediumPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            true
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_highPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            false
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_balanced_highPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;

        uniswapBalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapBalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapBalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapBalancedTokenA), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            true
        );

        uint256 beforeA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapBalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapBalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapBalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    // Unbalanced pool variants
    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_mediumPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            false
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_mediumPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            true
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_highPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            false
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_unbalanced_highPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapUnbalancedPools();
        IUniswapV2Pair pair = uniswapUnbalancedPair;

        uniswapUnbalancedTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapUnbalancedTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapUnbalancedTokenA), address(uniswapUnbalancedTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            true
        );

        uint256 beforeA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapUnbalancedTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = uniswapUnbalancedTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    // Extreme unbalanced pool variants (medium & high)
    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_mediumPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenA), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            false
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_mediumPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenA), pair.token0(), r0, r1);

        uint256 mediumPercent = 50;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            mediumPercent,
            true
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_highPercentage_feesDisabled_extractTokenA() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenA), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            false
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }

    function test_quoteWithdrawSwapWithFee_Uniswap_extreme_highPercentage_feesEnabled_extractTokenA() public {
        _initializeUniswapExtremeUnbalancedPools();
        IUniswapV2Pair pair = uniswapExtremeUnbalancedPair;

        uniswapExtremeTokenA.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.mint(address(this), TEST_LP_AMOUNT);
        uniswapExtremeTokenA.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapExtremeTokenB.approve(address(uniswapV2Router), TEST_LP_AMOUNT);
        uniswapV2Router.addLiquidity(address(uniswapExtremeTokenA), address(uniswapExtremeTokenB), TEST_LP_AMOUNT, TEST_LP_AMOUNT, 1, 1, address(this), block.timestamp);

        uint256 lpReceived = pair.balanceOf(address(this));
        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(uniswapExtremeTokenA), pair.token0(), r0, r1);

        uint256 highPercent = 500;

        (uint256 quotedA, uint256 quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            pair.kLast(),
            highPercent,
            true
        );

        uint256 beforeA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = uniswapExtremeTokenB.balanceOf(address(this));
        pair.transfer(address(pair), lpReceived);
        pair.burn(address(this));
        uint256 afterA = uniswapExtremeTokenA.balanceOf(address(this));
        uint256 afterB = uniswapExtremeTokenB.balanceOf(address(this));

        assertEq(quotedA, afterA - beforeA, "quotedA == actualA");
        assertEq(quotedB, afterB - beforeB, "quotedB == actualB");
    }
}
