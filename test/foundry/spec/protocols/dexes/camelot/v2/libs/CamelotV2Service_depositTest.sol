// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {betterconsole as console} from "../../../../../../../../contracts/utils/vm/foundry/tools/console/betterconsole.sol";
import "forge-std/Base.sol";
import "../../../../../../../../contracts/constants/Constants.sol";
import {APE_CHAIN_CURTIS} from "../../../../../../../../contracts/networks/arbitrum/apechain/constants/APE_CHAIN_CURTIS.sol";
import {CraneTest} from "../../../../../../../../contracts/test/CraneTest.sol";
import {IOwnableStorage, OwnableStorage} from "../../../../../../../../contracts/access/ownable/utils/OwnableStorage.sol";
import {ConstProdUtils} from "../../../../../../../../contracts/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {ICamelotPair} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotFactory} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "../../../../../../../../contracts/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "../../../../../../../../contracts/token/ERC20/BetterIERC20.sol";
import {IERC20MintBurn} from "../../../../../../../../contracts/token/ERC20/IERC20MintBurn.sol";
import {IERC20MintBurnOperableStorage, ERC20MintBurnOperableStorage} from "../../../../../../../../contracts/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";

/**
 * @title CamelotV2Service_depositTest
 * @dev Test suite for the _deposit function of CamelotV2Service
 */
contract CamelotV2Service_depositTest is CraneTest {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    ICamelotPair pool;

    function setUp() public virtual override {
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

        tokenA = IERC20MintBurn(
            diamondFactory()
            .deploy(
                erc20MintBurnPkg(),
                abi.encode(tokenAInit)
            )
        );
        vm.label(address(tokenA), "TokenA");

        // Create TokenB
        IERC20MintBurnOperableStorage.MintBurnOperableAccountInit memory tokenBInit;
        tokenBInit.ownableAccountInit = globalOwnableAccountInit;
        tokenBInit.name = "TokenB";
        tokenBInit.symbol = tokenBInit.name;
        tokenBInit.decimals = 18;

        tokenB = IERC20MintBurn(
            diamondFactory()
            .deploy(
                erc20MintBurnPkg(),
                abi.encode(tokenBInit)
            )
        );
        vm.label(address(tokenB), "TokenB");
        
        // Create pool
        pool = ICamelotPair(
            camV2Factory()
            .createPair(
                address(tokenA),
                address(tokenB)
            )
        );
        vm.label(
            address(pool),
            string.concat(
                pool.symbol(),
                " - ",
                IERC20(address(tokenA)).symbol(),
                " / ",
                IERC20(address(tokenB)).symbol()
            )
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                          Success Path Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_deposit_firstDeposit(
        uint256 firstDepositAmtA,
        uint256 firstDepositAmtB
    ) public {
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
        uint256 testValue = CamelotV2Service._deposit(
            camV2Router(),
            tokenA,
            tokenB,
            firstDepositAmtA,
            firstDepositAmtB
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
        tokenA.approve(address(camV2Router()), firstDepositAmtA);
        tokenB.mint(address(this), firstDepositAmtB);
        tokenB.approve(address(camV2Router()), firstDepositAmtB);

        CamelotV2Service._deposit(
            camV2Router(),
            tokenA,
            tokenB,
            firstDepositAmtA,
            firstDepositAmtB
        );
        
        // Transfer initial LP tokens away to start fresh
        pool.transfer(address(0), pool.balanceOf(address(this)));
        
        // Prepare second deposit
        uint256 depositA = TENK_WAD;
        uint256 depositB = ONEK_WAD;
        
        // Calculate expected LP tokens from second deposit
        uint256 expected = ConstProdUtils._depositQuote(
            depositA,
            depositB,
            pool.totalSupply(),
            tokenA.balanceOf(address(pool)),
            tokenB.balanceOf(address(pool))
        );
        
        // Mint and approve tokens for second deposit
        tokenA.mint(address(this), depositA);
        tokenA.approve(address(camV2Router()), depositA);
        tokenB.mint(address(this), depositB);
        tokenB.approve(address(camV2Router()), depositB);

        // Perform second deposit
        uint256 testValue = CamelotV2Service._deposit(
            camV2Router(),
            tokenA,
            tokenB,
            depositA,
            depositB
        );

        // Verify results
        uint256 actual = pool.balanceOf(address(this));
        assertEq(testValue, actual, "Second deposit actual mismatch.");
        assertEq(expected, actual, "Second deposit quote mismatch.");
        assertEq(expected, testValue, "Second deposit return mismatch.");
    }
    
    /* ---------------------------------------------------------------------- */
    /*                          Edge Case Tests                               */
    /* ---------------------------------------------------------------------- */
    
    function test_deposit_zeroAmounts() public {
        // Setup initial liquidity
        uint256 initialDeposit = TENK_WAD;
        tokenA.mint(address(this), initialDeposit);
        tokenA.approve(address(camV2Router()), initialDeposit);
        tokenB.mint(address(this), initialDeposit);
        tokenB.approve(address(camV2Router()), initialDeposit);
        
        CamelotV2Service._deposit(
            camV2Router(),
            tokenA,
            tokenB,
            initialDeposit,
            initialDeposit
        );
        
        // Clear LP balance
        pool.transfer(address(0), pool.balanceOf(address(this)));
        
        // Try depositing with zero for one amount
        tokenA.mint(address(this), TENK_WAD);
        tokenA.approve(address(camV2Router()), TENK_WAD);
        
        // Depositing with zero amount for tokenB should result in zero LP tokens
        uint256 result = CamelotV2Service._deposit(
            camV2Router(),
            tokenA,
            tokenB,
            TENK_WAD,
            0
        );
        
        // The router's behavior may vary, but likely will return 0 or revert
        assertEq(result, 0, "Zero amount deposit should result in zero LP tokens");
    }
} 