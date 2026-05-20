// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

import {FraxTest} from "@crane/contracts/external/frax-std/FraxTest.sol";
import {FRAXStablecoin} from "@crane/contracts/protocols/tokens/stable/frax/Frax/Frax.sol";
import {FRAXShares} from "@crane/contracts/protocols/tokens/stable/frax/FXS/FXS.sol";
import {GasHelper} from "@crane/contracts/protocols/tokens/stable/frax/Utils/GasHelper.sol";
import {TestBase_FraxEthereumFork} from "../TestBase_FraxEthereumFork.sol";

contract FXSDisableVoteTrackingTest is FraxTest, GasHelper, TestBase_FraxEthereumFork {
    FRAXStablecoin internal frax = FRAXStablecoin(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    FRAXShares internal fxs = FRAXShares(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);

    address internal constant FXS_WHALE = 0xF977814e90dA44bFA03b6295A0616a897441aceC;
    address internal constant UTILITY_WALLET = 0x36A87d1E3200225f881488E4AEedF25303FebcAe;
    address internal constant COMPTROLLER_ADDRESS = 0xB1748C79709f4Ba2Dd82834B8c82D4a505003f27;

    function setUp() public {
        _forkEthereumAtBlock(17_198_193);

        vm.startPrank(COMPTROLLER_ADDRESS);
        fxs.toggleVotes();
        changePrank(FXS_WHALE);
    }

    function testTransfers() public {
        uint256 balBeforeWhale = fxs.balanceOf(FXS_WHALE);
        uint256 balBeforeUtility = fxs.balanceOf(UTILITY_WALLET);

        startMeasuringGas("Tracking disabled");
        fxs.transfer(UTILITY_WALLET, 100e18);
        fxs.approve(FXS_WHALE, type(uint256).max);
        fxs.transferFrom(FXS_WHALE, UTILITY_WALLET, 100e18);
        stopMeasuringGas();

        uint256 balAfterWhale = fxs.balanceOf(FXS_WHALE);
        uint256 balAfterUtility = fxs.balanceOf(UTILITY_WALLET);

        assertEq(int256(balAfterWhale) - int256(balBeforeWhale), -200e18);
        assertEq(int256(balAfterUtility) - int256(balBeforeUtility), 200e18);

        vm.startPrank(COMPTROLLER_ADDRESS);
        fxs.toggleVotes();
        changePrank(FXS_WHALE);

        startMeasuringGas("transfer");
        fxs.transfer(UTILITY_WALLET, 100e18);
        fxs.approve(FXS_WHALE, type(uint256).max);
        fxs.transferFrom(FXS_WHALE, UTILITY_WALLET, 100e18);
        stopMeasuringGas();
    }

    function testBurn() public {
        uint256 balBeforeWhale = fxs.balanceOf(FXS_WHALE);
        uint256 balBeforeUtility = fxs.balanceOf(UTILITY_WALLET);

        fxs.approve(FXS_WHALE, 100e18);
        startMeasuringGas("burnFrom");
        fxs.burnFrom(FXS_WHALE, 100e18);
        stopMeasuringGas();

        startMeasuringGas("burn");
        fxs.burn(100e18);
        stopMeasuringGas();

        uint256 balAfterWhale = fxs.balanceOf(FXS_WHALE);
        uint256 balAfterUtility = fxs.balanceOf(UTILITY_WALLET);

        assertEq(int256(balAfterWhale) - int256(balBeforeWhale), -200e18);
        assertEq(int256(balAfterUtility) - int256(balBeforeUtility), 0);
    }

    function testPoolActions() public {
        fxs.approve(UTILITY_WALLET, 100e18);

        changePrank(COMPTROLLER_ADDRESS);
        frax.addPool(UTILITY_WALLET);

        changePrank(UTILITY_WALLET);
        fxs.mint(FXS_WHALE, 100e18);
        fxs.pool_mint(FXS_WHALE, 100e18);
        fxs.pool_burn_from(FXS_WHALE, 100e18);
    }

}