// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/FPIControllerPool-Tests.js`

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FPI} from "@crane/contracts/protocols/tokens/stable/frax/FPI/FPI.sol";
import {FPIControllerPool} from "@crane/contracts/protocols/tokens/stable/frax/FPI/FPIControllerPool.sol";
import {FraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {IFraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/interfaces/IFraxswapPair.sol";
import {TestBase_FraxEthereumFork, FraxEthereumAddresses} from "../TestBase_FraxEthereumFork.sol";

contract FPIControllerPool_Tests is TestBase_FraxEthereumFork {
    FPIControllerPool internal pool;
    FPI internal fpi;
    IERC20 internal frax;
    IFraxswapPair internal twammPair;

    address internal operator;

    function setUp() public {
        _forkEthereum();
        operator = address(this);

        pool = FPIControllerPool(FraxEthereumAddresses.FPI_CONTROLLER_POOL);
        fpi = FPI(FraxEthereumAddresses.FPI);
        frax = IERC20(FraxEthereumAddresses.FRAX);
        twammPair = IFraxswapPair(FraxEthereumAddresses.FRAXSWAP_V2_FRAX_FPI);

        _takeOwnership(operator);
        _fundController();
    }

    function _takeOwnership(address newOwner) internal {
        address currentOwner = pool.owner();
        vm.prank(currentOwner);
        pool.nominateNewOwner(newOwner);
        vm.prank(newOwner);
        pool.acceptOwnership();
    }

    function _fundController() internal {
        deal(FraxEthereumAddresses.FRAX, address(pool), 500_000e18);
        deal(FraxEthereumAddresses.FPI, address(pool), 10_000e18);
        deal(FraxEthereumAddresses.FRAX, operator, 10_000e18);
        deal(FraxEthereumAddresses.FPI, operator, 10_000e18);
    }

    function test_Initialize_readsPricesAndReserves() public view {
        assertGt(pool.getFRAXPriceE18(), 0);
        assertGt(pool.getFPIPriceE18(), 0);

        (uint256 cpiPeg,, bool withinRange) = pool.pegStatusMntRdm();
        assertGt(cpiPeg, 0);

        (int256 collatImbalance, uint256 cpiPeg2, uint256 fpiPrice, uint256 priceDiff) = pool.price_info();
        assertGt(cpiPeg2, 0);
        assertGt(fpiPrice, 0);
        assertGt(pool.num_twamm_intervals(), 0);
        assertGt(pool.swap_period(), 0);

        (uint112 r0, uint112 r1,) = twammPair.getReserves();
        assertGt(r0, 0);
        assertGt(r1, 0);

        // Sanity: peg band flag is a bool (may be true or false on live state)
        withinRange;
        collatImbalance;
        priceDiff;
    }

    /// @dev `twammManual` + pair storage reads are heavy on RPC; set `FRAX_HEAVY_FORK=1` to run.
    function test_twammManual_fpiSell_intervalOverride_cancel() public {
        if (!_heavyForkEnabled()) return;
        if (FraxswapPair(address(twammPair)).newSwapsPaused()) {
            vm.skip(true);
        }

        uint256 manualAmt = 100e18;
        uint256 intervals = 50;

        uint256 fpiBefore = fpi.balanceOf(address(pool));
        uint256 fraxBefore = frax.balanceOf(address(pool));

        pool.twammManual(0, manualAmt, intervals);

        vm.warp(block.timestamp + intervals * 1800);
        pool.cancelCurrTWAMMOrder(0);

        uint256 fpiAfter = fpi.balanceOf(address(pool));
        uint256 fraxAfter = frax.balanceOf(address(pool));

        int256 fpiDelta = int256(fpiAfter) - int256(fpiBefore);
        assertLt(fpiDelta, int256(manualAmt));
        assertGt(fpiDelta, int256(manualAmt / 2) - int256(manualAmt / 100));
        fraxAfter;
        fraxBefore;
    }

    /// @dev `executeVirtualOrders` hammers fork storage; set `FRAX_HEAVY_FORK=1` to run.
    function test_executeVirtualOrders_advancesCpiPeg() public {
        if (!_heavyForkEnabled()) return;

        (, uint256 cpiBefore,,) = pool.price_info();

        vm.prank(FraxEthereumAddresses.ADDRESS_WITH_ETH);
        twammPair.executeVirtualOrders(block.timestamp);

        vm.warp(block.timestamp + 1 days);

        (, uint256 cpiAfter,,) = pool.price_info();
        assertGe(cpiAfter, cpiBefore);
    }

    function _heavyForkEnabled() internal returns (bool) {
        try vm.envString("FRAX_HEAVY_FORK") returns (string memory flag) {
            return keccak256(bytes(flag)) == keccak256("1");
        } catch {
            vm.skip(true);
            return false;
        }
    }
}
