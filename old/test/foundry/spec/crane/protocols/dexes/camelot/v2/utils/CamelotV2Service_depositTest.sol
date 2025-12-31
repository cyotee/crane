// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Base.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";
// import {APE_CHAIN_CURTIS} from "contracts/crane/constants/networks/APE_CHAIN_CURTIS.sol";
// import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {TestBase_CamelotV2} from "contracts/crane/test/bases/protocols/TestBase_CamelotV2.sol";
import {IOwnableStorage} from 
// OwnableStorage
"contracts/crane/access/ownable/utils/OwnableStorage.sol";
import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
// import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
// import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IERC20MintBurnOperableStorage} from 
//  ERC20MintBurnOperableStorage
"contracts/crane/token/erc20/utils/ERC20MintBurnOperableStorage.sol";

/**
 * @title CamelotV2Service_depositTest
 * @dev Test suite for the _deposit function of CamelotV2Service
 */
contract CamelotV2Service_depositTest is TestBase_CamelotV2 {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    ICamelotPair pool;

    function setUp() public virtual override {
        owner(address(this));
        // Fork chain state
        vm.createSelectFork("apeChain_curtis_rpc", 8579331);

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

        // Create pool
        pool = ICamelotPair(camV2Factory().createPair(address(tokenA), address(tokenB)));
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
        tokenA.approve(address(camV2Router()), firstDepositAmtA);
        tokenB.mint(address(this), firstDepositAmtB);
        tokenB.approve(address(camV2Router()), firstDepositAmtB);

        // Perform deposit
        uint256 testValue = CamelotV2Service._deposit(camV2Router(), tokenA, tokenB, firstDepositAmtA, firstDepositAmtB);

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
        tokenA.approve(address(camV2Router()), firstDepositAmtA);
        tokenB.mint(address(this), firstDepositAmtB);
        tokenB.approve(address(camV2Router()), firstDepositAmtB);

        CamelotV2Service._deposit(camV2Router(), tokenA, tokenB, firstDepositAmtA, firstDepositAmtB);

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
        tokenA.approve(address(camV2Router()), depositA);
        tokenB.mint(address(this), depositB);
        tokenB.approve(address(camV2Router()), depositB);

        // Perform second deposit
        uint256 testValue = CamelotV2Service._deposit(camV2Router(), tokenA, tokenB, depositA, depositB);

        // Verify results
        uint256 actual = pool.balanceOf(address(this));
        assertEq(testValue, actual, "Second deposit actual mismatch.");
        assertEq(expected, actual, "Second deposit quote mismatch.");
        assertEq(expected, testValue, "Second deposit return mismatch.");
    }
}
