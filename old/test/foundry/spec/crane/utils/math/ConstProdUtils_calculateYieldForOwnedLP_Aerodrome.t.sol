// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import "forge-std/console.sol";

contract ConstProdUtils_calculateYieldForOwnedLP_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    function setUp() public override {
        super.setUp();
    }

    function test_calculateYieldForOwnedLP_5Param_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        _test5Param_aerodrome(aeroBalancedPool, address(aeroBalancedTokenA));
    }

    function test_calculateYieldForOwnedLP_5Param_Aerodrome_unbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        _test5Param_aerodrome(aeroUnbalancedPool, address(aeroUnbalancedTokenA));
    }

    function test_calculateYieldForOwnedLP_6Param_Aerodrome_balancedPool() public {
        _initializeAerodromeBalancedPools();
        _test6Param_aerodrome(aeroBalancedPool, address(aeroBalancedTokenA));
    }

    function test_calculateYieldForOwnedLP_edgeCases_Aerodrome() public {
        _initializeAerodromeBalancedPools();
        Pool pair = aeroBalancedPool;
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(aeroBalancedTokenA), pair.token0(), r0, r1);
        uint256 totalSupply = IERC20(address(pair)).totalSupply();

        // no growth
        uint256 lastK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10;
        uint256 newK = reserveA * reserveB;
        uint256 lpYield5 = ConstProdUtils._calculateYieldForOwnedLP(reserveA, reserveB, totalSupply, lastK, newK, ownedLP);
        assertEq(lpYield5, 0, "no growth -> zero yield");
        assertEq(newK, reserveA * reserveB, "newK equals reserveA*reserveB");

        // zero ownedLP
        newK = reserveA * reserveB;
        lpYield5 = ConstProdUtils._calculateYieldForOwnedLP(reserveA, reserveB, totalSupply, (reserveA*reserveB)/2, newK, 0);
        assertEq(lpYield5, 0, "zero ownedLP -> zero yield");

        // zero total supply
        newK = reserveA * reserveB;
        lpYield5 = ConstProdUtils._calculateYieldForOwnedLP(reserveA, reserveB, 0, (reserveA*reserveB)/2, newK, ownedLP);
        assertEq(lpYield5, 0, "zero totalSupply -> zero yield");

        // decreased K
        newK = reserveA * reserveB;
        lpYield5 = ConstProdUtils._calculateYieldForOwnedLP(reserveA, reserveB, totalSupply, reserveA*reserveB*2, newK, ownedLP);
        assertEq(lpYield5, 0, "decreased K -> zero yield");
    }

    function _test5Param_aerodrome(Pool pair, address tokenA) internal {
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(tokenA, pair.token0(), r0, r1);
        uint256 totalSupply = IERC20(address(pair)).totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // previous K
        uint256 ownedLP = totalSupply / 10;

        // generate trading so K grows
        address other = pair.token0() == tokenA ? pair.token1() : pair.token0();
        _generateTradingActivity(pair, tokenA, other, 100);

        // read new reserves and compute expected yield
        (uint256 nr0, uint256 nr1, ) = pair.getReserves();
        (uint256 newReserveA, uint256 newReserveB) = ConstProdUtils._sortReserves(tokenA, pair.token0(), nr0, nr1);

        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        // owned reserve tokenA before and after
        uint256 beforeOwnedA = (ownedLP * reserveA) / totalSupply;
        uint256 afterOwnedA = (ownedLP * newReserveA) / totalSupply;
        uint256 actualIncreaseA;
        if (afterOwnedA >= beforeOwnedA) {
            actualIncreaseA = afterOwnedA - beforeOwnedA;
        } else {
            console.log("DIAG: afterOwnedA < beforeOwnedA", afterOwnedA, beforeOwnedA);
            actualIncreaseA = 0;
        }

        // convert expected LP-of-yield into tokenA amount under new reserves
        uint256 expectedIncreaseA = (expectedLpOfYield * newReserveA) / totalSupply;

        // diagnostics
        console.log("reserveA", reserveA);
        console.log("reserveB", reserveB);
        console.log("newReserveA", newReserveA);
        console.log("newReserveB", newReserveB);
        console.log("totalSupply", totalSupply);
        console.log("ownedLP", ownedLP);
        console.log("expectedLpOfYield", expectedLpOfYield);
        console.log("beforeOwnedA", beforeOwnedA);
        console.log("afterOwnedA", afterOwnedA);
        console.log("actualIncreaseA", actualIncreaseA);
        console.log("expectedIncreaseA", expectedIncreaseA);

        assertEq(expectedNewK, reserveA * reserveB, "newK == reserveA*reserveB");
        assertGt(expectedLpOfYield, 0, "yield > 0");
        assertLt(expectedLpOfYield, ownedLP, "yield < ownedLP");

        assertEq(actualIncreaseA, expectedIncreaseA, "owned TokenA reserves increased by expected yield");
    }

    function _test6Param_aerodrome(Pool pair, address tokenA) internal {
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(tokenA, pair.token0(), r0, r1);
        uint256 totalSupply = IERC20(address(pair)).totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2;
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10;

        // generate trading activity so reserves advance
        address other = pair.token0() == tokenA ? pair.token1() : pair.token0();
        _generateTradingActivity(pair, tokenA, other, 100);

        (uint256 nr0, uint256 nr1, ) = pair.getReserves();
        (uint256 newReserveA, uint256 newReserveB) = ConstProdUtils._sortReserves(tokenA, pair.token0(), nr0, nr1);

        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        uint256 beforeOwnedA = (ownedLP * reserveA) / totalSupply;
        uint256 afterOwnedA = (ownedLP * newReserveA) / totalSupply;
        uint256 actualIncreaseA;
        if (afterOwnedA >= beforeOwnedA) {
            actualIncreaseA = afterOwnedA - beforeOwnedA;
        } else {
            console.log("DIAG: afterOwnedA < beforeOwnedA", afterOwnedA, beforeOwnedA);
            actualIncreaseA = 0;
        }
        uint256 expectedIncreaseA = (expectedLpOfYield * newReserveA) / totalSupply;

        // diagnostics
        console.log("reserveA", reserveA);
        console.log("reserveB", reserveB);
        console.log("newReserveA", newReserveA);
        console.log("newReserveB", newReserveB);
        console.log("totalSupply", totalSupply);
        console.log("ownedLP", ownedLP);
        console.log("expectedLpOfYield", expectedLpOfYield);
        console.log("beforeOwnedA", beforeOwnedA);
        console.log("afterOwnedA", afterOwnedA);
        console.log("actualIncreaseA", actualIncreaseA);
        console.log("expectedIncreaseA", expectedIncreaseA);

        assertGt(expectedLpOfYield, 0, "yield > 0");
        assertLt(expectedLpOfYield, ownedLP, "yield < ownedLP");

        assertEq(actualIncreaseA, expectedIncreaseA, "owned TokenA reserves increased by expected yield");
    }

    // Simple trading activity generator for Aerodrome pairs
    function _generateTradingActivity(Pool pair, address tokenA, address tokenB, uint256 swapPercentage) internal {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        uint256 swapAmountA = (uint256(reserve0) * swapPercentage) / 10000;
        uint256 swapAmountB = (uint256(reserve1) * swapPercentage) / 10000;

        // mint tokens to this contract
        ERC20PermitMintableStub(tokenA).mint(address(this), swapAmountA);
        ERC20PermitMintableStub(tokenB).mint(address(this), swapAmountB);

        ERC20PermitMintableStub(tokenA).approve(address(router), swapAmountA);
        IRouter.Route[] memory routesAB = new IRouter.Route[](1);
        routesAB[0] = IRouter.Route({from: tokenA, to: tokenB, stable: false, factory: address(factory)});
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(swapAmountA, 1, routesAB, address(this), block.timestamp);

        uint256 receivedB = IERC20(tokenB).balanceOf(address(this));
        if (receivedB > 0) {
            ERC20PermitMintableStub(tokenB).approve(address(router), receivedB);
            IRouter.Route[] memory routesBA = new IRouter.Route[](1);
            routesBA[0] = IRouter.Route({from: tokenB, to: tokenA, stable: false, factory: address(factory)});
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(receivedB, 1, routesBA, address(this), block.timestamp);
        }
    }
}
