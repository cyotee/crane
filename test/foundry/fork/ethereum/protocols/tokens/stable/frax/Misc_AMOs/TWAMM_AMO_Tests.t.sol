// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/TWAMM_AMO-Tests.js`

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FRAXShares} from "@crane/contracts/protocols/tokens/stable/frax/FXS/FXS.sol";
import {TWAMM_AMO} from "@crane/contracts/protocols/tokens/stable/frax/Misc_AMOs/TWAMM_AMO.sol";
import {FraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {IFraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/interfaces/IFraxswapPair.sol";
import {
    TestBase_FraxEthereumFork,
    FraxEthereumAddresses
} from "../TestBase_FraxEthereumFork.sol";

contract TWAMM_AMO_Tests is TestBase_FraxEthereumFork {
    TWAMM_AMO internal amo;
    IERC20 internal frax;
    IERC20 internal fxs;
    IFraxswapPair internal pair;

    function setUp() public {
        _forkEthereum();
        amo = TWAMM_AMO(FraxEthereumAddresses.TWAMM_AMO);
        frax = IERC20(FraxEthereumAddresses.FRAX);
        fxs = IERC20(FraxEthereumAddresses.FXS);
        pair = IFraxswapPair(amo.fraxswap_pair());

        _disableFxsVoteTracking();
        _takeOwnership(address(this));
        deal(FraxEthereumAddresses.FRAX, address(amo), 500_000e18);
        deal(FraxEthereumAddresses.FXS, address(amo), 10_000e18);
        deal(FraxEthereumAddresses.FRAX, address(this), 10_000e18);
        deal(FraxEthereumAddresses.FXS, address(this), 10_000e18);
    }

    function _disableFxsVoteTracking() internal {
        vm.prank(FraxEthereumAddresses.COMPTROLLER);
        FRAXShares(FraxEthereumAddresses.FXS).toggleVotes();
    }

    function _takeOwnership(address newOwner) internal {
        address currentOwner = amo.owner();
        vm.prank(currentOwner);
        amo.nominateNewOwner(newOwner);
        vm.prank(newOwner);
        amo.acceptOwnership();
    }

    function test_Initialize_readsPricesAndReserves() public view {
        assertGt(amo.getFRAXPriceE18(), 0);
        assertGt(amo.getFXSPriceE18(), 0);
        assertGt(amo.num_twamm_intervals(), 0);
        assertGt(amo.swap_period(), 0);

        (uint112 r0, uint112 r1,) = pair.getReserves();
        assertGt(r0, 0);
        assertGt(r1, 0);
    }

    function test_twammSwap_fxsSell_intervalOverride_cancel() public {
        if (!_heavyForkEnabled()) return;
        // Mainnet tip: FRAX/FXS Fraxswap pair has long-term swaps paused (see `newSwapsPaused`).
        if (FraxswapPair(address(pair)).newSwapsPaused()) {
            vm.skip(true);
        }

        uint256 sellAmt = 100e18;
        uint256 intervals = 50;

        pair.executeVirtualOrders(block.timestamp);

        uint256 fxsBefore = fxs.balanceOf(address(amo));

        (,, uint256 orderId) = amo.twammSwap(0, sellAmt, intervals);

        vm.warp(block.timestamp + intervals * 1800);
        amo.cancelTWAMMOrder(orderId);

        uint256 fxsAfter = fxs.balanceOf(address(amo));
        assertLt(fxsAfter, fxsBefore);
        assertGt(fxsBefore - fxsAfter, sellAmt / 2 - sellAmt / 100);
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