// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {RocketStorage} from "@crane/contracts/external/rocketpool/storage/RocketStorage.sol";
import {RocketTokenRETH} from "@crane/contracts/external/rocketpool/token/RocketTokenRETH.sol";
import {RocketDepositPool} from "@crane/contracts/external/rocketpool/deposit/RocketDepositPool.sol";
import {RocketNetworkBalancesMock} from
    "@crane/contracts/external/rocketpool/mock/RocketNetworkBalancesMock.sol";
import {RocketDAOProtocolSettingsDepositMock} from
    "@crane/contracts/external/rocketpool/mock/RocketDAOProtocolSettingsDepositMock.sol";

/**
 * @notice Drives shipped RocketStorage/RocketBase/RocketTokenRETH/RocketDepositPool domain.
 * Exchange-rate math and deposit→mint onlyLatestContract gates from upstream architecture.
 */
contract RocketTokenRETH_DomainTest is Test {
    RocketStorage internal store;
    RocketTokenRETH internal reth;
    RocketDepositPool internal pool;
    RocketNetworkBalancesMock internal balances;
    RocketDAOProtocolSettingsDepositMock internal settings;

    function setUp() public {
        store = new RocketStorage();
        balances = new RocketNetworkBalancesMock();
        settings = new RocketDAOProtocolSettingsDepositMock();

        reth = new RocketTokenRETH(store);
        pool = new RocketDepositPool(store, address(reth));

        // Upstream address book: contract.address + name
        store.setContractAddress("rocketTokenRETH", address(reth));
        store.setContractAddress("rocketDepositPool", address(pool));
        store.setContractAddress("rocketNetworkBalances", address(balances));
        store.setContractAddress("rocketDAOProtocolSettingsDeposit", address(settings));

        // Empty network → 1:1 rate (upstream formula)
        balances.setBalances(0, 0);
    }

    function test_Domain_DepositMintsRETH_ViaOnlyLatestContract() public {
        vm.deal(address(this), 5 ether);
        uint256 beforeBal = reth.balanceOf(address(this));
        pool.deposit{value: 1 ether}();
        uint256 minted = reth.balanceOf(address(this)) - beforeBal;
        assertGt(minted, 0, "rETH minted via deposit pool");
        // 1:1 when reth supply was 0
        assertEq(minted, 1 ether, "1:1 mint at empty network");
        assertEq(pool.getBalance(), 1 ether, "deposit pool balance");
    }

    function test_Domain_ExchangeRate_UsesNetworkBalances() public {
        balances.setBalances(200 ether, 100 ether);
        assertEq(reth.getExchangeRate(), 2 ether, "1 rETH = 2 ETH");
        assertEq(reth.getEthValue(1 ether), 2 ether);
        assertEq(reth.getRethValue(2 ether), 1 ether);
    }

    function test_Domain_MintRevertsIfNotDepositPool() public {
        vm.expectRevert(bytes("Invalid or outdated contract"));
        reth.mint(1 ether, address(this));
    }

    function test_Domain_DepositRespectsMaxPoolSize() public {
        settings.setMaximumDepositPoolSize(0.5 ether);
        vm.deal(address(this), 2 ether);
        vm.expectRevert(bytes("The deposit pool size after depositing exceeds the maximum size"));
        pool.deposit{value: 1 ether}();
    }

    function test_Domain_GetMaximumDepositAmount() public {
        settings.setMaximumDepositPoolSize(10 ether);
        assertEq(pool.getMaximumDepositAmount(), 10 ether);
        settings.setDepositEnabled(false);
        assertEq(pool.getMaximumDepositAmount(), 0);
    }
}
