// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";
import {IRouter} from "contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_quoteZapOutToTargetWithFee_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    uint256 constant PERCENTAGE_1_PCT = 100; // 1%
    uint256 constant PERCENTAGE_5_PCT = 500; // 5%
    uint256 constant PERCENTAGE_10_PCT = 1000; // 10%
    uint256 constant PERCENTAGE_25_PCT = 2500; // 25%

    function setUp() public override {
        super.setUp();
    }

    function test_quoteZapOutToTargetWithFee_Aerodrome_balancedPool_targetTokenA_1pct() public {
        _testZapOutToTargetWithFeePercentage(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB, false, PERCENTAGE_1_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Aerodrome_balancedPool_targetTokenA_5pct_feesEnabled() public {
        _testZapOutToTargetWithFeePercentage(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB, true, PERCENTAGE_5_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Aerodrome_balancedPool_targetTokenB_10pct() public {
        _testZapOutToTargetWithFeePercentage(aeroBalancedPool, aeroBalancedTokenB, aeroBalancedTokenA, false, PERCENTAGE_10_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Aerodrome_balancedPool_targetTokenB_25pct_feesEnabled() public {
        _testZapOutToTargetWithFeePercentage(aeroBalancedPool, aeroBalancedTokenB, aeroBalancedTokenA, true, PERCENTAGE_25_PCT);
    }

    function test_quoteZapOutToTargetWithFee_Aerodrome_balancedPool_impossible_scenarios() public {
        _testZapOutToTargetWithFeeImpossible(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB, false);
        _testZapOutToTargetWithFeeImpossible(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB, true);
    }

    function _testZapOutToTargetWithFeePercentage(
        Pool pair,
        ERC20PermitMintableStub targetToken,
        ERC20PermitMintableStub saleToken,
        bool feesEnabled,
        uint256 percentage
    ) internal {
        _initializeAerodromeBalancedPools();
        // Generate trading activity to accrue protocol fees before quoting
        // so the fee-enabled paths mirror on-chain behavior.
        _executeAerodromeTradesToGenerateFees(targetToken, saleToken);

        (uint256 r0, uint256 r1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        (uint256 reserveTarget, uint256 reserveSale) = ConstProdUtils._sortReserves(address(targetToken), pair.token0(), r0, r1);

        uint256 desiredOut = (reserveTarget * percentage) / 10000;
        if (desiredOut > reserveTarget) desiredOut = reserveTarget;

        uint256 feePercent = aerodromePoolFactory.getFee(address(pair), false);

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: desiredOut,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveTarget,
            reserveOther: reserveSale,
            feePercent: feePercent,
            feeDenominator: 10000,
            kLast: 0,
            ownerFeeShare: 0,
            feeOn: feesEnabled,
            protocolFeeDenominator: 10000
        });

        uint256 quotedLpAmt = ConstProdUtils._quoteZapOutToTargetWithFee(args);
        assertTrue(quotedLpAmt > 0, "Quoted LP amount should be positive");
        assertTrue(quotedLpAmt <= totalSupply, "Quoted LP amount should not exceed total supply");

        uint256 balBefore = targetToken.balanceOf(address(this));
        pair.transfer(address(pair), quotedLpAmt);
        (uint256 a0, uint256 a1) = pair.burn(address(this));
        uint256 saleAmount;
        address token0 = pair.token0();
        if (address(targetToken) == token0) {
            saleAmount = a1;
        } else {
            saleAmount = a0;
        }
        if (saleAmount > 0) {
            address tokenFrom = pair.token0() == address(targetToken) ? pair.token1() : pair.token0();
            IERC20(tokenFrom).approve(address(aerodromeRouter), saleAmount);
            IRouter.Route[] memory routes = new IRouter.Route[](1);
            routes[0] = IRouter.Route({from: tokenFrom, to: address(targetToken), stable: false, factory: address(aerodromePoolFactory)});
            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(saleAmount, 1, routes, address(this), block.timestamp);
        }

        uint256 balAfter = targetToken.balanceOf(address(this));
        uint256 actualReceived = balAfter - balBefore;
        assertTrue(actualReceived >= desiredOut, "received >= desiredOut");
    }

    function _testZapOutToTargetWithFeeImpossible(
        Pool pair,
        ERC20PermitMintableStub targetToken,
        ERC20PermitMintableStub saleToken,
        bool feesEnabled
    ) internal {
        _initializeAerodromeBalancedPools();

        (uint256 r0, uint256 r1, ) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();
        uint256 kLast = 0;
        (uint256 reserveTarget, uint256 reserveSale) = ConstProdUtils._sortReserves(address(targetToken), pair.token0(), r0, r1);

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args1 = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: reserveTarget + 1,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveTarget,
            reserveOther: reserveSale,
            feePercent: 500,
            feeDenominator: 10000,
            kLast: kLast,
            ownerFeeShare: 0,
            feeOn: feesEnabled,
            protocolFeeDenominator: 10000
        });
        uint256 quoted1 = ConstProdUtils._quoteZapOutToTargetWithFee(args1);
        assertEq(quoted1, 0, "Should return 0 when desired output exceeds reserves");

        ConstProdUtils.ZapOutToTargetWithFeeArgs memory args2 = ConstProdUtils.ZapOutToTargetWithFeeArgs({
            desiredOut: 0,
            lpTotalSupply: totalSupply,
            reserveDesired: reserveTarget,
            reserveOther: reserveSale,
            feePercent: 500,
            feeDenominator: 10000,
            kLast: kLast,
            ownerFeeShare: 0,
            feeOn: feesEnabled,
            protocolFeeDenominator: 10000
        });
        uint256 quoted2 = ConstProdUtils._quoteZapOutToTargetWithFee(args2);
        assertEq(quoted2, 0, "Should return 0 when desired output is 0");

        uint256 maxPossibleOutput = reserveTarget;
        if (maxPossibleOutput > 0) {
            ConstProdUtils.ZapOutToTargetWithFeeArgs memory args3 = ConstProdUtils.ZapOutToTargetWithFeeArgs({
                desiredOut: maxPossibleOutput + 1,
                lpTotalSupply: totalSupply,
                reserveDesired: reserveTarget,
                reserveOther: reserveSale,
                feePercent: 500,
                feeDenominator: 10000,
                kLast: kLast,
                ownerFeeShare: 0,
                feeOn: feesEnabled,
                protocolFeeDenominator: 10000
            });
            uint256 quoted3 = ConstProdUtils._quoteZapOutToTargetWithFee(args3);
            assertEq(quoted3, 0, "Should return 0 when desired output exceeds maximum possible");
        }
    }
}
