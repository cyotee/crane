// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ConstProdUtils_purchaseQuote_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    uint256 constant AERO_FEE_PERCENT = 30; // 30/10000

    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_purchaseQuote_aerodrome_AtoB_balanced_4param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_AtoB(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB, 1, false);
    }

    function test_purchaseQuote_aerodrome_AtoB_unbalanced_4param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_AtoB(aeroUnbalancedPool, aeroUnbalancedTokenA, aeroUnbalancedTokenB, 0, false);
    }

    function test_purchaseQuote_aerodrome_AtoB_extreme_4param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_AtoB(aeroExtremeUnbalancedPool, aeroExtremeTokenA, aeroExtremeTokenB, 0, false);
    }

    function test_purchaseQuote_aerodrome_AtoB_balanced_5param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_AtoB(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB, 1, true);
    }

    function test_purchaseQuote_aerodrome_AtoB_unbalanced_5param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_AtoB(aeroUnbalancedPool, aeroUnbalancedTokenA, aeroUnbalancedTokenB, 0, true);
    }

    function test_purchaseQuote_aerodrome_AtoB_extreme_5param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_AtoB(aeroExtremeUnbalancedPool, aeroExtremeTokenA, aeroExtremeTokenB, 0, true);
    }

    function test_purchaseQuote_aerodrome_BtoA_balanced_4param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_BtoA(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB, 1, false);
    }

    function test_purchaseQuote_aerodrome_BtoA_unbalanced_4param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_BtoA(aeroUnbalancedPool, aeroUnbalancedTokenA, aeroUnbalancedTokenB, 1, false);
    }

    function test_purchaseQuote_aerodrome_BtoA_extreme_4param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_BtoA(aeroExtremeUnbalancedPool, aeroExtremeTokenA, aeroExtremeTokenB, 1, false);
    }

    function test_purchaseQuote_aerodrome_BtoA_balanced_5param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_BtoA(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB, 1, true);
    }

    function test_purchaseQuote_aerodrome_BtoA_unbalanced_5param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_BtoA(aeroUnbalancedPool, aeroUnbalancedTokenA, aeroUnbalancedTokenB, 1, true);
    }

    function test_purchaseQuote_aerodrome_BtoA_extreme_5param() public {
        _initializeAerodromeBalancedPools();
        _initializeAerodromeUnbalancedPools();
        _initializeAerodromeExtremeUnbalancedPools();
        _testPurchaseQuote_Aerodrome_BtoA(aeroExtremeUnbalancedPool, aeroExtremeTokenA, aeroExtremeTokenB, 1, true);
    }

    function _testPurchaseQuote_Aerodrome_AtoB(
        Pool pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 reduce,
        bool use5param
    ) internal {
        (uint256 r0, uint256 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(tokenA), pair.token0(), r0, r1);

        uint256 desiredOutput = ((reserveB / (reduce == 1 ? 10 : (reduce == 0 ? 20 : 100))) - reduce);

        if (use5param) {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, AERO_FEE_PERCENT, 10000);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: address(tokenA), to: address(tokenB), stable: false, factory: address(aerodromePoolFactory)});
            uint256 amountIn = expectedInput;
            uint256[] memory outs = aerodromeRouter.getAmountsOut(amountIn, routes);
            emit log_named_uint("_purchaseQuote_expectedInput", expectedInput);
            emit log_named_uint("aerodromeRouter.getAmountsOut(expectedInput)", outs[outs.length - 1]);
            uint256 poolOutQuoted = pair.getAmountOut(expectedInput, address(tokenB));
            emit log_named_uint("pair.getAmountOut(expectedInput)", poolOutQuoted);
            if (expectedInput > 0) {
                uint256 poolOutQuotedPrev = pair.getAmountOut(expectedInput - 1, address(tokenB));
                emit log_named_uint("pair.getAmountOut(expectedInput-1)", poolOutQuotedPrev);
            }
            if (outs[outs.length - 1] < desiredOutput) {
                uint256 low = amountIn;
                uint256 high = amountIn;
                // exponential search to find an upper bound
                while (true) {
                    high = high == 0 ? 1 : high * 2;
                    outs = aerodromeRouter.getAmountsOut(high, routes);
                    if (outs[outs.length - 1] >= desiredOutput) break;
                }
                // binary search for minimal sufficient amountIn
                while (low + 1 < high) {
                    uint256 mid = (low + high) / 2;
                    outs = aerodromeRouter.getAmountsOut(mid, routes);
                    if (outs[outs.length - 1] < desiredOutput) {
                        low = mid;
                    } else {
                        high = mid;
                    }
                }
                amountIn = high;
            }
            emit log_named_uint("final_amountIn_from_search", amountIn);
            outs = aerodromeRouter.getAmountsOut(amountIn, routes);
            emit log_named_uint("aerodromeRouter.getAmountsOut(final_amountIn)", outs[outs.length - 1]);
            tokenA.mint(address(this), amountIn);
            tokenA.approve(address(aerodromeRouter), amountIn);
            aerodromeRouter.swapExactTokensForTokens(amountIn, desiredOutput, routes, address(this), block.timestamp + 300);
            assertEq(amountIn, expectedInput, "Input used must equal quoted expected input");
        } else {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveA, reserveB, AERO_FEE_PERCENT, 10000);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: address(tokenA), to: address(tokenB), stable: false, factory: address(aerodromePoolFactory)});
            uint256 amountIn = expectedInput;
            uint256[] memory outs = aerodromeRouter.getAmountsOut(amountIn, routes);
            emit log_named_uint("_purchaseQuote_expectedInput", expectedInput);
            emit log_named_uint("aerodromeRouter.getAmountsOut(expectedInput)", outs[outs.length - 1]);
            uint256 poolOutQuoted = pair.getAmountOut(expectedInput, address(tokenB));
            emit log_named_uint("pair.getAmountOut(expectedInput)", poolOutQuoted);
            if (expectedInput > 0) {
                uint256 poolOutQuotedPrev = pair.getAmountOut(expectedInput - 1, address(tokenB));
                emit log_named_uint("pair.getAmountOut(expectedInput-1)", poolOutQuotedPrev);
            }
            if (outs[outs.length - 1] < desiredOutput) {
                uint256 low = amountIn;
                uint256 high = amountIn;
                while (true) {
                    high = high == 0 ? 1 : high * 2;
                    outs = aerodromeRouter.getAmountsOut(high, routes);
                    if (outs[outs.length - 1] >= desiredOutput) break;
                }
                while (low + 1 < high) {
                    uint256 mid = (low + high) / 2;
                    outs = aerodromeRouter.getAmountsOut(mid, routes);
                    if (outs[outs.length - 1] < desiredOutput) {
                        low = mid;
                    } else {
                        high = mid;
                    }
                }
                amountIn = high;
            }
            emit log_named_uint("final_amountIn_from_search", amountIn);
            outs = aerodromeRouter.getAmountsOut(amountIn, routes);
            emit log_named_uint("aerodromeRouter.getAmountsOut(final_amountIn)", outs[outs.length - 1]);
            tokenA.mint(address(this), amountIn);
            tokenA.approve(address(aerodromeRouter), amountIn);
            aerodromeRouter.swapExactTokensForTokens(amountIn, desiredOutput, routes, address(this), block.timestamp + 300);
            assertEq(amountIn, expectedInput, "Input used must equal quoted expected input");
        }
    }

    function _testPurchaseQuote_Aerodrome_BtoA(
        Pool pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB,
        uint256 reduce,
        bool use5param
    ) internal {
        (uint256 r0, uint256 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(tokenA), pair.token0(), r0, r1);

        uint256 desiredOutput = ((reserveA / (reduce == 1 ? 10 : (reduce == 0 ? 20 : 100))) - reduce);

        if (use5param) {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, AERO_FEE_PERCENT, 10000);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: address(tokenB), to: address(tokenA), stable: false, factory: address(aerodromePoolFactory)});
            uint256 amountIn = expectedInput;
            uint256 iter = 0;
            uint256[] memory outs = aerodromeRouter.getAmountsOut(amountIn, routes);
            emit log_named_uint("_purchaseQuote_expectedInput", expectedInput);
            emit log_named_uint("aerodromeRouter.getAmountsOut(expectedInput)", outs[outs.length - 1]);
            uint256 poolOutQuoted = pair.getAmountOut(expectedInput, address(tokenA));
            emit log_named_uint("pair.getAmountOut(expectedInput)", poolOutQuoted);
            if (expectedInput > 0) {
                uint256 poolOutQuotedPrev = pair.getAmountOut(expectedInput - 1, address(tokenA));
                emit log_named_uint("pair.getAmountOut(expectedInput-1)", poolOutQuotedPrev);
            }
            while (outs[outs.length - 1] < desiredOutput && iter < 1024) {
                amountIn += 1;
                outs = aerodromeRouter.getAmountsOut(amountIn, routes);
                iter++;
            }
            emit log_named_uint("final_amountIn_after_linear_search", amountIn);
            outs = aerodromeRouter.getAmountsOut(amountIn, routes);
            emit log_named_uint("aerodromeRouter.getAmountsOut(final_amountIn)", outs[outs.length - 1]);
            tokenB.mint(address(this), amountIn);
            tokenB.approve(address(aerodromeRouter), amountIn);
            aerodromeRouter.swapExactTokensForTokens(amountIn, desiredOutput, routes, address(this), block.timestamp + 300);
            assertEq(amountIn, expectedInput, "Input used must equal quoted expected input");
        } else {
            uint256 expectedInput = ConstProdUtils._purchaseQuote(desiredOutput, reserveB, reserveA, AERO_FEE_PERCENT, 10000);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: address(tokenB), to: address(tokenA), stable: false, factory: address(aerodromePoolFactory)});
            uint256 amountIn = expectedInput;
            uint256 iter = 0;
            uint256[] memory outs = aerodromeRouter.getAmountsOut(amountIn, routes);
            emit log_named_uint("_purchaseQuote_expectedInput", expectedInput);
            emit log_named_uint("aerodromeRouter.getAmountsOut(expectedInput)", outs[outs.length - 1]);
            uint256 poolOutQuoted = pair.getAmountOut(expectedInput, address(tokenA));
            emit log_named_uint("pair.getAmountOut(expectedInput)", poolOutQuoted);
            if (expectedInput > 0) {
                uint256 poolOutQuotedPrev = pair.getAmountOut(expectedInput - 1, address(tokenA));
                emit log_named_uint("pair.getAmountOut(expectedInput-1)", poolOutQuotedPrev);
            }
            while (outs[outs.length - 1] < desiredOutput && iter < 1024) {
                amountIn += 1;
                outs = aerodromeRouter.getAmountsOut(amountIn, routes);
                iter++;
            }
            emit log_named_uint("final_amountIn_after_linear_search", amountIn);
            outs = aerodromeRouter.getAmountsOut(amountIn, routes);
            emit log_named_uint("aerodromeRouter.getAmountsOut(final_amountIn)", outs[outs.length - 1]);
            tokenB.mint(address(this), amountIn);
            tokenB.approve(address(aerodromeRouter), amountIn);
            aerodromeRouter.swapExactTokensForTokens(amountIn, desiredOutput, routes, address(this), block.timestamp + 300);
            assertEq(amountIn, expectedInput, "Input used must equal quoted expected input");
        }
    }
}
