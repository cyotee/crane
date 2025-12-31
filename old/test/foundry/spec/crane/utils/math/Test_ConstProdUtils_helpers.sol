// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {Test} from "forge-std/Test.sol";
import {TestBase_ConstProdUtils} from "./TestBase_ConstProdUtils.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
// import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
// import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";

/**
 * @title ConstProdUtils_helpersTest
 * @dev Tests ConstProdUtils helper functions and edge cases
 */
// contract Test_ConstProdUtils_helpers is Test, TestBase_ConstProdUtils {

//     function setUp() public override {
//         super.setUp();
//         _initializePools();
//     }

//     function run() public override {
//         // super.run();
//         // _initializePools();
//     }

//     function test_withdrawTargetQuote() public {
//         // Get LP tokens first
//         uint256 depositAmountA = 5000e18;
//         uint256 depositAmountB = 5000e18;

//         camelotBalancedTokenA.mint(address(this), depositAmountA);
//         camelotBalancedTokenB.mint(address(this), depositAmountB);

//         CamelotV2Service._deposit(
//             camV2Router(),
//             camelotBalancedTokenA,
//             camelotBalancedTokenB,
//             depositAmountA,
//             depositAmountB
//         );

//         // Get current reserves and total supply
//         (uint112 reserveA,,,) = camelotBalancedPair.getReserves();
//         uint256 totalSupply = camelotBalancedPair.totalSupply();

//         // Test target withdraw quote for specific amount
//         uint256 targetAmount = 1000e18;

//         uint256 lpRequired = ConstProdUtils._withdrawTargetQuote(
//             targetAmount,
//             totalSupply,
//             uint256(reserveA)
//         );

//         // Verify the LP amount gives us at least the target amount
//         uint256 actualWithdraw = (lpRequired * uint256(reserveA)) / totalSupply;

//         // THE KEY ASSERTION: LP required should give at least the target amount
//         assertGe(actualWithdraw, targetAmount, "LP amount should withdraw at least target amount");
//     }

//     function test_withdrawTargetQuote_edgeCases() public pure {
//         uint256 lpTotalSupply = 1000e18;
//         uint256 outRes = 2000e18;

//         // Test edge cases return expected values
//         assertEq(ConstProdUtils._withdrawTargetQuote(0, lpTotalSupply, outRes), 0, "Zero target should return zero LP");
//         assertEq(ConstProdUtils._withdrawTargetQuote(100e18, 0, outRes), 0, "Zero LP supply should return zero");
//         assertEq(ConstProdUtils._withdrawTargetQuote(100e18, lpTotalSupply, 0), 0, "Zero reserves should return zero");
//         assertEq(ConstProdUtils._withdrawTargetQuote(3000e18, lpTotalSupply, outRes), 0, "Target exceeding reserves should return zero");
//     }

//     function test_saleQuoteMin() public pure {
//         uint256 saleReserve = 10000e18;
//         uint256 purchaseReserve = 20000e18;
//         uint256 fee = 300; // 0.3%
//         uint256 feeDenominator = 100000;

//         uint256 minAmountIn = ConstProdUtils._saleQuoteMin(
//             saleReserve,
//             purchaseReserve,
//             fee,
//             feeDenominator
//         );

//         // Test that this minimum amount produces at least 1 unit of output
//         uint256 actualOutput = ConstProdUtils._saleQuote(
//             minAmountIn,
//             saleReserve,
//             purchaseReserve,
//             fee
//         );

//         // THE KEY ASSERTION: Minimum amount should produce at least 1 unit of output
//         assertGe(actualOutput, 1, "Minimum sale amount should produce at least 1 unit output");
//     }

//     function test_calculateProtocolFee() public pure {
//         uint256 lpTotalSupply = 1000000e18;
//         uint256 newK = 25000000e36; // 50000^2
//         uint256 kLast = 24000000e36; // Smaller K, indicating growth
//         uint256 ownerFeeShare = 16667; // 1/6 fee share (about 16.67%)

//         uint256 feeAmount = ConstProdUtils._calculateProtocolFee(
//             lpTotalSupply,
//             newK,
//             kLast,
//             ownerFeeShare
//         );

//         // Verify fee is calculated when K grows
//         assert(feeAmount > 0);

//         console.log("Protocol fee test passed:");
//         console.log("  LP total supply: ", lpTotalSupply);
//         console.log("  New K:           ", newK);
//         console.log("  Last K:          ", kLast);
//         console.log("  Owner fee share: ", ownerFeeShare);
//         console.log("  Fee amount:      ", feeAmount);

//         // Test no fee when K doesn't grow
//         uint256 noFee = ConstProdUtils._calculateProtocolFee(
//             lpTotalSupply,
//             kLast,
//             newK, // kLast > newK
//             ownerFeeShare
//         );
//         assert(noFee == 0);

//         // Test no fee when kLast is 0
//         uint256 noFee2 = ConstProdUtils._calculateProtocolFee(
//             lpTotalSupply,
//             newK,
//             0,
//             ownerFeeShare
//         );
//         assert(noFee2 == 0);

//         console.log("Protocol fee edge cases passed");
//     }

//     // function test_quoteSwapDepositWithFee() public pure {
//     //     uint256 lpTotalSupply = 1000000e18;
//     //     uint256 amountIn = 1000e18;
//     //     uint256 reserveIn = 50000e18;
//     //     uint256 reserveOut = 50000e18;
//     //     uint256 feePercent = 300;
//     //     uint256 kLast = (reserveIn * reserveOut) * 95 / 100; // Simulate some K growth
//     //     uint256 ownerFeeShare = 16667;
//     //     bool feeOn = true;

//     //     (uint256 lpAmt, uint256 protocolFee) = ConstProdUtils._quoteSwapDepositWithFee(
//     //         lpTotalSupply,
//     //         amountIn,
//     //         reserveIn,
//     //         reserveOut,
//     //         feePercent,
//     //         kLast,
//     //         ownerFeeShare,
//     //         feeOn
//     //     );

//     //     // Verify LP amount is reasonable
//     //     assert(lpAmt > 0);

//     //     // Verify protocol fee is calculated when fees are on and K grows
//     //     assert(protocolFee > 0);

//     //     console.log("Swap deposit with fee test passed:");
//     //     console.log("  LP amount:       ", lpAmt);
//     //     console.log("  Protocol fee:    ", protocolFee);

//     //     // Test with fees off
//     //     ( , uint256 protocolFeeOff) = ConstProdUtils._quoteSwapDepositWithFee(
//     //         lpTotalSupply,
//     //         amountIn,
//     //         reserveIn,
//     //         reserveOut,
//     //         feePercent,
//     //         kLast,
//     //         ownerFeeShare,
//     //         false // feeOn = false
//     //     );

//     //     assert(protocolFeeOff == 0);
//     //     console.log("Fees off test passed");
//     // }

//     function test_sortReserves() public view {
//         address tokenA = address(camelotBalancedTokenA);
//         // address tokenB = address(camelotBalancedTokenB);
//         address token0 = camelotBalancedPair.token0();
//         uint256 reserve0 = 1000e18;
//         uint256 reserve1 = 2000e18;

//         // Test sorting with tokenA as known token
//         (uint256 knownReserve, uint256 unknownReserve) = ConstProdUtils._sortReserves(
//             tokenA,
//             token0,
//             reserve0,
//             reserve1
//         );

//         if (tokenA == token0) {
//             assert(knownReserve == reserve0);
//             assert(unknownReserve == reserve1);
//         } else {
//             assert(knownReserve == reserve1);
//             assert(unknownReserve == reserve0);
//         }

//         console.log("Sort reserves test passed:");
//         console.log("  Token A:         ", tokenA);
//         console.log("  Token0:          ", token0);
//         console.log("  Known reserve:   ", knownReserve);
//         console.log("  Unknown reserve: ", unknownReserve);
//     }

//     function test_sortReservesWithFees() public view {
//         address tokenA = address(camelotBalancedTokenA);
//         address token0 = camelotBalancedPair.token0();
//         uint256 reserve0 = 1000e18;
//         uint256 reserve0Fee = 300;
//         uint256 reserve1 = 2000e18;
//         uint256 reserve1Fee = 250;

//         (uint256 knownReserve, uint256 knownReserveFee, uint256 unknownReserve, uint256 unknownReserveFee) =
//             ConstProdUtils._sortReserves(
//                 tokenA,
//                 token0,
//                 reserve0,
//                 reserve0Fee,
//                 reserve1,
//                 reserve1Fee
//             );

//         if (tokenA == token0) {
//             assert(knownReserve == reserve0);
//             assert(knownReserveFee == reserve0Fee);
//             assert(unknownReserve == reserve1);
//             assert(unknownReserveFee == reserve1Fee);
//         } else {
//             assert(knownReserve == reserve1);
//             assert(knownReserveFee == reserve1Fee);
//             assert(unknownReserve == reserve0);
//             assert(unknownReserveFee == reserve0Fee);
//         }

//         console.log("Sort reserves with fees test passed");
//     }

//     function test_k_calculation() public pure {
//         uint256 balanceA = 50000e18;
//         uint256 balanceB = 40000e18;

//         uint256 k = ConstProdUtils._k(balanceA, balanceB);
//         uint256 expectedK = balanceA * balanceB;

//         // THE KEY ASSERTION: K calculation must equal product of balances
//         assertEq(k, expectedK, "K calculation must equal balanceA * balanceB");
//     }

//     // function test_calculateProtocolFee_alternative() public pure {
//     //     uint256 reserveA = 50000e18;
//     //     uint256 reserveB = 40000e18;
//     //     uint256 totalSupply = 1000000e18;
//     //     uint256 lastK = (reserveA * reserveB) * 90 / 100; // Simulate K growth
//     //     uint256 vaultFee = 16667;

//     //     (uint256 feeAmount, uint256 newK) = ConstProdUtils._calculateProtocolFee(
//     //         reserveA,
//     //         reserveB,
//     //         totalSupply,
//     //         lastK,
//     //         vaultFee
//     //     );

//     //     // Verify new K is calculated correctly
//     //     assert(newK == reserveA * reserveB);

//     //     // Verify fee is calculated when K grows
//     //     assert(feeAmount > 0);

//     //     console.log("Alternative protocol fee test passed:");
//     //     console.log("  Fee amount: ", feeAmount);
//     //     console.log("  New K:      ", newK);
//     // }

//     // function test_calcFeePerLp_validation() public {
//     //     // Get LP tokens by depositing
//     //     uint256 depositAmountA = 2000e18;
//     //     uint256 depositAmountB = 2000e18;

//     //     camelotBalancedTokenA.mint(address(this), depositAmountA);
//     //     camelotBalancedTokenB.mint(address(this), depositAmountB);

//     //     // uint256 liquidityGained =
//     //     CamelotV2Service._deposit(
//     //         camV2Router(),
//     //         camelotBalancedTokenA,
//     //         camelotBalancedTokenB,
//     //         depositAmountA,
//     //         depositAmountB
//     //     );

//     //     // Record initial state
//     //     /// forge-lint: disable-next-line(mixed-case-variable)
//     //     (uint112 reserveA_before, uint112 reserveB_before,,) = camelotBalancedPair.getReserves();
//     //     /// forge-lint: disable-next-line(mixed-case-variable)
//     //     uint256 totalSupply_before = camelotBalancedPair.totalSupply();
//     //     /// forge-lint: disable-next-line(mixed-case-variable)
//     //     uint256 k_before = uint256(reserveA_before) * uint256(reserveB_before);

//     //     // Execute some swaps to generate fees
//     //     uint256 swapAmount = 1000e18;
//     //     camelotBalancedTokenA.mint(address(this), swapAmount);

//     //     CamelotV2Service._swap(
//     //         camV2Router(),
//     //         camelotBalancedPair,
//     //         swapAmount,
//     //         camelotBalancedTokenA,
//     //         camelotBalancedTokenB,
//     //         address(0)
//     //     );

//     //     // Get current state after fee generation
//     //     /// forge-lint: disable-next-line(mixed-case-variable)
//     //     (uint112 reserveA_after, uint112 reserveB_after,,) = camelotBalancedPair.getReserves();
//     //     /// forge-lint: disable-next-line(mixed-case-variable)
//     //     uint256 totalSupply_after = camelotBalancedPair.totalSupply();

//     //     // Calculate expected fees using ConstProdUtils._calcFeePerLp
//     //     // k_last, lpTotalSupply_last, reserveIT_current, reserveOT_current, lpTotalSupply_current
//     //     (uint256 expectedFeeA, uint256 expectedFeeB) = ConstProdUtils._calcFeePerLp(
//     //         k_before,
//     //         totalSupply_before,
//     //         uint256(reserveA_after),
//     //         uint256(reserveB_after),
//     //         totalSupply_after
//     //     );

//     //     // The fee calculation is complex and depends on protocol implementation
//     //     // For this test, we verify the function executes without reverting
//     //     // and returns reasonable values

//     //     // THE KEY ASSERTION: Fee calculations should not revert and should be non-negative
//     //     // Note: In a real AMM with protocol fees, these would be non-zero after swaps
//     //     assertGe(expectedFeeA, 0, "Fee A should be non-negative");
//     //     assertGe(expectedFeeB, 0, "Fee B should be non-negative");
//     // }
// }
