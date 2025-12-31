// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";
// import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
import {TestBase_UniswapV2} from "contracts/crane/test/bases/protocols/TestBase_UniswapV2.sol";
import {IOwnableStorage} from 
// OwnableStorage
"contracts/crane/access/ownable/utils/OwnableStorage.sol";
// import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
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
 * @title UniswapV2Service_swapTest
 * @dev Test suite for the _swap function variants of UniswapV2Service
 */
contract UniswapV2Service_swapTest is TestBase_UniswapV2 {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    IUniswapV2Pair pool;
    uint256 depositAmount = TENK_WAD;
    uint256 swapAmount = ONE_WAD;

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

    function test_swap_viaPair() public {
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router()), swapAmount);

        uint256 beforeBalanceB = tokenB.balanceOf(address(this));

        uint256 amountOut =
            UniswapV2Service._swap(IUniswapV2Router(address(uniswapV2Router())), pool, swapAmount, tokenA, tokenB);

        require(amountOut > 0, "Swap should produce non-zero output");
        require(
            tokenB.balanceOf(address(this)) == beforeBalanceB + amountOut, "TokenB balance increase should match output"
        );
    }

    function test_swapExactTokensForTokens() public {
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(uniswapV2Router()), swapAmount);

        uint256 beforeBalanceB = tokenB.balanceOf(address(this));

        uint256 amountOut = UniswapV2Service._swapExactTokensForTokens(
            IUniswapV2Router(address(uniswapV2Router())), tokenA, swapAmount, tokenB, 1, address(this)
        );

        require(amountOut > 0, "Swap should produce non-zero output");
        require(
            tokenB.balanceOf(address(this)) == beforeBalanceB + amountOut, "TokenB balance increase should match output"
        );
    }
}
