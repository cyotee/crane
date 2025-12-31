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
 * @title UniswapV2Service_swapDepositTest
 * @dev Test suite for the _swapDeposit function of UniswapV2Service
 */
contract UniswapV2Service_swapDepositTest is TestBase_UniswapV2 {
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
    /*                        Swap Deposit Tests                              */
    /* ---------------------------------------------------------------------- */

    function test_swapDeposit_singleToken() public {
        uint256 saleAmt = FIVEK_WAD;

        // Mint only tokenA for swap deposit
        tokenA.mint(address(this), saleAmt);
        tokenA.approve(address(uniswapV2Router()), saleAmt);

        // Get initial LP balance
        // uint256 initialLPBalance = pool.balanceOf(address(this));

        // Perform swap deposit
        uint256 lpTokens =
            UniswapV2Service._swapDeposit(IUniswapV2Router(address(uniswapV2Router())), pool, tokenA, saleAmt, tokenB);

        console.log("LP tokens received from swap deposit:", lpTokens);
        console.log("Total LP balance:", pool.balanceOf(address(this)));
        console.log("TokenA balance after:", tokenA.balanceOf(address(this)));
        console.log("TokenB balance after:", tokenB.balanceOf(address(this)));
    }

    function test_swapDeposit_tokenB() public {
        uint256 saleAmt = FIVEK_WAD;

        // Mint only tokenB for swap deposit
        tokenB.mint(address(this), saleAmt);
        tokenB.approve(address(uniswapV2Router()), saleAmt);

        // Get initial LP balance
        // uint256 initialLPBalance = pool.balanceOf(address(this));

        // Perform swap deposit (swapping tokenB for tokenA)
        uint256 lpTokens =
            UniswapV2Service._swapDeposit(IUniswapV2Router(address(uniswapV2Router())), pool, tokenB, saleAmt, tokenA);

        console.log("LP tokens received from swap deposit:", lpTokens);
        console.log("Total LP balance:", pool.balanceOf(address(this)));
        console.log("TokenA balance after:", tokenA.balanceOf(address(this)));
        console.log("TokenB balance after:", tokenB.balanceOf(address(this)));
    }

    function test_swapDeposit_calculateOptimalSplit() public view {
        uint256 saleAmt = FIVEK_WAD;

        // Get current reserves
        UniswapV2Service.ReserveInfo memory reserves = UniswapV2Service._sortReserves(pool, tokenA);

        // Calculate expected swap amount for optimal deposit
        uint256 expectedSwapAmount =
            ConstProdUtils._swapDepositSaleAmt(saleAmt, reserves.knownReserve, reserves.feePercent);

        console.log("Sale amount:", saleAmt);
        console.log("Expected swap amount:", expectedSwapAmount);
        console.log("Expected remaining for deposit:", saleAmt - expectedSwapAmount);
        console.log("Reserve in:", reserves.knownReserve);
        console.log("Reserve out:", reserves.opposingReserve);
    }
}
