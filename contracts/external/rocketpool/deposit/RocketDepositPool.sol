// SPDX-License-Identifier: GPL-3.0-only
// Domain: rocket-pool/rocketpool contracts/contract/deposit/RocketDepositPool.sol
// Pin: see staking/ethereum/rocket-pool/README.md
// Narrowed: user deposit() → fee → rETH.mint; getBalance/getMaximumDepositAmount/getExcessBalance.
// Megapool/minipool assignment, vault recycle, node credit queues deferred (documented cut).
pragma solidity ^0.8.0;

import {RocketBase} from "@crane/contracts/external/rocketpool/base/RocketBase.sol";
import {RocketStorageInterface} from "@crane/contracts/external/rocketpool/interface/RocketStorageInterface.sol";
import {RocketDepositPoolInterface} from
    "@crane/contracts/external/rocketpool/interface/deposit/RocketDepositPoolInterface.sol";
import {RocketTokenRETHInterface} from
    "@crane/contracts/external/rocketpool/interface/token/RocketTokenRETHInterface.sol";
import {RocketDAOProtocolSettingsDepositInterface} from
    "@crane/contracts/external/rocketpool/interface/dao/RocketDAOProtocolSettingsDepositInterface.sol";

/// @notice Accepts user deposits and mints rETH (upstream deposit path core)
contract RocketDepositPool is RocketBase, RocketDepositPoolInterface {
    event DepositReceived(address indexed from, uint256 amount, uint256 time);

    RocketTokenRETHInterface public immutable rocketTokenRETH;

    /// @dev ETH held as deposit pool user balance (upstream uses RocketVault; we keep balance here for narrow subgraph)
    uint256 private depositBalance;

    constructor(RocketStorageInterface _rocketStorageAddress, address _reth)
        RocketBase(_rocketStorageAddress)
    {
        version = 4;
        rocketTokenRETH = RocketTokenRETHInterface(_reth);
    }

    /// @inheritdoc RocketDepositPoolInterface
    function getBalance() public view override returns (uint256) {
        return depositBalance;
    }

    /// @inheritdoc RocketDepositPoolInterface
    function getExcessBalance() public view override returns (uint256) {
        // No minipool queue in narrow subgraph → all balance is excess-eligible for collateral views
        return depositBalance;
    }

    /// @inheritdoc RocketDepositPoolInterface
    function getMaximumDepositAmount() external view override returns (uint256) {
        RocketDAOProtocolSettingsDepositInterface settings = RocketDAOProtocolSettingsDepositInterface(
            getContractAddress("rocketDAOProtocolSettingsDeposit")
        );
        if (!settings.getDepositEnabled()) return 0;
        uint256 depositPoolBalance = getBalance();
        uint256 maxCapacity = settings.getMaximumDepositPoolSize();
        if (depositPoolBalance >= maxCapacity) return 0;
        return maxCapacity - depositPoolBalance;
    }

    /// @inheritdoc RocketDepositPoolInterface
    function deposit() external payable override {
        RocketDAOProtocolSettingsDepositInterface settings = RocketDAOProtocolSettingsDepositInterface(
            getContractAddress("rocketDAOProtocolSettingsDeposit")
        );
        require(settings.getDepositEnabled(), "Deposits into Rocket Pool are currently disabled");
        require(msg.value >= settings.getMinimumDeposit(), "The deposited amount is less than the minimum deposit size");

        uint256 capacityNeeded = getBalance() + msg.value;
        uint256 maxDepositPoolSize = settings.getMaximumDepositPoolSize();
        require(capacityNeeded <= maxDepositPoolSize, "The deposit pool size after depositing exceeds the maximum size");

        uint256 depositFee = (msg.value * settings.getDepositFee()) / calcBase;
        uint256 depositNet = msg.value - depositFee;

        depositBalance += msg.value;
        // Forward net ETH as rETH collateral buffer (upstream: vault + processDeposit)
        (bool ok,) = address(rocketTokenRETH).call{value: depositNet}("");
        require(ok, "rETH ETH forward failed");

        rocketTokenRETH.mint(depositNet, msg.sender);
        emit DepositReceived(msg.sender, msg.value, block.timestamp);
    }

    /// @inheritdoc RocketDepositPoolInterface
    function recycleExcessCollateral() external payable override {
        depositBalance += msg.value;
    }
}
