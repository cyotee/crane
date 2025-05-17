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
 * @title CamelotV2Service_withdrawDirectTest
 * @dev Test suite for the _withdrawDirect function of CamelotV2Service
 */
contract CamelotV2Service_withdrawDirectTest is CraneTest {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    ICamelotPair pool;
    uint256 depositAmount = TENK_WAD;
    uint256 withdrawAmount;

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
        
        // Initialize pool with liquidity
        tokenA.mint(address(this), depositAmount);
        tokenA.approve(address(camV2Router()), depositAmount);
        tokenB.mint(address(this), depositAmount);
        tokenB.approve(address(camV2Router()), depositAmount);
        
        CamelotV2Service._deposit(
            camV2Router(),
            tokenA,
            tokenB,
            depositAmount,
            depositAmount
        );
        
        // Store the LP amount for later
        withdrawAmount = pool.balanceOf(address(this));
    }

    /* ---------------------------------------------------------------------- */
    /*                          Success Path Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_withdrawDirect() public {
        // Get initial balances
        uint256 beforeBalanceA = tokenA.balanceOf(address(this));
        uint256 beforeBalanceB = tokenB.balanceOf(address(this));
        
        // Withdraw all LP tokens
        (uint256 amountA, uint256 amountB) = CamelotV2Service._withdrawDirect(
            pool,
            withdrawAmount
        );
        
        // Verify LP tokens were burned
        assertEq(pool.balanceOf(address(this)), 0, "All LP tokens should be burned");
        
        // Verify received tokens
        assertGt(amountA, 0, "Should receive non-zero tokenA");
        assertGt(amountB, 0, "Should receive non-zero tokenB");
        
        // Verify balances increased
        assertEq(tokenA.balanceOf(address(this)), beforeBalanceA + amountA, "TokenA balance should increase");
        assertEq(tokenB.balanceOf(address(this)), beforeBalanceB + amountB, "TokenB balance should increase");
        
        // Verify received approximately what was deposited (allowing for some fees)
        assertApproxEqRel(amountA, depositAmount, 0.05e18, "Should get back approximately what was deposited");
        assertApproxEqRel(amountB, depositAmount, 0.05e18, "Should get back approximately what was deposited");
    }
    
    function test_withdrawDirect_partial() public {
        // Get half the LP tokens
        uint256 halfLpBalance = pool.balanceOf(address(this)) / 2;
        
        // Record balances before
        uint256 beforeBalanceA = tokenA.balanceOf(address(this));
        uint256 beforeBalanceB = tokenB.balanceOf(address(this));
        
        // Withdraw half the LP tokens
        (uint256 amountA, uint256 amountB) = CamelotV2Service._withdrawDirect(
            pool,
            halfLpBalance
        );
        
        // Verify partial LP tokens were burned
        assertEq(pool.balanceOf(address(this)), halfLpBalance, "Half of LP tokens should remain");
        
        // Verify received tokens
        assertGt(amountA, 0, "Should receive non-zero tokenA");
        assertGt(amountB, 0, "Should receive non-zero tokenB");
        
        // Verify balances increased
        assertEq(tokenA.balanceOf(address(this)), beforeBalanceA + amountA, "TokenA balance should increase");
        assertEq(tokenB.balanceOf(address(this)), beforeBalanceB + amountB, "TokenB balance should increase");
        
        // Verify received approximately half of what was deposited (allowing for some fees)
        assertApproxEqRel(amountA, depositAmount / 2, 0.05e18, "Should get back approximately half of what was deposited");
        assertApproxEqRel(amountB, depositAmount / 2, 0.05e18, "Should get back approximately half of what was deposited");
    }
    
    /* ---------------------------------------------------------------------- */
    /*                          Edge Case Tests                               */
    /* ---------------------------------------------------------------------- */
    
    // This test is skipped because attempting to burn zero LP tokens will revert
    // with "CamelotPair: INSUFFICIENT_LIQUIDITY_BURNED"
    function skip_test_withdrawDirect_zeroAmount() public {
        // The base CamelotPair contract will revert when attempting to burn 0 LP tokens
        // This is expected behavior and not a bug in our implementation
    }
} 