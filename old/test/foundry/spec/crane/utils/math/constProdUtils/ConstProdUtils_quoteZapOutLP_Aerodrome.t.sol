// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {IRouter} from "contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

contract ConstProdUtils_quoteZapOutLP_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function test_quoteZapOutLP_Aerodrome_balancedPool_simple() public {
        _initializeAerodromeBalancedPools();

        Pool pair = aeroBalancedPool;
        (uint256 r0, uint256 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroBalancedTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: factory.getFee(address(pair), false),
            feeDenominator: 10000,
            kLast: 0,
            ownerFeeShare: 0,
            feeOn: false,
            protocolFeeDenominator: 10000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        uint256 balBefore = aeroBalancedTokenA.balanceOf(address(this));
        pair.transfer(address(pair), quoted);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 saleAmount;
        address token0 = pair.token0();
        if (address(aeroBalancedTokenA) == token0) {
            saleAmount = a1;
        } else {
            saleAmount = a0;
        }
        if (saleAmount > 0) {
            IERC20(pair.token0() == address(aeroBalancedTokenA) ? pair.token1() : pair.token0()).approve(address(router), saleAmount);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            address tokenFrom = pair.token0() == address(aeroBalancedTokenA) ? pair.token1() : pair.token0();
            routes[0] = IRouter.Route({from: tokenFrom, to: address(aeroBalancedTokenA), stable: false, factory: address(factory)});
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(saleAmount, 1, routes, address(this), block.timestamp);
        }

        uint256 balAfter = aeroBalancedTokenA.balanceOf(address(this));
        uint256 actualOut = balAfter - balBefore;
        assertEq(actualOut, desiredOut, "Should receive exact desired TokenA amount");
    }

    function test_quoteZapOutLP_Aerodrome_unbalancedPool_simple() public {
        _initializeAerodromeUnbalancedPools();
        Pool pair = aeroUnbalancedPool;
        (uint256 r0, uint256 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: factory.getFee(address(pair), false),
            feeDenominator: 10000,
            kLast: 0,
            ownerFeeShare: 0,
            feeOn: false,
            protocolFeeDenominator: 10000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        uint256 balBefore = aeroUnbalancedTokenA.balanceOf(address(this));
        pair.transfer(address(pair), quoted);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 saleAmount;
        address token0 = pair.token0();
        if (address(aeroUnbalancedTokenA) == token0) {
            saleAmount = a1;
        } else {
            saleAmount = a0;
        }
        if (saleAmount > 0) {
            address tokenFrom = pair.token0() == address(aeroUnbalancedTokenA) ? pair.token1() : pair.token0();
            IERC20(tokenFrom).approve(address(router), saleAmount);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: tokenFrom, to: address(aeroUnbalancedTokenA), stable: false, factory: address(factory)});
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(saleAmount, 1, routes, address(this), block.timestamp);
        }

        uint256 balAfter = aeroUnbalancedTokenA.balanceOf(address(this));
        uint256 actualOut = balAfter - balBefore;
        assertEq(actualOut, desiredOut, "Should receive exact desired TokenA amount");
    }

    function test_quoteZapOutLP_Aerodrome_extremePool_simple() public {
        _initializeAerodromeExtremeUnbalancedPools();
        Pool pair = aeroExtremeUnbalancedPool;
        (uint256 r0, uint256 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroExtremeTokenA), pair.token0(), r0, r1);

        uint256 desiredOut = reserveA / 10; // 10%

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveA,
            reserveOther: reserveB,
            feePercent: factory.getFee(address(pair), false),
            feeDenominator: 10000,
            kLast: 0,
            ownerFeeShare: 0,
            feeOn: false,
            protocolFeeDenominator: 10000
        });

        uint256 quoted = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quoted > 0, "quoted > 0");
        assertTrue(quoted <= totalSupply, "quoted <= totalSupply");

        uint256 balBefore = aeroExtremeTokenA.balanceOf(address(this));
        pair.transfer(address(pair), quoted);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 saleAmount;
        address token0 = pair.token0();
        if (address(aeroExtremeTokenA) == token0) {
            saleAmount = a1;
        } else {
            saleAmount = a0;
        }
        if (saleAmount > 0) {
            address tokenFrom = pair.token0() == address(aeroExtremeTokenA) ? pair.token1() : pair.token0();
            IERC20(tokenFrom).approve(address(router), saleAmount);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: tokenFrom, to: address(aeroExtremeTokenA), stable: false, factory: address(factory)});
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(saleAmount, 1, routes, address(this), block.timestamp);
        }

        uint256 balAfter = aeroExtremeTokenA.balanceOf(address(this));
        uint256 actualOut = balAfter - balBefore;
        assertEq(actualOut, desiredOut, "Should receive exact desired TokenA amount");
    }
}
