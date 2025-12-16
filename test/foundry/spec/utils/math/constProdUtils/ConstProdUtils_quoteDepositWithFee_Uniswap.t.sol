// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Uniswap} from "./TestBase_ConstProdUtils_Uniswap.sol";
import {IUniswapV2Pair} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {betterconsole as console} from "contracts/utils/vm/foundry/tools/betterconsole.sol";

contract ConstProdUtils_quoteDepositWithFee_Uniswap is TestBase_ConstProdUtils_Uniswap {
    function setUp() public override {
        super.setUp();
    }

    function _setupUniswapFees(bool enable) internal {
        if (enable) {
            vm.prank(uniswapV2FeeToSetter);
            uniswapV2Factory.setFeeTo(uniswapV2FeeToSetter);
        } else {
            vm.prank(uniswapV2FeeToSetter);
            uniswapV2Factory.setFeeTo(address(0));
        }
    }

    function _generateTradingActivity(
        IUniswapV2Pair pair,
        address tokenA,
        address tokenB,
        uint256 swapPercentage
    ) internal {
        (uint112 reserveA, uint112 reserveB,) = pair.getReserves();

        uint256 swapAmountA = (uint256(reserveA) * swapPercentage) / 10000;
        uint256 swapAmountB = (uint256(reserveB) * swapPercentage) / 10000;

        deal(tokenA, address(this), swapAmountA, true);
        deal(tokenB, address(this), swapAmountB, true);

        IERC20(tokenA).approve(address(uniswapV2Router), swapAmountA);
        address[] memory pathAB = new address[](2);
        pathAB[0] = tokenA;
        pathAB[1] = tokenB;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            1,
            pathAB,
            address(this),
            block.timestamp
        );

        uint256 receivedB = IERC20(tokenB).balanceOf(address(this));
        IERC20(tokenB).approve(address(uniswapV2Router), receivedB);
        address[] memory pathBA = new address[](2);
        pathBA[0] = tokenB;
        pathBA[1] = tokenA;

        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            receivedB,
            1,
            pathBA,
            address(this),
            block.timestamp
        );
    }

    function _testUniswapQuoteDepositWithFee(
        IUniswapV2Pair pair,
        IERC20 tokenA,
        IERC20 tokenB,
        uint256 amountA,
        uint256 amountB,
        bool feesEnabled
    ) internal {
        console.log("=== Testing Uniswap V2 ===");

        (uint112 r0, uint112 r1,) = pair.getReserves();
        uint256 totalSupply = pair.totalSupply();

        (uint256 reserveA, uint256 reserveB) = ConstProdUtils._sortReserves(
            address(tokenA),
            pair.token0(),
            r0,
            r1
        );

        uint256 kLast = pair.kLast();

        uint256 quoted = ConstProdUtils._quoteDepositWithFee(
            amountA,
            amountB,
            totalSupply,
            reserveA,
            reserveB,
            kLast,
            0,
            feesEnabled
        );

        console.log("Quoted LP:", quoted);

        // Prepare pool for actual deposit

        // Mint and approve tokens
        ERC20PermitMintableStub(address(tokenA)).mint(address(this), amountA);
        ERC20PermitMintableStub(address(tokenB)).mint(address(this), amountB);
        tokenA.approve(address(uniswapV2Router), amountA);
        tokenB.approve(address(uniswapV2Router), amountB);

        // Execute addLiquidity
        (, , uint256 actualLPTokens) = uniswapV2Router.addLiquidity(
            address(tokenA),
            address(tokenB),
            amountA,
            amountB,
            1,
            1,
            address(this),
            block.timestamp
        );

        assertEq(quoted, actualLPTokens, "Quoted LP should match actual LP tokens");
    }

    function test_quoteDepositWithFee_Uniswap_balancedPool_feesDisabled() public {
        _initializeUniswapBalancedPools();
        _setupUniswapFees(false);
        _testUniswapQuoteDepositWithFee(
            uniswapBalancedPair,
            ERC20PermitMintableStub(address(uniswapBalancedTokenA)),
            ERC20PermitMintableStub(address(uniswapBalancedTokenB)),
            1000e18,
            1000e18,
            false
        );
    }

    function test_quoteDepositWithFee_Uniswap_balancedPool_feesEnabled() public {
        _initializeUniswapBalancedPools();
        _setupUniswapFees(true);
        _generateTradingActivity(uniswapBalancedPair, address(uniswapBalancedTokenA), address(uniswapBalancedTokenB), 100);
        _testUniswapQuoteDepositWithFee(
            uniswapBalancedPair,
            ERC20PermitMintableStub(address(uniswapBalancedTokenA)),
            ERC20PermitMintableStub(address(uniswapBalancedTokenB)),
            1000e18,
            1000e18,
            true
        );
    }

    function test_quoteDepositWithFee_Uniswap_zeroAmounts() public {
        _initializeUniswapBalancedPools();
        _setupUniswapFees(false);
        uint256 quoted = ConstProdUtils._quoteDepositWithFee(
            0,
            0,
            uniswapBalancedPair.totalSupply(),
            uint256(10000000000000000000000),
            uint256(10000000000000000000000),
            uniswapBalancedPair.kLast(),
            0,
            false
        );
        assertEq(quoted, 0, "Zero amounts should quote zero LP");
    }

    function test_quoteDepositWithFee_Uniswap_verySmallAmounts() public {
        _initializeUniswapBalancedPools();
        _setupUniswapFees(false);
        uint256 quoted = ConstProdUtils._quoteDepositWithFee(
            1,
            1,
            uniswapBalancedPair.totalSupply(),
            uint256(10000000000000000000000),
            uint256(10000000000000000000000),
            uniswapBalancedPair.kLast(),
            0,
            false
        );
        assertTrue(quoted > 0, "Very small amounts should produce LP tokens");
    }
}
