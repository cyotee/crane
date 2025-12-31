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
 * @title UniswapV2Service_depositTest
 * @dev Test suite for the _deposit function of UniswapV2Service
 */
contract UniswapV2Service_depositTest is TestBase_UniswapV2 {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    IUniswapV2Pair pool;

    function setUp() public virtual override {
        // No forking - use local deployment
        super.setUp();

        // Initialize token owner
        IOwnableStorage.OwnableAccountInit memory globalOwnableAccountInit;
        globalOwnableAccountInit.owner = address(this);

        // Create TokenA
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenAInit;
        tokenAInit.ownableAccountInit = globalOwnableAccountInit;
        tokenAInit.name = "TokenA";
        tokenAInit.symbol = tokenAInit.name;
        tokenAInit.decimals = 18;

        tokenA = IERC20MintBurn(diamondFactory().deploy(erc20MintBurnPkg(), abi.encode(tokenAInit)));
        vm.label(address(tokenA), "TokenA");

        // Create TokenB
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenBInit;
        tokenBInit.ownableAccountInit = globalOwnableAccountInit;
        tokenBInit.name = "TokenB";
        tokenBInit.symbol = tokenBInit.name;
        tokenBInit.decimals = 18;

        tokenB = IERC20MintBurn(diamondFactory().deploy(erc20MintBurnPkg(), abi.encode(tokenBInit)));
        vm.label(address(tokenB), "TokenB");

        // Create pool using fixture
        pool = uniswapV2Pair(tokenA, tokenB);
        vm.label(
            address(pool),
            string.concat(
                pool.symbol(), " - ", IERC20(address(tokenA)).symbol(), " / ", IERC20(address(tokenB)).symbol()
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                          Success Path Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_deposit_firstDeposit(uint256 firstDepositAmtA, uint256 firstDepositAmtB) public {
        firstDepositAmtA = bound(firstDepositAmtA, 10000, type(uint112).max - 1);
        firstDepositAmtB = bound(firstDepositAmtB, 10000, type(uint112).max - 1);

        // Calculate expected LP tokens from deposit
        uint256 expected = ConstProdUtils._depositQuote(
            firstDepositAmtA,
            firstDepositAmtB,
            pool.totalSupply(),
            tokenA.balanceOf(address(pool)),
            tokenB.balanceOf(address(pool))
        );

        // Mint and approve tokens
        tokenA.mint(address(this), firstDepositAmtA);
        tokenA.approve(address(uniswapV2Router()), firstDepositAmtA);
        tokenB.mint(address(this), firstDepositAmtB);
        tokenB.approve(address(uniswapV2Router()), firstDepositAmtB);

        // Perform deposit
        uint256 testValue = UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())), tokenA, tokenB, firstDepositAmtA, firstDepositAmtB
        );

        // Verify results
        uint256 actual = pool.balanceOf(address(this));
        assertEq(expected, testValue, "First deposit return mismatch.");
        assertEq(expected, actual, "First deposit quote mismatch.");
        assertEq(testValue, actual, "First deposit actual mismatch.");
    }

    function test_deposit_secondDeposit() public {
        // Initialize with first deposit
        uint256 firstDepositAmtA = HUNDREDK_WAD;
        uint256 firstDepositAmtB = TENK_WAD;

        tokenA.mint(address(this), firstDepositAmtA);
        tokenA.approve(address(uniswapV2Router()), firstDepositAmtA);
        tokenB.mint(address(this), firstDepositAmtB);
        tokenB.approve(address(uniswapV2Router()), firstDepositAmtB);

        UniswapV2Service._deposit(
            IUniswapV2Router(address(uniswapV2Router())), tokenA, tokenB, firstDepositAmtA, firstDepositAmtB
        );

        // Transfer initial LP tokens away to start fresh
        /// forge-lint: disable-next-line(erc20-unchecked-transfer)
        pool.transfer(address(0), pool.balanceOf(address(this)));

        // Prepare second deposit
        uint256 depositA = TENK_WAD;
        uint256 depositB = ONEK_WAD;

        // Calculate expected LP tokens from second deposit
        uint256 expected = ConstProdUtils._depositQuote(
            depositA, depositB, pool.totalSupply(), tokenA.balanceOf(address(pool)), tokenB.balanceOf(address(pool))
        );

        // Mint and approve tokens for second deposit
        tokenA.mint(address(this), depositA);
        tokenA.approve(address(uniswapV2Router()), depositA);
        tokenB.mint(address(this), depositB);
        tokenB.approve(address(uniswapV2Router()), depositB);

        // Perform second deposit
        uint256 testValue =
            UniswapV2Service._deposit(IUniswapV2Router(address(uniswapV2Router())), tokenA, tokenB, depositA, depositB);

        // Verify results
        uint256 actual = pool.balanceOf(address(this));
        assertEq(testValue, actual, "Second deposit actual mismatch.");
        assertEq(expected, actual, "Second deposit quote mismatch.");
        assertEq(expected, testValue, "Second deposit return mismatch.");
    }
}
