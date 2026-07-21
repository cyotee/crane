// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IEthVault} from "@crane/contracts/protocols/staking/ethereum/stakewise/interfaces/IEthVault.sol";
import {IOsTokenVaultController} from
    "@crane/contracts/protocols/staking/ethereum/stakewise/interfaces/IOsTokenVaultController.sol";
import {StakeWiseService} from
    "@crane/contracts/protocols/staking/ethereum/stakewise/services/StakeWiseService.sol";
import {OsETHRateProvider} from
    "@crane/contracts/protocols/staking/ethereum/stakewise/rate/OsETHRateProvider.sol";
import {
    TestBase_EthereumStakingFork,
    EthereumStakingAddresses
} from "./TestBase_EthereumStakingFork.sol";

contract StakeWiseServiceHarness {
    function deposit(IEthVault vault, address receiver, address referrer)
        external
        payable
        returns (uint256)
    {
        return StakeWiseService._deposit(vault, receiver, referrer);
    }

    function osEthRate(IOsTokenVaultController controller) external view returns (uint256) {
        return StakeWiseService._osEthRate(controller);
    }
}

contract StakeWiseServiceFork is TestBase_EthereumStakingFork {
    StakeWiseServiceHarness internal harness;
    IOsTokenVaultController internal controller;
    OsETHRateProvider internal rateProvider;
    IEthVault internal vault;

    /// @dev Public mainnet vaults with convertToShares (Genesis + secondary)
    address internal constant VAULT_A = EthereumStakingAddresses.STAKEWISE_GENESIS_VAULT;
    address internal constant VAULT_B = 0xe6d8d8aC54461b1C5eD15740EEe322043F696C08;

    function setUp() public {
        if (!_forkEthereum()) return;
        harness = new StakeWiseServiceHarness();
        controller = IOsTokenVaultController(EthereumStakingAddresses.OS_TOKEN_VAULT_CONTROLLER);
        rateProvider = new OsETHRateProvider(controller);
        vault = IEthVault(_selectPublicVault());
        _dealETH(address(this), 50 ether);
    }

    function _selectPublicVault() internal view returns (address selected) {
        if (_vaultHasConvertToShares(VAULT_A)) return VAULT_A;
        if (_vaultHasConvertToShares(VAULT_B)) return VAULT_B;
        revert("no StakeWise public vault with convertToShares");
    }

    function _vaultHasConvertToShares(address v) internal view returns (bool) {
        (bool ok, bytes memory data) =
            v.staticcall(abi.encodeWithSignature("convertToShares(uint256)", uint256(1 ether)));
        if (!ok || data.length < 32) return false;
        return abi.decode(data, (uint256)) > 0;
    }

    function test_Fork_OsETH_RateReadable() public {
        uint256 rate = rateProvider.getRate();
        assertGt(rate, 0, "osETH rate > 0");
        assertEq(rate, harness.osEthRate(controller), "provider matches controller");
        assertEq(rate, controller.convertToAssets(1e18));
    }

    /// @notice §7.3: vault deposit must increase shares (hard fail — no soft-pass).
    function test_Fork_VaultDeposit_IncreasesShares() public {
        uint256 amount = 0.2 ether;
        uint256 preview = vault.convertToShares(amount);
        assertGt(preview, 0, "convertToShares > 0 for deposit amount");

        // Prefer totalAssets/totalSupply style accounting; fall back to raw call return.
        uint256 shares = harness.deposit{value: amount}(vault, address(this), address(0));
        assertGt(shares, 0, "vault deposit must mint shares");
        // Shares should track preview within 1% (rate can move slightly in same block path)
        assertApproxEqAbs(shares, preview, preview / 100 + 1, "shares ~ convertToShares preview");
    }
}
