// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/FrxETH/FrxETHMiniRouter-Tests.js` (mainnet fork).

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {FrxETHMiniRouter} from "@crane/contracts/protocols/tokens/stable/frax/FraxETH/FrxETHMiniRouter.sol";
import {
    TestBase_FraxEthereumFork,
    FraxEthereumAddresses
} from "../TestBase_FraxEthereumFork.sol";

contract FrxETHMiniRouter_Test is TestBase_FraxEthereumFork {
    FrxETHMiniRouter internal router;
    IERC20 internal frxETH;
    IERC20 internal sfrxETH;

    function setUp() public {
        _forkEthereum();
        router = new FrxETHMiniRouter();
        frxETH = IERC20(0x5E8422345238F34275888049021821E8E08CAa1f);
        sfrxETH = IERC20(0xac3E018457B222d93114458476f3E3416Abbe38F);
    }

    function test_setupContracts() public view {
        assertTrue(address(router) != address(0));
    }

    function test_ETH_to_frxETH() public {

        uint256 ethBefore = address(this).balance;
        uint256 frxBefore = frxETH.balanceOf(address(this));
        uint256 sfrxBefore = sfrxETH.balanceOf(address(this));

        router.sendETH{value: 0.1 ether}(address(this), false, 0);

        uint256 frxDelta = frxETH.balanceOf(address(this)) - frxBefore;
        assertApproxEqAbs(frxDelta, 0.1 ether, 0.005 ether);
        assertEq(sfrxETH.balanceOf(address(this)) - sfrxBefore, 0);
        assertGt(ethBefore - address(this).balance, 0.09 ether);
    }

    function test_ETH_to_sfrxETH() public {

        uint256 sfrxBefore = sfrxETH.balanceOf(address(this));

        (uint256 frxUsed,, uint256 sfrxOut) = router.sendETH{value: 0.1 ether}(address(this), true, 0);

        assertApproxEqAbs(frxUsed, 0.1 ether, 0.005 ether);
        assertGt(sfrxOut, 0);
        assertGt(sfrxETH.balanceOf(address(this)) - sfrxBefore, 0);
    }
}