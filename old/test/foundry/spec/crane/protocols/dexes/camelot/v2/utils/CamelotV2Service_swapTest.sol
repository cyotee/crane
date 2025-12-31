// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Base.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";
// import {APE_CHAIN_CURTIS} from "contracts/networks/arbitrum/apechain/constants/APE_CHAIN_CURTIS.sol";
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
// ERC20MintBurnOperableStorage
"contracts/crane/token/ERC20/utils/ERC20MintBurnOperableStorage.sol";

/**
 * @title CamelotV2Service_swapTest
 * @dev Test suite for the _swap function variants of CamelotV2Service
 */
contract CamelotV2Service_swapTest is TestBase_CamelotV2 {
    IERC20MintBurn tokenA;
    IERC20MintBurn tokenB;
    ICamelotPair pool;
    address referrer = address(0); // Using zero address as dummy referrer
    uint256 depositAmount = TENK_WAD;
    uint256 swapAmount = ONE_WAD; // Amount to swap for testing

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
    }

    /* ---------------------------------------------------------------------- */
    /*                      Direct Swap Function Tests                        */
    /* ---------------------------------------------------------------------- */

    function test_swap_directWithReserves() public {
        // Prepare for swap
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(camV2Router()), swapAmount);

        // Get token balances before swap
        uint256 beforeBalanceB = tokenB.balanceOf(address(this));

        // Get reserves for swap
        (uint112 reserve0, uint112 reserve1, uint16 token0feePercent, uint16 token1FeePercent) = pool.getReserves();
        (uint256 reserveIn, uint256 reserveOut, uint256 feePercent) = address(tokenA) == pool.token0()
            ? (reserve0, reserve1, token0feePercent)
            : (reserve1, reserve0, token1FeePercent);

        // Calculate expected output amount
        uint256 expectedOut = ConstProdUtils._saleQuote(swapAmount, reserveIn, reserveOut, feePercent);
        assertGt(expectedOut, 0, "Expected output should be greater than zero");

        // Perform swap
        uint256 actualOut = CamelotV2Service._swap(
            camV2Router(), swapAmount, tokenA, reserveIn, feePercent, tokenB, reserveOut, referrer
        );

        // Verify output amount is close to expected
        // assertApproxEqRel(actualOut, expectedOut, 0.01e18, "Swap output should be close to expected");
        assertEq(actualOut, expectedOut, "Swap output should be close to expected");

        // Verify balance increased correctly
        assertGt(tokenB.balanceOf(address(this)), beforeBalanceB, "TokenB balance should increase after swap");
    }

    function test_swap_viaPair() public {
        // Prepare for swap
        tokenA.mint(address(this), swapAmount);
        tokenA.approve(address(camV2Router()), swapAmount);

        // Get token balances before swap
        uint256 beforeBalanceB = tokenB.balanceOf(address(this));

        // Perform swap using the pair-based variant
        uint256 amountOut = CamelotV2Service._swap(camV2Router(), pool, swapAmount, tokenA, tokenB, referrer);

        // Verify output is non-zero
        assertGt(amountOut, 0, "Swap should produce non-zero output");

        // Verify balance increased correctly
        assertEq(
            tokenB.balanceOf(address(this)), beforeBalanceB + amountOut, "TokenB balance increase should match output"
        );
    }

    /* ---------------------------------------------------------------------- */
    /*                         _sortReserves Tests                            */
    /* ---------------------------------------------------------------------- */

    function test_sortReserves() public view {
        // Test sorting reserves for tokenA
        CamelotV2Service.ReserveInfo memory reservesA = CamelotV2Service._sortReserves(pool, tokenA);

        // Test sorting reserves for tokenB
        CamelotV2Service.ReserveInfo memory reservesB = CamelotV2Service._sortReserves(pool, tokenB);

        // Verify that token order is properly handled
        assertEq(reservesA.reserveIn, reservesB.reserveOut, "Reserves should be swapped when token changes");
        assertEq(reservesA.reserveOut, reservesB.reserveIn, "Reserves should be swapped when token changes");

        // Verify fees are also correctly sorted
        assertEq(reservesA.feePercent, reservesB.unknownFee, "Fees should be swapped when token changes");
        assertEq(reservesA.unknownFee, reservesB.feePercent, "Fees should be swapped when token changes");
    }

    /* ---------------------------------------------------------------------- */
    /*                          Edge Case Tests                               */
    /* ---------------------------------------------------------------------- */

    // This test is skipped because swapping zero tokens will revert with
    // "CamelotPair: INSUFFICIENT_OUTPUT_AMOUNT" in the router
    /// forge-lint: disable-next-line(mixed-case-function)
    function skip_test_swap_zeroAmount() public {
        // The CamelotV2Router will revert when attempting to swap 0 tokens
        // This is expected behavior from the protocol and not a bug in our implementation
    }
}
