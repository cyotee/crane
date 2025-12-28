// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "test/foundry/spec/utils/math/constProdUtils/TestBase_ConstProdUtils_Aerodrome.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";

contract ConstProdUtils_quoteWithdrawWithFee_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    function setUp() public override {
        TestBase_ConstProdUtils_Aerodrome.setUp();
    }

    function _quotedWithdrawForPair(Pool pair, address tokenA) internal view returns (uint256 quotedA, uint256 quotedB) {
        uint256 lpReceived = pair.balanceOf(address(this));
        if (lpReceived == 0) return (0, 0);

        (uint256 r0, uint256 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            tokenA, 
            pair.token0(), 
            r0, 
            r1 
        );

        // Aerodrome doesn't expose kLast / ownerFee in the same way; pass zeros
        uint256 kLast = 0;
        uint256 ownerFeeShare = 0;

        (quotedA, quotedB) = ConstProdUtils._quoteWithdrawWithFee(
            lpReceived,
            totalSupply,
            reserveA,
            reserveB,
            kLast,
            ownerFeeShare,
            false
        );
    }

    function test_quoteWithdrawWithFee_Aerodrome_balanced_simple() public {
        _initializeAerodromeBalancedPools();
        Pool pair = aeroBalancedPool;

        uint256 lpReceived = pair.balanceOf(address(this));
        assertTrue(lpReceived > 0, "got lp");

        // generate trading activity so protocol fee paths can run
        _executeAerodromeTradesToGenerateFees(aeroBalancedTokenA, aeroBalancedTokenB);

        (uint256 quotedA, uint256 quotedB) = _quotedWithdrawForPair(pair, address(aeroBalancedTokenA));

        uint256 beforeA = aeroBalancedTokenA.balanceOf(address(this));
        uint256 beforeB = aeroBalancedTokenB.balanceOf(address(this));

        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));

        uint256 afterA = aeroBalancedTokenA.balanceOf(address(this));
        uint256 afterB = aeroBalancedTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    function test_quoteWithdrawWithFee_Aerodrome_unbalanced_simple() public {
        _initializeAerodromeUnbalancedPools();
        Pool pair = aeroUnbalancedPool;

        uint256 lpReceived = pair.balanceOf(address(this));
        assertTrue(lpReceived > 0, "got lp");

        // generate trading activity so protocol fee paths can run
        _executeAerodromeTradesToGenerateFees(aeroUnbalancedTokenA, aeroUnbalancedTokenB);

        (uint256 quotedA, uint256 quotedB) = _quotedWithdrawForPair(pair, address(aeroUnbalancedTokenA));

        uint256 beforeA = aeroUnbalancedTokenA.balanceOf(address(this));
        uint256 beforeB = aeroUnbalancedTokenB.balanceOf(address(this));

        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));

        uint256 afterA = aeroUnbalancedTokenA.balanceOf(address(this));
        uint256 afterB = aeroUnbalancedTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }

    function test_quoteWithdrawWithFee_Aerodrome_extreme_unbalanced_simple() public {
        _initializeAerodromeExtremeUnbalancedPools();
        Pool pair = aeroExtremeUnbalancedPool;

        uint256 lpReceived = pair.balanceOf(address(this));
        assertTrue(lpReceived > 0, "got lp");

        // generate trading activity so protocol fee paths can run
        _executeAerodromeTradesToGenerateFees(aeroExtremeTokenA, aeroExtremeTokenB);

        (uint256 quotedA, uint256 quotedB) = _quotedWithdrawForPair(pair, address(aeroExtremeTokenA));

        uint256 beforeA = aeroExtremeTokenA.balanceOf(address(this));
        uint256 beforeB = aeroExtremeTokenB.balanceOf(address(this));

        pair.transfer(address(pair), lpReceived);
        (uint256 a0, uint256 a1) = pair.burn(address(this));

        uint256 afterA = aeroExtremeTokenA.balanceOf(address(this));
        uint256 afterB = aeroExtremeTokenB.balanceOf(address(this));

        uint256 actualA = afterA - beforeA;
        uint256 actualB = afterB - beforeB;

        assertEq(quotedA, actualA, "quotedA == actualA");
        assertEq(quotedB, actualB, "quotedB == actualB");
    }
}
