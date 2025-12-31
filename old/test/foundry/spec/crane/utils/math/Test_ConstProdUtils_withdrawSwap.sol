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
 * @title ConstProdUtils_withdrawSwapTest
 * @dev Tests ConstProdUtils._withdrawSwapQuote against actual DEX withdraw+swap operations
 */
// contract Test_ConstProdUtils_withdrawSwap is TestBase_ConstProdUtils {

//     struct WithdrawSwapTestData {
//         uint256 depositAmountA;
//         uint256 depositAmountB;
//         uint256 liquidityGained;
//         uint256 liquidityToWithdraw;
//         uint256 reserveA;
//         uint256 reserveB;
//         uint256 feePercent;
//         uint256 totalSupply;
//         uint256 expectedAmountOut;
//         uint256 initialBalanceA;
//         uint256 actualAmountOut;
//         uint256 finalBalanceA;
//         uint256 receivedAmount;
//     }

//     function setUp() public override {
//         super.setUp();
//     }

//     function run() public override {
//         // super.run();
//         // _initializePools();
//     }

//     function test_withdrawSwapQuote_camelot() public {
//         WithdrawSwapTestData memory data;

//         // First, get some LP tokens by depositing
//         data.depositAmountA = 3000e18;
//         data.depositAmountB = 3000e18;

//         camelotBalancedTokenA.mint(address(this), data.depositAmountA);
//         camelotBalancedTokenB.mint(address(this), data.depositAmountB);

//         data.liquidityGained = CamelotV2Service._deposit(
//             camV2Router(),
//             camelotBalancedTokenA,
//             camelotBalancedTokenB,
//             data.depositAmountA,
//             data.depositAmountB
//         );

//         // Test withdraw+swap with partial LP tokens
//         data.liquidityToWithdraw = data.liquidityGained / 2;

//         // Get current reserves and total supply
//         (uint112 reserve0, uint112 reserve1, uint16 token0Fee, uint16 token1Fee) = camelotBalancedPair.getReserves();
//         (data.reserveA, data.feePercent, data.reserveB, ) = ConstProdUtils._sortReserves(
//             address(camelotBalancedTokenA), camelotBalancedPair.token0(), reserve0, uint256(token0Fee), reserve1, uint256(token1Fee)
//         );
//         data.totalSupply = camelotBalancedPair.totalSupply();

//         // Calculate expected output using ConstProdUtils
//         data.expectedAmountOut = ConstProdUtils._withdrawSwapQuote(
//             data.liquidityToWithdraw,
//             data.totalSupply,
//             data.reserveA,
//             data.reserveB,
//             data.feePercent
//         );

//         // Record initial balance of target token
//         data.initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

//         // Perform actual withdraw+swap via CamelotV2Service
//         data.actualAmountOut = CamelotV2Service._withdrawSwapDirect(
//             camelotBalancedPair,
//             camV2Router(),
//             data.liquidityToWithdraw,
//             camelotBalancedTokenA,
//             camelotBalancedTokenB,
//             address(0) // referrer
//         );

//         data.finalBalanceA = camelotBalancedTokenA.balanceOf(address(this));
//         data.receivedAmount = data.finalBalanceA - data.initialBalanceA;

//         // Verify calculations match actual results
//         assert(data.actualAmountOut == data.expectedAmountOut);
//         assert(data.receivedAmount == data.actualAmountOut);

//         console.log("Camelot withdraw+swap test passed:");
//         console.log("  Liquidity withdrawn: ", data.liquidityToWithdraw);
//         console.log("  Expected token A:    ", data.expectedAmountOut);
//         console.log("  Actual token A:      ", data.actualAmountOut);
//         console.log("  Received amount:     ", data.receivedAmount);
//         console.log("  Fee percent:         ", data.feePercent);
//     }

//     function test_withdrawSwapQuote_uniswap() public {
//         // First, get some LP tokens by depositing
//         uint256 depositAmountA = 3000e18;
//         uint256 depositAmountB = 3000e18;

//         uniswapBalancedTokenA.mint(address(this), depositAmountA);
//         uniswapBalancedTokenB.mint(address(this), depositAmountB);

//         uint256 liquidityGained = UniswapV2Service._deposit(
//             IUniswapV2Router(address(uniswapV2Router())),
//             uniswapBalancedTokenA,
//             uniswapBalancedTokenB,
//             depositAmountA,
//             depositAmountB
//         );

//         // Test withdraw+swap with partial LP tokens
//         uint256 liquidityToWithdraw = liquidityGained / 2;

//         // Get current reserves and total supply
//         (uint112 reserveA, uint112 reserveB,) = uniswapBalancedPair.getReserves();
//         uint256 totalSupply = uniswapBalancedPair.totalSupply();
//         uint256 feePercent = 300; // 0.3% standard Uniswap fee

//         // Calculate expected output using ConstProdUtils
//         uint256 expectedAmountOut = ConstProdUtils._withdrawSwapQuote(
//             liquidityToWithdraw,
//             totalSupply,
//             uint256(reserveA),
//             uint256(reserveB),
//             feePercent
//         );

//         // Record initial balance of target token
//         uint256 initialBalanceA = uniswapBalancedTokenA.balanceOf(address(this));

//         // Perform actual withdraw+swap via UniswapV2Service
//         uint256 actualAmountOut = UniswapV2Service._withdrawSwapDirect(
//             uniswapBalancedPair,
//             IUniswapV2Router(address(uniswapV2Router())),
//             liquidityToWithdraw,
//             uniswapBalancedTokenA,
//             uniswapBalancedTokenB
//         );

//         uint256 finalBalanceA = uniswapBalancedTokenA.balanceOf(address(this));
//         uint256 receivedAmount = finalBalanceA - initialBalanceA;

//         // Verify calculations match actual results
//         assert(actualAmountOut == expectedAmountOut);
//         assert(receivedAmount == actualAmountOut);

//         console.log("Uniswap withdraw+swap test passed:");
//         console.log("  Liquidity withdrawn: ", liquidityToWithdraw);
//         console.log("  Expected token A:    ", expectedAmountOut);
//         console.log("  Actual token A:      ", actualAmountOut);
//         console.log("  Received amount:     ", receivedAmount);
//         console.log("  Fee percent:         ", feePercent);
//     }

//     function test_withdrawSwapQuote_differentAmounts() public {
//         // First deposit to get LP tokens
//         uint256 depositAmountA = 5000e18;
//         uint256 depositAmountB = 5000e18;

//         camelotBalancedTokenA.mint(address(this), depositAmountA);
//         camelotBalancedTokenB.mint(address(this), depositAmountB);

//         uint256 liquidityGained = CamelotV2Service._deposit(
//             camV2Router(),
//             camelotBalancedTokenA,
//             camelotBalancedTokenB,
//             depositAmountA,
//             depositAmountB
//         );

//         // Test different withdrawal amounts
//         uint256[] memory withdrawAmounts = new uint256[](4);
//         withdrawAmounts[0] = liquidityGained / 10; // 10%
//         withdrawAmounts[1] = liquidityGained / 4;  // 25%
//         withdrawAmounts[2] = liquidityGained / 2;  // 50%
//         withdrawAmounts[3] = liquidityGained * 3 / 4; // 75%

//         (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotBalancedPair.getReserves();
//         uint256 totalSupply = camelotBalancedPair.totalSupply();
//         uint256 feePercent = uint256(feeA);

//         console.log("Testing different withdraw+swap amounts:");

//         for (uint i = 0; i < withdrawAmounts.length; i++) {
//             uint256 expectedOut = ConstProdUtils._withdrawSwapQuote(
//                 withdrawAmounts[i],
//                 totalSupply,
//                 uint256(reserveA),
//                 uint256(reserveB),
//                 feePercent
//             );

//             // Verify output is reasonable
//             assert(expectedOut > 0);

//             console.log("  Liquidity amount:", withdrawAmounts[i]);
//             console.log("  Token A out:     ", expectedOut);
//         }
//     }

//     function test_withdrawSwapQuote_fullWithdraw() public {
//         // First deposit to get LP tokens
//         uint256 depositAmountA = 2000e18;
//         uint256 depositAmountB = 2000e18;

//         camelotBalancedTokenA.mint(address(this), depositAmountA);
//         camelotBalancedTokenB.mint(address(this), depositAmountB);

//         uint256 liquidityGained = CamelotV2Service._deposit(
//             camV2Router(),
//             camelotBalancedTokenA,
//             camelotBalancedTokenB,
//             depositAmountA,
//             depositAmountB
//         );

//         // Test full withdrawal and swap
//         uint256 liquidityToWithdraw = liquidityGained;

//         // Get current reserves and total supply
//         (uint112 reserveA, uint112 reserveB, uint16 feeA,) = camelotBalancedPair.getReserves();
//         uint256 totalSupply = camelotBalancedPair.totalSupply();
//         uint256 feePercent = uint256(feeA);

//         // Calculate expected output using ConstProdUtils
//         uint256 expectedAmountOut = ConstProdUtils._withdrawSwapQuote(
//             liquidityToWithdraw,
//             totalSupply,
//             uint256(reserveA),
//             uint256(reserveB),
//             feePercent
//         );

//         // Record initial balance
//         uint256 initialBalanceA = camelotBalancedTokenA.balanceOf(address(this));

//         // Perform actual withdraw+swap
//         uint256 actualAmountOut = CamelotV2Service._withdrawSwapDirect(
//             camelotBalancedPair,
//             camV2Router(),
//             liquidityToWithdraw,
//             camelotBalancedTokenA,
//             camelotBalancedTokenB,
//             address(0) // referrer
//         );

//         uint256 finalBalanceA = camelotBalancedTokenA.balanceOf(address(this));
//         uint256 receivedAmount = finalBalanceA - initialBalanceA;

//         // Verify calculations match actual results
//         assert(actualAmountOut == expectedAmountOut);
//         assert(receivedAmount == actualAmountOut);

//         console.log("Full withdraw+swap test passed:");
//         console.log("  Liquidity withdrawn: ", liquidityToWithdraw);
//         console.log("  Expected token A:    ", expectedAmountOut);
//         console.log("  Actual token A:      ", actualAmountOut);
//         console.log("  Received amount:     ", receivedAmount);
//     }
// }
