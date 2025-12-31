// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
// import {TestBase_ConstProdUtils_Uniswap} from "@crane/test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Uniswap.sol";

// contract ConstProdUtils_calculateVaultFee_Uniswap is TestBase_ConstProdUtils_Uniswap {
//     function setUp() public override {
//         TestBase_ConstProdUtils_Uniswap.setUp();
//     }

//     function test_calculateVaultFee_Uniswap_balancedPool() public {
//         _initializeUniswapBalancedPools();
//         (uint112 r0, uint112 r1, ) = uniswapBalancedPair.getReserves();
//         uint256 totalSupply = uniswapBalancedPair.totalSupply();

//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA),
//             uniswapBalancedPair.token0(),
//             r0,
//             r1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2;
//         uint256 vaultFee = 500; // 0.5%
//         uint256 feeDenominator = 100000;

//         (uint256 expectedFeeAmount, uint256 expectedNewK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
//         assertGt(expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFee_Uniswap_unbalancedPool() public {
//         _initializeUniswapUnbalancedPools();
//         (uint112 r0, uint112 r1, ) = uniswapUnbalancedPair.getReserves();
//         uint256 totalSupply = uniswapUnbalancedPair.totalSupply();

//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapUnbalancedTokenA),
//             uniswapUnbalancedPair.token0(),
//             r0,
//             r1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2;
//         uint256 vaultFee = 500;
//         uint256 feeDenominator = 100000;

//         (uint256 expectedFeeAmount, uint256 expectedNewK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
//         assertGt(expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");
//     }

//     function test_calculateVaultFee_Uniswap_extremeUnbalancedPool() public {
//         _initializeUniswapExtremeUnbalancedPools();
//         (uint112 r0, uint112 r1, ) = uniswapExtremeUnbalancedPair.getReserves();
//         uint256 totalSupply = uniswapExtremeUnbalancedPair.totalSupply();

//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapExtremeTokenA),
//             uniswapExtremeUnbalancedPair.token0(),
//             r0,
//             r1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2;
//         uint256 vaultFee = 500;
//         uint256 feeDenominator = 100000;

//         (uint256 expectedFeeAmount, uint256 expectedNewK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         assertEq(expectedNewK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
//         assertGt(expectedFeeAmount, 0, "Fee amount should be greater than 0 when K has grown");
//     }

//     // _calculateVaultFeeNoNewK variants
//     function test_calculateVaultFeeNoNewK_Uniswap_balancedPool() public {
//         _initializeUniswapBalancedPools();
//         (uint112 r0, uint112 r1, ) = uniswapBalancedPair.getReserves();
//         uint256 totalSupply = uniswapBalancedPair.totalSupply();

//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA),
//             uniswapBalancedPair.token0(),
//             r0,
//             r1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2;
//         uint256 vaultFee = 500;
//         uint256 feeDenominator = 100000;

//         uint256 expectedLpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         assertGt(expectedLpOfYield, 0, "LP of yield should be greater than 0 when K has grown");
//         assertLt(expectedLpOfYield, totalSupply / 10, "LP of yield should be much less than total supply");
//     }

//     function test_calculateVaultFee_consistency() public {
//         _initializeUniswapBalancedPools();
//         (uint112 r0, uint112 r1, ) = uniswapBalancedPair.getReserves();
//         uint256 totalSupply = uniswapBalancedPair.totalSupply();

//         (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
//             address(uniswapBalancedTokenA),
//             uniswapBalancedPair.token0(),
//             r0,
//             r1
//         );

//         uint256 lastK = (reserveA * reserveB) / 2;
//         uint256 vaultFee = 500;
//         uint256 feeDenominator = 100000;

//         (uint256 feeAmount, uint256 newK) = ConstProdUtils._calculateVaultFee(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         uint256 lpOfYield = ConstProdUtils._calculateVaultFeeNoNewK(
//             reserveA,
//             reserveB,
//             totalSupply,
//             lastK,
//             vaultFee,
//             feeDenominator
//         );

//         assertEq(feeAmount, lpOfYield, "Both functions should return the same fee amount");
//         assertEq(newK, reserveA * reserveB, "NewK should equal reserveA * reserveB");
//     }
// }
