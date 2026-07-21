// SPDX-License-Identifier: GPL-3.0-only
// Domain vendor of rocket-pool deposit surface (RocketDepositPool.sol) — deposit→mint rETH path.
// Upstream full file kept as RocketDepositPool.upstream.sol.txt; narrowed to mint/wrap user path.

pragma solidity ^0.8.0;

interface IRocketTokenRETHMint {
    function mint(uint256 _ethAmount, address _to) external;
    function getRethValue(uint256 _ethAmount) external view returns (uint256);
}

/**
 * @title RocketDepositPool
 * @notice Minimal deposit pool: accepts ETH and mints rETH via RocketTokenRETH.mint.
 */
contract RocketDepositPool {
    IRocketTokenRETHMint public immutable reth;
    uint256 public balance;
    uint256 public maximumDepositAmount = type(uint256).max;

    constructor(address _reth) {
        reth = IRocketTokenRETHMint(_reth);
    }

    function setMaximumDepositAmount(uint256 _max) external {
        maximumDepositAmount = _max;
    }

    function getBalance() external view returns (uint256) {
        return balance;
    }

    function getMaximumDepositAmount() external view returns (uint256) {
        return maximumDepositAmount;
    }

    function deposit() external payable {
        require(msg.value > 0, "Invalid deposit amount");
        require(msg.value <= maximumDepositAmount, "The deposit pool size after depositing exceeds the maximum size");
        balance += msg.value;
        // Forward ETH backing to rETH contract for burn liquidity
        (bool ok,) = address(reth).call{value: msg.value}("");
        require(ok, "ETH to rETH failed");
        reth.mint(msg.value, msg.sender);
    }
}
