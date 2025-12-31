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
// import {ConstProdUtils} from "contracts/crane/utils/math/ConstProdUtils.sol";
import {CamelotV2Service} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotV2Service.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
// import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
// import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {IERC20MintBurn} from "contracts/crane/interfaces/IERC20MintBurn.sol";
import {IERC20MintBurnOperableStorage} from 
// ERC20MintBurnOperableStorage
"contracts/crane/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";

/**
 * @title CamelotV2Service_withdrawSwapDirectTest
 * @dev Test suite for the _withdrawSwapDirect function of CamelotV2Service
 */
contract CamelotV2Service_withdrawSwapDirectTest is TestBase_CamelotV2 {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    ICamelotPair pool;
    address referrer = address(0); // Using zero address as dummy referrer
    uint256 depositAmount = TENK_WAD;
    uint256 withdrawAmount;

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

        // Initialize pool with liquidity
        tokenA.mint(address(this), depositAmount);
        tokenA.approve(address(camV2Router()), depositAmount);
        tokenB.mint(address(this), depositAmount);
        tokenB.approve(address(camV2Router()), depositAmount);

        CamelotV2Service._deposit(camV2Router(), tokenA, tokenB, depositAmount, depositAmount);

        // Store the LP amount for later
        withdrawAmount = pool.balanceOf(address(this));
    }

    /* ---------------------------------------------------------------------- */
    /*                          Success Path Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_withdrawSwapDirect_TokenA() public {
        // Record balances before withdrawal
        uint256 beforeBalanceA = tokenA.balanceOf(address(this));
        uint256 beforeBalanceB = tokenB.balanceOf(address(this));

        // Withdraw and swap to tokenA
        uint256 totalTokenAOut = CamelotV2Service._withdrawSwapDirect(
            pool,
            camV2Router(),
            withdrawAmount,
            tokenA, // Target token is A
            tokenB, // Other token is B
            referrer
        );

        // Verify LP tokens were burned
        assertEq(pool.balanceOf(address(this)), 0, "All LP tokens should be burned");

        // Verify tokenA balance increased
        assertEq(
            tokenA.balanceOf(address(this)),
            beforeBalanceA + totalTokenAOut,
            "TokenA balance should increase by output amount"
        );

        // The other token balance should remain unchanged since all of tokenB was swapped to tokenA
        assertEq(tokenB.balanceOf(address(this)), beforeBalanceB, "TokenB balance should remain unchanged");

        // Verify we received a reasonable amount of tokenA
        // For first deposit, the amount could be equal or slightly less due to fees
        assertEq(
            totalTokenAOut, depositAmount - 1, "Should receive approximately the same deposit of TokenA"
        );
    }

    function test_withdrawSwapDirect_TokenB() public {
        // Record balances before withdrawal
        uint256 beforeBalanceA = tokenA.balanceOf(address(this));
        uint256 beforeBalanceB = tokenB.balanceOf(address(this));

        // Withdraw and swap to tokenB
        uint256 totalTokenBOut = CamelotV2Service._withdrawSwapDirect(
            pool,
            camV2Router(),
            withdrawAmount,
            tokenB, // Target token is B
            tokenA, // Other token is A
            referrer
        );

        // Verify LP tokens were burned
        assertEq(pool.balanceOf(address(this)), 0, "All LP tokens should be burned");

        // Verify tokenB balance increased
        assertEq(
            tokenB.balanceOf(address(this)),
            beforeBalanceB + totalTokenBOut,
            "TokenB balance should increase by output amount"
        );

        // The other token balance should remain unchanged since all of tokenA was swapped to tokenB
        assertEq(tokenA.balanceOf(address(this)), beforeBalanceA, "TokenA balance should remain unchanged");

        // Verify we received a reasonable amount of tokenB
        // For first deposit, the amount could be equal or slightly less due to fees
        assertEq(
            totalTokenBOut, depositAmount - 1, "Should receive approximately the same deposit of TokenB"
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                          Compare with Manual                           */
    /* ---------------------------------------------------------------------- */

    // Simplified comparison test that avoids the persistence issue
    function test_withdrawSwapDirect_compareOutputs() public {
        // Get quarter of the LP tokens to work with
        uint256 testLpAmount = withdrawAmount / 4;

        uint256 snapshotId = vm.snapshot();
        // First approach: Direct withdraw+swap
        uint256 directTokenAOut =
            CamelotV2Service._withdrawSwapDirect(pool, camV2Router(), testLpAmount, tokenA, tokenB, referrer);
        vm.revertTo(snapshotId);

        // For comparison, perform the manual withdraw+swap for the SAME LP amount
        (uint256 amount0, uint256 amount1) = CamelotV2Service._withdrawDirect(pool, testLpAmount);

        // Determine which withdrawn amount corresponds to tokenA and which is the sale token
        uint256 tokenAFromWithdraw = address(tokenA) == pool.token0() ? amount0 : amount1;
        uint256 saleTokenFromWithdraw = address(tokenA) == pool.token0() ? amount1 : amount0;
        IERC20 saleToken = tokenB;

        // Sanity checks
        assertGt(directTokenAOut, 0, "Direct withdraw+swap should produce non-zero output");
        assertGt(tokenAFromWithdraw, 0, "Direct withdraw should produce non-zero tokenA");

        // Swap the sale token to tokenA using the same router logic the service uses
        uint256 swappedToA = CamelotV2Service._swap(camV2Router(), pool, saleTokenFromWithdraw, saleToken, tokenA, referrer);

        uint256 manualTotalTokenA = tokenAFromWithdraw + swappedToA;

        // The manual withdraw+swap result should equal the library convenience method
        assertEq(manualTotalTokenA, directTokenAOut, "Token outputs should match between methods");
    }

    /* ---------------------------------------------------------------------- */
    /*                          Edge Case Tests                               */
    /* ---------------------------------------------------------------------- */

    function test_withdrawSwapDirect_partialAmount() public {
        // Get half the LP tokens
        uint256 halfLpBalance = pool.balanceOf(address(this)) / 2;

        // Record balance before
        uint256 beforeBalance = tokenA.balanceOf(address(this));

        // Withdraw half the LP tokens
        uint256 amountOut =
            CamelotV2Service._withdrawSwapDirect(pool, camV2Router(), halfLpBalance, tokenA, tokenB, referrer);

        // Verify partial LP tokens were burned
        assertEq(pool.balanceOf(address(this)), halfLpBalance, "Half of LP tokens should remain");

        // Verify output is non-zero and balance increased correctly
        assertGt(amountOut, 0, "Should receive non-zero output for partial withdrawal");

        // Use approxEq for floating point comparison to account for minor differences
        // assertApproxEqAbs(
        //     tokenA.balanceOf(address(this)),
        //     beforeBalance + amountOut,
        //     1, // allow 1 wei difference due to rounding
        //     "TokenA balance should increase correctly"
        // );
        assertEq(
            tokenA.balanceOf(address(this)),
            beforeBalance + amountOut
        );
    }
}
