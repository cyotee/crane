// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";
import {Test} from "forge-std/Test.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {ScriptBase_Crane_ERC4626} from "contracts/crane/script/ScriptBase_Crane_ERC4626.sol";
import {Script_WETH} from "contracts/crane/script/protocols/Script_WETH.sol";
import {Script_UniswapV2} from "contracts/crane/script/protocols/Script_UniswapV2.sol";
import {Script_Crane} from "contracts/crane/script/Script_Crane.sol";
import {Script_Crane_Stubs} from "contracts/crane/script/Script_Crane_Stubs.sol";
import {BetterTest} from "contracts/crane/test/BetterTest.sol";
import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";

// import { IUniswapV2Factory } from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
// import { IERC20MintBurn } from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";

abstract contract TestBase_UniswapV2 is
    CommonBase,
    ScriptBase,
    TestBase,
    StdAssertions,
    StdChains,
    StdCheatsSafe,
    StdCheats,
    StdInvariant,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories,
    ScriptBase_Crane_ERC20,
    ScriptBase_Crane_ERC4626,
    Script_WETH,
    Script_UniswapV2,
    Script_Crane,
    Script_Crane_Stubs,
    Test,
    BetterTest,
    Test_Crane
{
    function setUp() public virtual override(Test_Crane) {
        uniswapV2FeeTo(makeAddr("UniswapV2FeeCollector"));
        Test_Crane.setUp();
        // initialize();
    }

    function run()
        public
        virtual
        override(
            ScriptBase_Crane_Factories,
            ScriptBase_Crane_ERC20,
            ScriptBase_Crane_ERC4626,
            Script_WETH,
            Script_UniswapV2,
            Script_Crane,
            Script_Crane_Stubs,
            Test_Crane
        )
    {
        // Test_Crane.run();
        // Script_UniswapV2.run();
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
        console.log("recip balance", IERC20(tokenA_).balanceOf(address(recipient_)));
        deal(tokenA_, address(recipient_), amountADesired_, true);
        console.log("recip balance", IERC20(tokenA_).balanceOf(address(recipient_)));
        // IERC20MintBurn(tokenB_).mint(address(this), amountBDesired_);
        console.log("recip balance", IERC20(tokenB_).balanceOf(address(recipient_)));
        deal(tokenB_, address(recipient_), amountBDesired_, true);
        console.log("recip balance", IERC20(tokenB_).balanceOf(address(recipient_)));

        // Approve router
        IERC20(tokenA_).approve(address(uniswapV2Router()), amountADesired_);
        IERC20(tokenB_).approve(address(uniswapV2Router()), amountBDesired_);

        // Add liquidity
        (amountA, amountB, liquidity) = IUniswapV2Router(address(uniswapV2Router()))
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
