// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";
// import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
import {TestBase_UniswapV2} from "contracts/crane/test/bases/protocols/TestBase_UniswapV2.sol";
import {IOwnableStorage} from 
// OwnableStorage
"contracts/crane/access/ownable/utils/OwnableStorage.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {UniswapV2Service} from "contracts/crane/protocols/dexes/uniswap/v2/utils/UniswapV2Service.sol";
import {IUniswapV2Pair} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
// import {IUniswapV2Factory} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
// import {IUniswapV2Router02} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {IUniswapV2Router} from "contracts/crane/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IERC20MintBurnOperableStorage} from 
// ERC20MintBurnOperableStorage
"contracts/crane/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";

/**
 * @title UniswapV2Service_withdrawDirectTest
 * @dev Test suite for the _withdrawDirect function of UniswapV2Service
 */
contract UniswapV2Service_withdrawDirectTest is TestBase_UniswapV2 {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    IUniswapV2Pair pool;
    uint256 depositAmount = TENK_WAD;

    function setUp() public virtual override {
        super.setUp();

        IOwnableStorage.OwnableAccountInit memory globalOwnableAccountInit;
        globalOwnableAccountInit.owner = address(this);

        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenAInit;
        tokenAInit.ownableAccountInit = globalOwnableAccountInit;
        tokenAInit.name = "TokenA";
        tokenAInit.symbol = tokenAInit.name;
        tokenAInit.decimals = 18;

        tokenA = IERC20MintBurn(diamondFactory().deploy(erc20MintBurnPkg(), abi.encode(tokenAInit)));
        vm.label(address(tokenA), "TokenA");

        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenBInit;
        tokenBInit.ownableAccountInit = globalOwnableAccountInit;
        tokenBInit.name = "TokenB";
        tokenBInit.symbol = tokenBInit.name;
        tokenBInit.decimals = 18;

        tokenB = IERC20MintBurn(diamondFactory().deploy(erc20MintBurnPkg(), abi.encode(tokenBInit)));
        vm.label(address(tokenB), "TokenB");

        pool = uniswapV2Pair(tokenA, tokenB);
        vm.label(
            address(pool),
            string.concat(
                pool.symbol(), " - ", IERC20(address(tokenA)).symbol(), " / ", IERC20(address(tokenB)).symbol()
            )
        );

        // Initialize pool with liquidity
        tokenA.mint(address(this), depositAmount);
        tokenA.approve(address(uniswapV2Router()), depositAmount);
        tokenB.mint(address(this), depositAmount);
        tokenB.approve(address(uniswapV2Router()), depositAmount);

        UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())), tokenA, tokenB, depositAmount, depositAmount
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                        Withdraw Direct Tests                           */
    /* ---------------------------------------------------------------------- */

    function test_withdrawDirect_fullAmount() public {
        uint256 lpBalance = pool.balanceOf(address(this));

        // Get initial token balances
        uint256 initialTokenABalance = tokenA.balanceOf(address(this));
        uint256 initialTokenBBalance = tokenB.balanceOf(address(this));

        console.log("LP balance before withdraw:", lpBalance);
        console.log("TokenA balance before:", initialTokenABalance);
        console.log("TokenB balance before:", initialTokenBBalance);

        // Withdraw all LP tokens
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(pool, lpBalance);

        console.log("Amount0 received:", amount0);
        console.log("Amount1 received:", amount1);
        console.log("TokenA balance after:", tokenA.balanceOf(address(this)));
        console.log("TokenB balance after:", tokenB.balanceOf(address(this)));
        console.log("LP balance after:", pool.balanceOf(address(this)));
    }

    function test_withdrawDirect_partialAmount() public {
        uint256 lpBalance = pool.balanceOf(address(this));
        uint256 withdrawAmount = lpBalance / 2; // Withdraw half

        // Get initial token balances
        uint256 initialTokenABalance = tokenA.balanceOf(address(this));
        uint256 initialTokenBBalance = tokenB.balanceOf(address(this));

        console.log("LP balance before withdraw:", lpBalance);
        console.log("Withdraw amount:", withdrawAmount);
        console.log("TokenA balance before:", initialTokenABalance);
        console.log("TokenB balance before:", initialTokenBBalance);

        // Withdraw partial LP tokens
        (uint256 amount0, uint256 amount1) = UniswapV2Service._withdrawDirect(pool, withdrawAmount);

        console.log("Amount0 received:", amount0);
        console.log("Amount1 received:", amount1);
        console.log("TokenA balance after:", tokenA.balanceOf(address(this)));
        console.log("TokenB balance after:", tokenB.balanceOf(address(this)));
        console.log("LP balance after:", pool.balanceOf(address(this)));
    }

    function test_withdrawDirect_calculateExpectedAmounts() public view {
        uint256 lpBalance = pool.balanceOf(address(this));
        uint256 withdrawAmount = lpBalance / 4; // Withdraw quarter

        // Get current reserves
        (uint112 reserve0, uint112 reserve1,) = pool.getReserves();
        uint256 totalSupply = pool.totalSupply();

        // Calculate expected amounts using ConstProdUtils
        (uint256 expectedAmount0, uint256 expectedAmount1) =
            ConstProdUtils._withdrawQuote(withdrawAmount, totalSupply, uint256(reserve0), uint256(reserve1));

        console.log("Withdraw amount:", withdrawAmount);
        console.log("Total supply:", totalSupply);
        console.log("Reserve0:", uint256(reserve0));
        console.log("Reserve1:", uint256(reserve1));
        console.log("Expected amount0:", expectedAmount0);
        console.log("Expected amount1:", expectedAmount1);
    }
}
