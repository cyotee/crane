// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";

contract ConstProdUtils_calculateYieldForOwnedLP_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
    }

    function test_calculateYieldForOwnedLP_5Param_Uniswap_balancedPool() public {
        _initializeUniswapBalancedPools();
        _test5Param_uniswap(uniswapBalancedPair);
    }

    function test_calculateYieldForOwnedLP_5Param_Uniswap_unbalancedPool() public {
        _initializeUniswapUnbalancedPools();
        _test5Param_uniswap(uniswapUnbalancedPair);
    }

    function test_calculateYieldForOwnedLP_6Param_Uniswap_balancedPool() public {
        _initializeUniswapBalancedPools();
        _test6Param_uniswap(uniswapBalancedPair);
    }

    function test_calculateYieldForOwnedLP_edgeCases_Uniswap() public {
        _initializeUniswapBalancedPools();
        IUniswapV2Pair pair = uniswapBalancedPair;
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(0), pair.token0(), r0, r1);
        uint256 totalSupply = pair.totalSupply();

        // no growth
        uint256 lastK = reserveA * reserveB;
        uint256 ownedLP = totalSupply / 10;
        (uint256 lpYield5, uint256 newK) = ConstProdUtils._calculateYieldForOwnedLP(reserveA, reserveB, totalSupply, lastK, ownedLP);
        assertEq(lpYield5, 0, "no growth -> zero yield");
        assertEq(newK, reserveA * reserveB, "newK equals reserveA*reserveB");

        // zero ownedLP
        (lpYield5, newK) = ConstProdUtils._calculateYieldForOwnedLP(reserveA, reserveB, totalSupply, (reserveA*reserveB)/2, 0);
        assertEq(lpYield5, 0, "zero ownedLP -> zero yield");

        // zero total supply
        (lpYield5, newK) = ConstProdUtils._calculateYieldForOwnedLP(reserveA, reserveB, 0, (reserveA*reserveB)/2, ownedLP);
        assertEq(lpYield5, 0, "zero totalSupply -> zero yield");

        // decreased K
        (lpYield5, newK) = ConstProdUtils._calculateYieldForOwnedLP(reserveA, reserveB, totalSupply, reserveA*reserveB*2, ownedLP);
        assertEq(lpYield5, 0, "decreased K -> zero yield");
    }

    function _test5Param_uniswap(IUniswapV2Pair pair) internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(0), pair.token0(), r0, r1);
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

    function _test6Param_uniswap(IUniswapV2Pair pair) internal {
        (uint112 r0, uint112 r1,) = pair.getReserves();
        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(address(0), pair.token0(), r0, r1);
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
