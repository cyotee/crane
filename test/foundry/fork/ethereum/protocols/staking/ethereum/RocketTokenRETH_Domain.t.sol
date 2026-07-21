// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {RocketTokenRETH} from "@crane/contracts/external/rocketpool/token/RocketTokenRETH.sol";
import {RocketDepositPool} from "@crane/contracts/external/rocketpool/deposit/RocketDepositPool.sol";

contract RocketTokenRETH_DomainTest is Test {
    RocketTokenRETH internal reth;
    RocketDepositPool internal pool;

    function setUp() public {
        reth = new RocketTokenRETH();
        pool = new RocketDepositPool(address(reth));
        reth.setDepositPool(address(pool));
        // 1:1 initial (empty network)
        reth.setNetworkBalances(0, 0);
    }

    function test_Domain_DepositMintsRETH() public {
        vm.deal(address(this), 5 ether);
        pool.deposit{value: 2 ether}();
        assertGt(reth.balanceOf(address(this)), 0);
        assertEq(reth.getExchangeRate(), 1 ether); // still 1:1 after first mint with balances update
    }

    function test_Domain_ExchangeRate_AfterBalances() public {
        reth.setNetworkBalances(200 ether, 100 ether);
        // 1 rETH = 2 ETH
        assertEq(reth.getExchangeRate(), 2 ether);
        assertEq(reth.getEthValue(1 ether), 2 ether);
        assertEq(reth.getRethValue(2 ether), 1 ether);
    }
}
