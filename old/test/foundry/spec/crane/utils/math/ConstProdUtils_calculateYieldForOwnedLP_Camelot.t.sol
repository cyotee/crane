// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";

contract ConstProdUtils_calculateYieldForOwnedLP_Camelot is TestBase_ConstProdUtils_Camelot {
    function setUp() public override {
        super.setUp();
    }

    function test_calculateYieldForOwnedLP_5Param_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        _test5Param_camelot(camelotBalancedPair, address(camelotBalancedTokenA));
    }

    function test_calculateYieldForOwnedLP_5Param_Camelot_unbalancedPool() public {
        _initializeCamelotUnbalancedPools();
        _test5Param_camelot(camelotUnbalancedPair, address(camelotUnbalancedTokenA));
    }

    function test_calculateYieldForOwnedLP_6Param_Camelot_balancedPool() public {
        _initializeCamelotBalancedPools();
        _test6Param_camelot(camelotBalancedPair, address(camelotBalancedTokenA));
    }

    function test_calculateYieldForOwnedLP_edgeCases_Camelot() public {
        _initializeCamelotBalancedPools();
        ICamelotPair pair = camelotBalancedPair;
        (uint112 r0, uint112 r1, , ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(camelotBalancedTokenA), pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

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

    function _test5Param_camelot(ICamelotPair pair, address tokenA) internal {
        (uint112 r0, uint112 r1, , ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(tokenA, pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2; // previous K
        uint256 ownedLP = totalSupply / 10;

        (uint256 expectedLpOfYield, uint256 expectedNewK) = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            ownedLP
        );

        assertEq(expectedNewK, reserveA * reserveB, "newK == reserveA*reserveB");
        assertGt(expectedLpOfYield, 0, "yield > 0");
        assertLt(expectedLpOfYield, ownedLP, "yield < ownedLP");
    }

    function _test6Param_camelot(ICamelotPair pair, address tokenA) internal {
        (uint112 r0, uint112 r1, , ) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(tokenA, pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();
        uint256 lastK = (reserveA * reserveB) / 2;
        uint256 newK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10;

        uint256 expectedLpOfYield = ConstProdUtils._calculateYieldForOwnedLP(
            reserveA,
            reserveB,
            totalSupply,
            lastK,
            newK,
            ownedLP
        );

        assertGt(expectedLpOfYield, 0, "yield > 0");
        assertLt(expectedLpOfYield, ownedLP, "yield < ownedLP");
    }
}
