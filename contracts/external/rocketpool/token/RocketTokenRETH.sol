// SPDX-License-Identifier: GPL-3.0-only
// Domain: rocket-pool/rocketpool contracts/contract/token/RocketTokenRETH.sol
// Pin: see staking/ethereum/rocket-pool/README.md
// Adapted: pragma 0.7.6 → ^0.8.0; SafeMath → native; util ERC20 → Crane OZ ERC20;
// RocketBase + RocketStorage address book preserved (onlyLatestContract mint gate).
pragma solidity ^0.8.0;

import {ERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";
import {RocketBase} from "@crane/contracts/external/rocketpool/base/RocketBase.sol";
import {RocketStorageInterface} from "@crane/contracts/external/rocketpool/interface/RocketStorageInterface.sol";
import {RocketNetworkBalancesInterface} from
    "@crane/contracts/external/rocketpool/interface/network/RocketNetworkBalancesInterface.sol";
import {RocketDepositPoolInterface} from
    "@crane/contracts/external/rocketpool/interface/deposit/RocketDepositPoolInterface.sol";
import {RocketTokenRETHInterface} from
    "@crane/contracts/external/rocketpool/interface/token/RocketTokenRETHInterface.sol";

/// @notice rETH — tokenised stake; exchange rate from network balances (upstream formulas)
contract RocketTokenRETH is RocketBase, ERC20, RocketTokenRETHInterface {
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 ethAmount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 ethAmount, uint256 time);

    constructor(RocketStorageInterface _rocketStorageAddress)
        RocketBase(_rocketStorageAddress)
        ERC20("Rocket Pool ETH", "rETH")
    {
        version = 1;
    }

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    /// @inheritdoc RocketTokenRETHInterface
    function getEthValue(uint256 _rethAmount) public view override returns (uint256) {
        RocketNetworkBalancesInterface balances =
            RocketNetworkBalancesInterface(getContractAddress("rocketNetworkBalances"));
        uint256 totalEthBalance = balances.getTotalETHBalance();
        uint256 rethSupply = balances.getTotalRETHSupply();
        if (rethSupply == 0) return _rethAmount;
        return (_rethAmount * totalEthBalance) / rethSupply;
    }

    /// @inheritdoc RocketTokenRETHInterface
    function getRethValue(uint256 _ethAmount) public view override returns (uint256) {
        RocketNetworkBalancesInterface balances =
            RocketNetworkBalancesInterface(getContractAddress("rocketNetworkBalances"));
        uint256 totalEthBalance = balances.getTotalETHBalance();
        uint256 rethSupply = balances.getTotalRETHSupply();
        if (rethSupply == 0) return _ethAmount;
        require(totalEthBalance > 0, "Cannot calculate rETH token amount while total network balance is zero");
        return (_ethAmount * rethSupply) / totalEthBalance;
    }

    /// @inheritdoc RocketTokenRETHInterface
    function getExchangeRate() external view override returns (uint256) {
        return getEthValue(1 ether);
    }

    /// @inheritdoc RocketTokenRETHInterface
    function getTotalCollateral() public view override returns (uint256) {
        RocketDepositPoolInterface depositPool =
            RocketDepositPoolInterface(getContractAddress("rocketDepositPool"));
        return depositPool.getExcessBalance() + address(this).balance;
    }

    /// @inheritdoc RocketTokenRETHInterface
    function getCollateralRate() public view override returns (uint256) {
        uint256 totalEthValue = getEthValue(totalSupply());
        if (totalEthValue == 0) return calcBase;
        return (calcBase * address(this).balance) / totalEthValue;
    }

    /// @inheritdoc RocketTokenRETHInterface
    function depositExcess() external payable override onlyLatestContract("rocketDepositPool", msg.sender) {
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    /// @inheritdoc RocketTokenRETHInterface
    function mint(uint256 _ethAmount, address _to)
        external
        override
        onlyLatestContract("rocketDepositPool", msg.sender)
    {
        uint256 rethAmount = getRethValue(_ethAmount);
        require(rethAmount > 0, "Invalid token mint amount");
        _mint(_to, rethAmount);
        emit TokensMinted(_to, rethAmount, _ethAmount, block.timestamp);
    }

    /// @inheritdoc RocketTokenRETHInterface
    function burn(uint256 _rethAmount) external override {
        require(_rethAmount > 0, "Invalid token burn amount");
        require(balanceOf(msg.sender) >= _rethAmount, "Insufficient rETH balance");
        uint256 ethAmount = getEthValue(_rethAmount);
        uint256 ethBalance = getTotalCollateral();
        require(ethBalance >= ethAmount, "Insufficient ETH balance for exchange");
        _burn(msg.sender, _rethAmount);
        // Prefer contract balance; pull excess from deposit pool if short
        if (address(this).balance < ethAmount) {
            // recycle path omitted in narrow subgraph — require on-contract ETH
            revert("Insufficient rETH contract ETH");
        }
        (bool ok,) = msg.sender.call{value: ethAmount}("");
        require(ok, "ETH transfer failed");
        emit TokensBurned(msg.sender, _rethAmount, ethAmount, block.timestamp);
    }
}
