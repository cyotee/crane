// SPDX-License-Identifier: GPL-3.0-only
// Domain vendor of rocket-pool/rocketpool contracts/contract/token/RocketTokenRETH.sol
// Upstream pin documented in staking/ethereum/rocket-pool/README.md.
// Adapted: pragma 0.7.6 → ^0.8.0; SafeMath → native 0.8; ERC20 from Crane OZ;
// network balances injected via constructor for hermetic domain tests (mainnet uses RocketStorage).
// Exchange-rate math (getEthValue/getRethValue/getExchangeRate) matches upstream formulas.

pragma solidity ^0.8.0;

import {ERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/ERC20.sol";

/**
 * @title RocketTokenRETH
 * @notice rETH domain with upstream exchange-rate formulas.
 */
contract RocketTokenRETH is ERC20 {
    event EtherDeposited(address indexed from, uint256 amount, uint256 time);
    event TokensMinted(address indexed to, uint256 amount, uint256 ethAmount, uint256 time);
    event TokensBurned(address indexed from, uint256 amount, uint256 ethAmount, uint256 time);

    uint256 public totalEthBalance;
    uint256 public totalRETHSupply;
    address public depositPool;

    constructor() ERC20("Rocket Pool ETH", "rETH") {}

    receive() external payable {
        emit EtherDeposited(msg.sender, msg.value, block.timestamp);
    }

    function setNetworkBalances(uint256 _totalEthBalance, uint256 _totalRETHSupply) external {
        totalEthBalance = _totalEthBalance;
        totalRETHSupply = _totalRETHSupply;
    }

    function setDepositPool(address _depositPool) external {
        depositPool = _depositPool;
    }

    /// @dev Upstream: _rethAmount * totalEth / rethSupply (1:1 if supply 0)
    function getEthValue(uint256 _rethAmount) public view returns (uint256) {
        if (totalRETHSupply == 0) return _rethAmount;
        return (_rethAmount * totalEthBalance) / totalRETHSupply;
    }

    /// @dev Upstream: _ethAmount * rethSupply / totalEth (1:1 if eth 0)
    function getRethValue(uint256 _ethAmount) public view returns (uint256) {
        if (totalEthBalance == 0) return _ethAmount;
        return (_ethAmount * totalRETHSupply) / totalEthBalance;
    }

    /// @dev Upstream: 1 ether of rETH in ETH terms * 1e18 scaling via getEthValue(1e18)
    function getExchangeRate() public view returns (uint256) {
        return getEthValue(1 ether);
    }

    function mint(uint256 _ethAmount, address _to) external {
        require(msg.sender == depositPool, "Invalid token minter");
        uint256 rethAmount = getRethValue(_ethAmount);
        require(rethAmount > 0, "Invalid token mint amount");
        _mint(_to, rethAmount);
        totalRETHSupply = totalSupply();
        totalEthBalance += _ethAmount;
        emit TokensMinted(_to, rethAmount, _ethAmount, block.timestamp);
    }

    function burn(uint256 _rethAmount) external {
        require(_rethAmount > 0, "Invalid token burn amount");
        uint256 ethAmount = getEthValue(_rethAmount);
        _burn(msg.sender, _rethAmount);
        totalRETHSupply = totalSupply();
        totalEthBalance -= ethAmount;
        (bool ok,) = msg.sender.call{value: ethAmount}("");
        require(ok, "ETH transfer failed");
        emit TokensBurned(msg.sender, _rethAmount, ethAmount, block.timestamp);
    }
}
