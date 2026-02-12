// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";
import {IRouter} from "contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_swapDepositSaleAmt_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        super.setUp();
    }

    function test_swapDepositSaleAmt_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        Pool pair = aeroBalancedPool;
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroBalancedTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        uint256 feePercent = aerodromePoolFactory.getFee(address(pair), false);
        uint256 denom = feePercent <= 10 ? 1000 : 10000;

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent, denom);
        assertGt(saleAmt, 0, "saleAmt should be > 0");
        assertLe(saleAmt, amountIn, "saleAmt <= amountIn");

        // Do a real swap to ensure saleAmt is executable
        aeroBalancedTokenA.mint(address(this), amountIn);
        aeroBalancedTokenA.approve(address(aerodromeRouter), saleAmt);
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route({from: address(aeroBalancedTokenA), to: address(aeroBalancedTokenB), stable: false, factory: address(aerodromePoolFactory)});
        aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(saleAmt, 1, routes, address(this), block.timestamp);
    }

    function test_swapDepositSaleAmt_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        Pool pair = aeroUnbalancedPool;
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroUnbalancedTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        uint256 feePercent = aerodromePoolFactory.getFee(address(pair), false);
        uint256 denom = feePercent <= 10 ? 1000 : 10000;

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent, denom);
        assertGt(saleAmt, 0, "saleAmt should be > 0");
        assertLe(saleAmt, amountIn, "saleAmt <= amountIn");

        aeroUnbalancedTokenA.mint(address(this), amountIn);
        aeroUnbalancedTokenA.approve(address(aerodromeRouter), saleAmt);
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route({from: address(aeroUnbalancedTokenA), to: address(aeroUnbalancedTokenB), stable: false, factory: address(aerodromePoolFactory)});
        aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(saleAmt, 1, routes, address(this), block.timestamp);
    }

    function test_swapDepositSaleAmt_Aerodrome_extremePool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        Pool pair = aeroExtremeUnbalancedPool;
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroExtremeTokenA), pair.token0(), r0, r1);

        uint256 amountIn = 1000e18;
        uint256 feePercent = aerodromePoolFactory.getFee(address(pair), false);
        uint256 denom = feePercent <= 10 ? 1000 : 10000;

        uint256 saleAmt = ConstProdUtils._swapDepositSaleAmt(amountIn, reserveA, feePercent, denom);
        assertGt(saleAmt, 0, "saleAmt should be > 0");
        assertLe(saleAmt, amountIn, "saleAmt <= amountIn");

        aeroExtremeTokenA.mint(address(this), amountIn);
        aeroExtremeTokenA.approve(address(aerodromeRouter), saleAmt);
        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route({from: address(aeroExtremeTokenA), to: address(aeroExtremeTokenB), stable: false, factory: address(aerodromePoolFactory)});
        aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(saleAmt, 1, routes, address(this), block.timestamp);
    }
}
