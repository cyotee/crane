// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

// import {IWETH} from "@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol";
import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV2Router} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IERC20PermitProxy} from "@crane/contracts/interfaces/proxies/IERC20PermitProxy.sol";
import {ConstProdUtils} from "@crane/contracts/utils/math/ConstProdUtils.sol";
import {UniV2Factory} from "@crane/contracts/protocols/dexes/uniswap/v2/UniV2Factory.sol";
import {UniV2Router02} from "@crane/contracts/protocols/dexes/uniswap/v2/UniV2Router02.sol";
// import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";
import {TestBase_Weth9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/TestBase_Weth9.sol";

abstract contract TestBase_UniswapV2 is TestBase_Weth9 {

    address uniswapV2FeeToSetter;

    IUniswapV2Factory internal uniswapV2Factory;
    IUniswapV2Router internal uniswapV2Router;

    function setUp() public virtual override {
        uniswapV2FeeToSetter = makeAddr("uniswapV2FeeToSetter");
        TestBase_Weth9.setUp();
        if (address(uniswapV2Factory) == address(0)) {
            uniswapV2Factory = new UniV2Factory(uniswapV2FeeToSetter);
        }

        if (address(uniswapV2Router) == address(0)) {
            uniswapV2Router = new UniV2Router02(
                address(uniswapV2Factory),
                address(weth)
            );
        }
    }

    function sortedReserves(address tokenA_, IUniswapV2Pair pair_)
        internal
        view
        returns (uint256 reserveA, uint256 reserveB)
    {
        (uint112 reserve0, uint112 reserve1,) = pair_.getReserves();
        address token0 = pair_.token0();

        (reserveA, reserveB) = ConstProdUtils._sortReserves(tokenA_, token0, reserve0, reserve1);
    }

    /**
     * @notice Add balanced liquidity to a Uniswap V2 pool for strategy vault testing.
     * @dev Specify either amountADesired or amountBDesired (or both). If one is zero, the function computes the required amount for a balanced deposit using ConstProdUtils.
     * @param tokenA_ Address of token A
     * @param tokenB_ Address of token B
     * @param amountADesired_ Desired amount of token A (set to 0 if basing on token B)
     * @param amountBDesired_ Desired amount of token B (set to 0 if basing on token A)
     * @param recipient_ Address to receive the LP tokens
     * @return amountA Actual amount of token A deposited
     * @return amountB Actual amount of token B deposited
     * @return liquidity Amount of LP tokens minted
     *
     * Example usage:
     * (amountA, amountB, liquidity) = addBalancedUniswapLiquidity(address(tokenA), address(tokenB), 10_000e18, 0, address(this));
     */
    function addBalancedUniswapLiquidity(
        IUniswapV2Pair pair_,
        address tokenA_,
        address tokenB_,
        uint256 amountADesired_,
        uint256 amountBDesired_,
        address recipient_
    ) public virtual returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountADesired_ > 0 || amountBDesired_ > 0, "Must provide at least one nonzero amount");
        require(tokenA_ != address(0) && tokenB_ != address(0), "Token addresses required");

        (uint256 reserveA, uint256 reserveB) = sortedReserves(tokenA_, pair_);

        // Compute missing amount if needed
        if (amountADesired_ == 0) {
            amountADesired_ = ConstProdUtils._equivLiquidity(amountBDesired_, reserveB, reserveA);
        } else if (amountBDesired_ == 0) {
            amountBDesired_ = ConstProdUtils._equivLiquidity(amountADesired_, reserveA, reserveB);
        }

        // Mint/allocate tokens to this contract for testing
        // IERC20MintBurn(tokenA_).mint(address(this), amountADesired_);
        console.log("recip balance", IERC20PermitProxy(tokenA_).balanceOf(address(recipient_)));
        deal(tokenA_, address(recipient_), amountADesired_, true);
        console.log("recip balance", IERC20PermitProxy(tokenA_).balanceOf(address(recipient_)));
        // IERC20MintBurn(tokenB_).mint(address(this), amountBDesired_);
        console.log("recip balance", IERC20PermitProxy(tokenB_).balanceOf(address(recipient_)));
        deal(tokenB_, address(recipient_), amountBDesired_, true);
        console.log("recip balance", IERC20PermitProxy(tokenB_).balanceOf(address(recipient_)));

        // Approve router
        IERC20PermitProxy(tokenA_).approve(address(uniswapV2Router), amountADesired_);
        IERC20PermitProxy(tokenB_).approve(address(uniswapV2Router), amountBDesired_);

        // Add liquidity
        (amountA, amountB, liquidity) = uniswapV2Router
            .addLiquidity(
                tokenA_,
                tokenB_,
                amountADesired_,
                amountBDesired_,
                amountADesired_ * 95 / 100, // min amounts (5% slippage)
                amountBDesired_ * 95 / 100,
                recipient_,
                block.timestamp + 300
            );
    }
}