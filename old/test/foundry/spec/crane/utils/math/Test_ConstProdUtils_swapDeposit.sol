// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
// import {Test} from "forge-std/Test.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title ConstProdUtils_swapDepositTest
 * @dev Tests ConstProdUtils swap+deposit calculations against actual DEX operations
 */
// contract Test_ConstProdUtils_swapDeposit is TestBase_ConstProdUtils {

//     function setUp() public override {
//         super.setUp();
//     }

//     function run() public override {
//         // super.run();
//         // _initializePools();
//     }

//     function test_swapDepositQuote_camelot() public {
//         uint256 amountIn = 2000e18;

//         // Get current reserves and fee
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
//         (uint256 reserveIn, uint256 feePercent, uint256 reserveOut, uint256 tokenBFee) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
//         );
//         uint256 totalSupply = camelotBalancedPair.totalSupply();

//         // Calculate expected LP tokens using ConstProdUtils
//         /// forge-lint: disable-next-line(mixed-case-variable)
//         uint256 expectedLPTokens = ConstProdUtils._swapDepositQuote(
//             totalSupply,
//             amountIn,
//             reserveIn,
//             reserveOut,
//             feePercent
//         );

//         // Mint tokens and perform actual swap+deposit
//         camelotBalancedTokenA.mint(address(this), amountIn);

//         // uint256 initialLPBalance = camelotBalancedPair.balanceOf(address(this));

//         // Execute actual swap+deposit on Camelot
//         /// forge-lint: disable-next-line(mixed-case-variable)
//         uint256 actualLPTokens = CamelotV2Service._swapDeposit(
//             camV2Router(),
//             camelotBalancedPair,
//             camelotBalancedTokenA,
//             amountIn,
//             camelotBalancedTokenB,
//             address(0) // referrer
//         );

//         // uint256 finalLPBalance = camelotBalancedPair.balanceOf(address(this));
//         // uint256 receivedLP = finalLPBalance - initialLPBalance;

//         // Verify our calculation was correct (within small tolerance)
//         uint256 tolerance = expectedLPTokens / 1000; // 0.1% tolerance
//         uint256 diff = actualLPTokens > expectedLPTokens ?
//             actualLPTokens - expectedLPTokens :
//             expectedLPTokens - actualLPTokens;

//         assert(diff <= tolerance);
//     }

//     function test_swapDepositQuote_uniswap() public {
//         uint256 amountIn = 1000e18;

//         // Get current reserves
//         (uint112 reserve0, uint112 reserve1,) = uniswapBalancedPair.getReserves();
//         (uint256 reserveIn, uint256 reserveOut) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA), uniswapBalancedPair.token0(), reserve0, reserve1
//         );
//         uint256 totalSupply = uniswapBalancedPair.totalSupply();
//         uint256 feePercent = 300; // 0.3% for Uniswap

//         // Calculate expected LP tokens using ConstProdUtils
//         /// forge-lint: disable-next-line(mixed-case-variable)
//         uint256 expectedLPTokens = ConstProdUtils._swapDepositQuote(
//             totalSupply,
//             amountIn,
//             reserveIn,
//             reserveOut,
//             feePercent
//         );

//         // Mint tokens for actual swap+deposit
//         uniswapBalancedTokenA.mint(address(this), amountIn);

//         // Execute actual swap+deposit on Uniswap
//         /// forge-lint: disable-next-line(mixed-case-variable)
//         uint256 actualLPTokens = UniswapV2Service._swapDeposit(
//             IUniswapV2Router(address(uniswapV2Router())),
//             uniswapBalancedPair,
//             uniswapBalancedTokenA,
//             amountIn,
//             uniswapBalancedTokenB
//         );

//         // Verify our calculation was correct (within small tolerance)
//         uint256 tolerance = expectedLPTokens / 1000; // 0.1% tolerance
//         uint256 diff = actualLPTokens > expectedLPTokens ?
//             actualLPTokens - expectedLPTokens :
//             expectedLPTokens - actualLPTokens;

//         assert(diff <= tolerance);
//     }

//     function test_swapDepositSaleAmt() public pure {
//         // uint256 saleAmt = 2000e18;
//         uint256 saleReserve = 50000e18;
//         uint256 feePercent = 300;

//         // Test different sale amounts
//         uint256[] memory amounts = new uint256[](5);
//         amounts[0] = 100e18;
//         amounts[1] = 500e18;
//         amounts[2] = 1000e18;
//         amounts[3] = 2000e18;
//         amounts[4] = 5000e18;

//         console.log("Testing swap deposit sale amounts:");

//         for (uint i = 0; i < amounts.length; i++) {
//             uint256 swapAmount = ConstProdUtils._swapDepositSaleAmt(
//                 amounts[i],
//                 saleReserve,
//                 feePercent
//             );

//             // Verify swap amount is reasonable (should be < sale amount)
//             assert(swapAmount < amounts[i]);
//             assert(swapAmount > 0);

//             console.log("  Sale amount:     ", amounts[i]);
//             console.log("  Swap amount:     ", swapAmount);
//         }
//     }

//     function test_swapDepositQuote_differentAmounts() public view {
//         uint256[] memory amounts = new uint256[](4);
//         amounts[0] = 500e18;
//         amounts[1] = 1000e18;
//         amounts[2] = 2000e18;
//         amounts[3] = 5000e18;

//         (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
//         uint256 totalSupply = camelotBalancedPair.totalSupply();

//         (
//             uint256 reserveIn,
//             uint256 feePercentIn,
//             uint256 reserveOut,
//             // uint256 feePercentOut
//         ) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA),
//             camelotBalancedPair.token0(),
//             uint256(reserveA),
//             uint256(feeA),
//             uint256(reserveB),
//             uint256(feeB)
//         );

//         console.log("Testing different swap+deposit amounts:");

//         for (uint i = 0; i < amounts.length; i++) {
//         /// forge-lint: disable-next-line(mixed-case-variable)
//             uint256 expectedLP = ConstProdUtils._swapDepositQuote(
//                 totalSupply,
//                 amounts[i],
//                 reserveIn,
//                 reserveOut,
//                 feePercentIn
//             );

//             // Verify LP output is reasonable
//             assert(expectedLP > 0);

//             console.log("  Amount in:       ", amounts[i]);
//             console.log("  LP out:          ", expectedLP);
//         }
//     }

//     function test_equivLiquidity_helper() public pure{
//         // Test the _equivLiquidity helper function
//         uint256 amountA = 1000e18;
//         uint256 reserveA = 10000e18;
//         uint256 reserveB = 20000e18;

//         uint256 equivalentB = ConstProdUtils._equivLiquidity(amountA, reserveA, reserveB);

//         // Expected: (1000 * 20000) / 10000 = 2000
//         assert(equivalentB == 2000e18);

//         console.log("Equivalent liquidity test passed:");
//         console.log("  Amount A:        ", amountA);
//         console.log("  Reserve A:       ", reserveA);
//         console.log("  Reserve B:       ", reserveB);
//         console.log("  Equivalent B:    ", equivalentB);
//     }

//     function test_swapDepositToTargetQuote() public {
//         uint256 lpAmountDesired = 1000e18;

//         // Get current reserves and total supply
//         (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();

//         (
//             uint256 reserveIn,
//             uint256 feePercentIn,
//             uint256 reserveOut,
//             // uint256 feePercentOut
//         ) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA),
//             camelotBalancedPair.token0(),
//             uint256(reserveA),
//             uint256(feeA),
//             uint256(reserveB),
//             uint256(feeB)
//         );

//         uint256 totalSupply = camelotBalancedPair.totalSupply();

//         console.log("Debug values:");
//         console.log("  camelotBalancedTokenA:", address(camelotBalancedTokenA));
//         console.log("  camelotBalancedTokenB:", address(camelotBalancedTokenB));
//         console.log("  token0:", camelotBalancedPair.token0());
//         console.log("  reserveA:", uint256(reserveA));
//         console.log("  reserveB:", uint256(reserveB));
//         console.log("  feeA:", uint256(feeA));
//         console.log("  feeB:", uint256(feeB));
//         console.log("  reserveIn:", reserveIn);
//         console.log("  reserveOut:", reserveOut);
//         console.log("  feePercentIn:", feePercentIn);
//         console.log("  totalSupply:", totalSupply);
//         console.log("  lpAmountDesired:", lpAmountDesired);

//         // Calculate required input amount for desired LP tokens
//         uint256 requiredInput = ConstProdUtils._swapDepositToTargetQuote(
//             lpAmountDesired,
//             reserveIn,
//             reserveOut,
//             totalSupply,
//             feePercentIn
//         );

//         // Verify the calculation by doing the reverse - use the required input
//         // to calculate LP output and verify it matches our desired amount
//         /// forge-lint: disable-next-line(mixed-case-variable)
//         uint256 calculatedLP = ConstProdUtils._swapDepositQuote(
//             totalSupply,
//             requiredInput,
//             reserveIn,
//             reserveOut,
//             feePercentIn
//         );

//         // Now execute actual swap+deposit with the calculated required input
//         camelotBalancedTokenA.mint(address(this), requiredInput);

//         // Execute actual swap+deposit on Camelot with the calculated input
//         /// forge-lint: disable-next-line(mixed-case-variable)
//         uint256 actualLPTokens = CamelotV2Service._swapDeposit(
//             camV2Router(),
//             camelotBalancedPair,
//             camelotBalancedTokenA,
//             requiredInput,
//             camelotBalancedTokenB,
//             address(0) // referrer
//         );

//         // Verify our target calculation was correct (within tolerance)
//         uint256 tolerance = lpAmountDesired / 100; // 1% tolerance
//         uint256 diffFromDesired = actualLPTokens > lpAmountDesired ?
//             actualLPTokens - lpAmountDesired :
//             lpAmountDesired - actualLPTokens;

//         // Also verify consistency with our quote calculation
//         uint256 diffFromCalculated = actualLPTokens > calculatedLP ?
//             actualLPTokens - calculatedLP :
//             calculatedLP - actualLPTokens;

//         assert(diffFromDesired <= tolerance);
//         assert(diffFromCalculated <= tolerance);
//         assert(requiredInput > 0);
//         assert(actualLPTokens > 0);
//     }

//     function test_swapDepositToTargetQuote_differentAmounts() public view {
//         uint256[] memory lpAmounts = new uint256[](4);
//         lpAmounts[0] = 500e18;
//         lpAmounts[1] = 1000e18;
//         lpAmounts[2] = 2000e18;
//         lpAmounts[3] = 5000e18;

//         (uint112 reserveA, uint112 reserveB, uint16 feeA, uint16 feeB) = camelotBalancedPair.getReserves();
//         uint256 totalSupply = camelotBalancedPair.totalSupply();

//         (
//             uint256 reserveIn,
//             uint256 feePercentIn,
//             uint256 reserveOut,
//             // uint256 feePercentOut
//         ) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA),
//             camelotBalancedPair.token0(),
//             uint256(reserveA),
//             uint256(feeA),
//             uint256(reserveB),
//             uint256(feeB)
//         );

//         for (uint i = 0; i < lpAmounts.length; i++) {
//             uint256 requiredInput = ConstProdUtils._swapDepositToTargetQuote(
//                 lpAmounts[i],
//                 reserveIn,
//                 reserveOut,
//                 totalSupply,
//                 feePercentIn
//             );

//             // Verify the reverse calculation
//         /// forge-lint: disable-next-line(mixed-case-variable)
//             uint256 calculatedLP = ConstProdUtils._swapDepositQuote(
//                 totalSupply,
//                 requiredInput,
//                 reserveIn,
//                 reserveOut,
//                 feePercentIn
//             );

//             // Allow for small rounding differences
//             uint256 tolerance = lpAmounts[i] / 5; // 20% tolerance
//             uint256 diff = calculatedLP > lpAmounts[i] ?
//                 calculatedLP - lpAmounts[i] :
//                 lpAmounts[i] - calculatedLP;

//             assert(diff <= tolerance);
//             assert(requiredInput > 0);
//         }
//     }
// }
