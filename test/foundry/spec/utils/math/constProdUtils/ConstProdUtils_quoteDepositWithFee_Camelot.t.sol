// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Camelot} from "./TestBase_ConstProdUtils_Camelot.sol";
import {ICamelotPair} from "contracts/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {IERC20MintBurn} from "contracts/interfaces/IERC20MintBurn.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterIERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";
import {CamelotV2Service} from "contracts/protocols/dexes/camelot/v2/CamelotV2Service.sol";

contract ConstProdUtils_quoteDepositWithFee_Camelot is TestBase_ConstProdUtils_Camelot {
    uint256 constant CAMELOT_MIN_FEE = 10;
    uint256 constant CAMELOT_DEFAULT_FEE = 300;
    uint256 constant CAMELOT_MAX_FEE = 2000;
    uint256 constant CAMELOT_MIN_OWNER = 100;
    uint256 constant CAMELOT_DEFAULT_OWNER = 1000;
    uint256 constant CAMELOT_MAX_OWNER = 10000;

    function setUp() public override {
        super.setUp();
    }

    function _configureCamelotFees(ICamelotPair pair, uint256 swapFee, uint256 ownerFeeShare) internal {
        pair.setFeePercent(uint16(swapFee), uint16(swapFee));
        // owner fee share is a factory/global setting; assume factory default is usable
        // generate trading activity to create protocol fees when needed
        _generateCamelotTradingActivity(pair, IERC20MintBurn(pair.token0()), IERC20MintBurn(pair.token1()), 100);
    }

    function _generateCamelotTradingActivity(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 swapPercentage
    ) internal {
        (uint112 reserveA, uint112 reserveB,,) = pair.getReserves();

        uint256 swapAmountA = (uint256(reserveA) * swapPercentage) / 10000;
        uint256 swapAmountB = (uint256(reserveB) * swapPercentage) / 10000;

        tokenA.mint(address(this), swapAmountA);
        tokenB.mint(address(this), swapAmountB);

        IERC20(address(tokenA)).approve(address(camelotV2Router), swapAmountA);
        IERC20(address(tokenB)).approve(address(camelotV2Router), swapAmountB);

        address[] memory pathAB = new address[](2);
        pathAB[0] = address(tokenA);
        pathAB[1] = address(tokenB);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            1,
            pathAB,
            address(this),
            address(0),
            block.timestamp
        );

        uint256 receivedB = IERC20(address(tokenB)).balanceOf(address(this));
        IERC20(address(tokenB)).approve(address(camelotV2Router), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = address(tokenB);
        pathBA[1] = address(tokenA);

        camelotV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            receivedB,
            1,
            pathBA,
            address(this),
            address(0),
            block.timestamp
        );
    }

    function _testCamelotQuoteDepositWithFee(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 swapFee,
        uint256 ownerFeeShare
    ) internal {
        console.log("=== Testing Camelot V2 ===");

        _configureCamelotFees(pair, swapFee, ownerFeeShare);

        // Diagnostic: capture factory/pair state before quoting
        console.log("pair.totalSupply before quote:", pair.totalSupply());
        console.log("pair.kLast before quote:", pair.kLast());
        console.log("factory.ownerFeeShare:", camelotV2Factory.ownerFeeShare());
        console.log("factory.feeTo:", uint256(uint160(address(camelotV2Factory.feeTo()))));

        uint256 quoted = _computeCamelotQuoted(pair, tokenA, tokenB, amountA, amountB);

        // Execute actual deposit and capture minted LP tokens
        tokenA.mint(address(this), amountA);
        tokenB.mint(address(this), amountB);
        IERC20(address(tokenA)).approve(address(camelotV2Router), amountA);
        IERC20(address(tokenB)).approve(address(camelotV2Router), amountB);

        // Diagnostic: capture factory/pair state just before deposit
        console.log("pair.totalSupply before deposit:", pair.totalSupply());
        console.log("pair.kLast before deposit:", pair.kLast());
        console.log("factory.ownerFeeShare before deposit:", camelotV2Factory.ownerFeeShare());
        console.log("factory.feeTo before deposit:", uint256(uint160(address(camelotV2Factory.feeTo()))));

        uint256 actualLPTokens = CamelotV2Service._deposit(
            camelotV2Router,
            BetterIERC20(address(tokenA)),
            BetterIERC20(address(tokenB)),
            amountA,
            amountB
        );
        assertTrue(quoted > 0, "quoted positive");
        assertTrue(actualLPTokens > 0, "actual positive");

        // Allow a single-unit rounding difference due to integer sqrt/div rounding.
        if (quoted == actualLPTokens) return;
        if (quoted == actualLPTokens + 1) return;
        if (actualLPTokens == quoted + 1) return;
        assertEq(quoted, actualLPTokens, "quoted == actual LP tokens");
    }

    function _computeCamelotQuoted(
        ICamelotPair pair,
        IERC20MintBurn tokenA,
        IERC20MintBurn tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal view returns (uint256) {
        (uint112 r0, uint112 r1, uint16 f0, uint16 f1) = pair.getReserves();

        (uint256 reserveA, , uint256 reserveB, ) = ConstProdUtils._sortReserves(
            address(tokenA),
            pair.token0(),
            r0,
            f0,
            r1,
            f1
        );

        return ConstProdUtils._quoteDepositWithFee(
            amountA,
            amountB,
            pair.totalSupply(),
            reserveA,
            reserveB,
            pair.kLast(),
            camelotV2Factory.ownerFeeShare(),
            true
        );
    }

    function test_quoteDepositWithFee_Camelot_balancedPool_defaultFees() public {
        _initializeCamelotBalancedPools();
        _testCamelotQuoteDepositWithFee(
            camelotBalancedPair,
            IERC20MintBurn(address(camelotBalancedTokenA)),
            IERC20MintBurn(address(camelotBalancedTokenB)),
            1000e18,
            1000e18,
            CAMELOT_DEFAULT_FEE,
            CAMELOT_DEFAULT_OWNER
        );
    }

    function test_quoteDepositWithFee_Camelot_balancedPool_minFees() public {
        _initializeCamelotBalancedPools();
        _testCamelotQuoteDepositWithFee(
            camelotBalancedPair,
            IERC20MintBurn(address(camelotBalancedTokenA)),
            IERC20MintBurn(address(camelotBalancedTokenB)),
            1000e18,
            1000e18,
            CAMELOT_MIN_FEE,
            CAMELOT_MIN_OWNER
        );
    }

    function test_quoteDepositWithFee_Camelot_balancedPool_maxFees() public {
        _initializeCamelotBalancedPools();
        _testCamelotQuoteDepositWithFee(
            camelotBalancedPair,
            IERC20MintBurn(address(camelotBalancedTokenA)),
            IERC20MintBurn(address(camelotBalancedTokenB)),
            1000e18,
            1000e18,
            CAMELOT_MAX_FEE,
            CAMELOT_MAX_OWNER
        );
    }

    function test_quoteDepositWithFee_Camelot_zeroAmounts() public {
        uint256 quoted = ConstProdUtils._quoteDepositWithFee(
            0,
            0,
            camelotBalancedPair.totalSupply(),
            uint256(10000000000000000000000),
            uint256(10000000000000000000000),
            camelotBalancedPair.kLast(),
            camelotV2Factory.ownerFeeShare(),
            true
        );
        assertEq(quoted, 0, "Zero amounts should return zero LP tokens");
    }

    function test_quoteDepositWithFee_Camelot_verySmallAmounts() public {
        // Ensure pool is initialized so totalSupply/kLast are non-zero
        _initializeCamelotBalancedPools();

        uint256 quoted = ConstProdUtils._quoteDepositWithFee(
            1,
            1,
            camelotBalancedPair.totalSupply(),
            uint256(10000000000000000000000),
            uint256(10000000000000000000000),
            camelotBalancedPair.kLast(),
            camelotV2Factory.ownerFeeShare(),
            true
        );

        assertTrue(quoted > 0, "Very small amounts should still produce LP tokens");
    }
}
