// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";
import {WstETH} from "@crane/contracts/external/lido/WstETH.sol";
import {IStETH} from "@crane/contracts/external/lido/IStETH.sol";

/// @dev Minimal stETH mock for domain wrap/unwrap (share math 1:1 for hermetic domain proof).
contract MockStETH is ERC20, IStETH {
    constructor() ERC20("staked ETH", "stETH") {}

    function getPooledEthByShares(uint256 shares) external pure returns (uint256) {
        return shares;
    }

    function getSharesByPooledEth(uint256 ethAmount) external pure returns (uint256) {
        return ethAmount;
    }

    function submit(address) external payable returns (uint256) {
        _mint(msg.sender, msg.value);
        return msg.value;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract WstETH_DomainTest is Test {
    MockStETH internal steth;
    WstETH internal wsteth;

    function setUp() public {
        steth = new MockStETH();
        wsteth = new WstETH(IStETH(address(steth)));
    }

    function test_Domain_WrapUnwrap_Inverse() public {
        steth.mint(address(this), 10 ether);
        steth.approve(address(wsteth), 10 ether);
        uint256 w = wsteth.wrap(10 ether);
        assertEq(w, 10 ether);
        assertEq(wsteth.balanceOf(address(this)), 10 ether);
        uint256 s = wsteth.unwrap(10 ether);
        assertEq(s, 10 ether);
        assertEq(steth.balanceOf(address(this)), 10 ether);
    }

    function test_Domain_StEthPerToken() public {
        assertEq(wsteth.stEthPerToken(), 1 ether);
    }
}
