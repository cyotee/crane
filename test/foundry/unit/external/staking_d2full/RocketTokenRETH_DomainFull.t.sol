// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {RocketStorage} from "@crane/contracts/external/rocketpool/contract/RocketStorage.sol";
import {RocketTokenRETH} from "@crane/contracts/external/rocketpool/contract/token/RocketTokenRETH.sol";
import {RocketDepositPool} from "@crane/contracts/external/rocketpool/contract/deposit/RocketDepositPool.sol";
import {RocketNetworkBalancesMock} from
    "@crane/contracts/external/rocketpool/mock/RocketNetworkBalancesMock.sol";
import {RocketDAOProtocolSettingsDepositMock} from
    "@crane/contracts/external/rocketpool/mock/RocketDAOProtocolSettingsDepositMock.sol";
import {RocketDAOProtocolSettingsNetworkMock} from
    "@crane/contracts/external/rocketpool/mock/RocketDAOProtocolSettingsNetworkMock.sol";
import {RocketVaultMock} from "@crane/contracts/external/rocketpool/mock/RocketVaultMock.sol";
import {RocketMinipoolQueueMock} from
    "@crane/contracts/external/rocketpool/mock/RocketMinipoolQueueMock.sol";

/**
 * @notice Domain deposit→mint against FULL vendored RocketStorage / RocketTokenRETH / RocketDepositPool.
 * Uses guardian registration (upstream address book) + minimal vault/settings mocks.
 */
contract RocketTokenRETH_DomainFullTest is Test {
    RocketStorage internal store;
    RocketTokenRETH internal reth;
    RocketDepositPool internal pool;
    RocketNetworkBalancesMock internal balances;
    RocketDAOProtocolSettingsDepositMock internal depositSettings;
    RocketDAOProtocolSettingsNetworkMock internal networkSettings;
    RocketVaultMock internal vault;
    RocketMinipoolQueueMock internal queue;

    address internal constant GUARDIAN = address(0xB0B);

    function setUp() public {
        // Deploy as GUARDIAN for both msg.sender and tx.origin so storageInit path allows setAddress
        vm.startPrank(GUARDIAN, GUARDIAN);
        store = new RocketStorage();
        balances = new RocketNetworkBalancesMock();
        depositSettings = new RocketDAOProtocolSettingsDepositMock();
        networkSettings = new RocketDAOProtocolSettingsNetworkMock();
        vault = new RocketVaultMock();
        queue = new RocketMinipoolQueueMock();

        reth = new RocketTokenRETH(store);
        _setContract("rocketTokenRETH", address(reth));
        _setContract("rocketVault", address(vault));
        _setContract("rocketNetworkBalances", address(balances));
        _setContract("rocketDAOProtocolSettingsDeposit", address(depositSettings));
        _setContract("rocketDAOProtocolSettingsNetwork", address(networkSettings));
        _setContract("rocketMinipoolQueue", address(queue));

        pool = new RocketDepositPool(store);
        _setContract("rocketDepositPool", address(pool));
        vm.stopPrank();

        // Empty network → 1:1 rate (upstream formula when reth supply 0)
        balances.setBalances(0, 0);
        networkSettings.setTargetRethCollateralRate(0);
        depositSettings.setAssignDepositsEnabled(false);
        depositSettings.setDepositEnabled(true);
        depositSettings.setMaximumDepositPoolSize(1000 ether);
    }

    function _setContract(string memory name, address addr) internal {
        bytes32 key = keccak256(abi.encodePacked("contract.address", name));
        store.setAddress(key, addr);
        store.setBool(keccak256(abi.encodePacked("contract.exists", addr)), true);
    }

    function test_Domain_DepositMintsRETH_ViaOnlyLatestContract() public {
        vm.deal(address(this), 5 ether);
        uint256 beforeBal = reth.balanceOf(address(this));
        pool.deposit{value: 1 ether}();
        uint256 minted = reth.balanceOf(address(this)) - beforeBal;
        assertGt(minted, 0, "rETH minted via full vendored deposit pool");
        assertEq(minted, 1 ether, "1:1 mint at empty network");
    }

    function test_Domain_ExchangeRate_UsesNetworkBalances() public {
        // After minting some rETH, set balances for rate formula
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
        depositSettings.setMaximumDepositPoolSize(0.5 ether);
        vm.deal(address(this), 2 ether);
        vm.expectRevert(bytes("The deposit pool size after depositing exceeds the maximum size"));
        pool.deposit{value: 1 ether}();
    }

    function test_Domain_GetMaximumDepositAmount() public {
        depositSettings.setMaximumDepositPoolSize(10 ether);
        assertEq(pool.getMaximumDepositAmount(), 10 ether);
        depositSettings.setDepositEnabled(false);
        assertEq(pool.getMaximumDepositAmount(), 0);
    }
}
