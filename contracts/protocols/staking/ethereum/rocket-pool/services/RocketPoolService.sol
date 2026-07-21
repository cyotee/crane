// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IRETH} from "@crane/contracts/protocols/staking/ethereum/rocket-pool/interfaces/IRETH.sol";
import {IRocketDepositPool} from
    "@crane/contracts/protocols/staking/ethereum/rocket-pool/interfaces/IRocketDepositPool.sol";
import {IRocketStorage} from
    "@crane/contracts/protocols/staking/ethereum/rocket-pool/interfaces/IRocketStorage.sol";

/**
 * @title RocketPoolService
 * @notice deposit ETH→rETH via deposit pool; rate/capacity helpers.
 */
library RocketPoolService {
    error ZeroAddress();
    error ZeroAmount();
    error InsufficientDepositCapacity(uint256 maxDeposit, uint256 amount);

    bytes32 public constant DEPOSIT_POOL_KEY = keccak256(abi.encodePacked("contract.address", "rocketDepositPool"));
    bytes32 public constant RETH_TOKEN_KEY = keccak256(abi.encodePacked("contract.address", "rocketTokenRETH"));

    function _depositPool(IRocketStorage storage_) internal view returns (IRocketDepositPool) {
        return IRocketDepositPool(storage_.getAddress(DEPOSIT_POOL_KEY));
    }

    function _reth(IRocketStorage storage_) internal view returns (IRETH) {
        return IRETH(storage_.getAddress(RETH_TOKEN_KEY));
    }

    function _maxDeposit(IRocketDepositPool pool) internal view returns (uint256) {
        return pool.getMaximumDepositAmount();
    }

    function _deposit(IRocketDepositPool pool, IRETH reth) internal returns (uint256 rethOut) {
        if (address(pool) == address(0) || address(reth) == address(0)) revert ZeroAddress();
        if (msg.value == 0) revert ZeroAmount();
        uint256 maxDep = pool.getMaximumDepositAmount();
        if (msg.value > maxDep) revert InsufficientDepositCapacity(maxDep, msg.value);
        uint256 beforeBal = IERC20(address(reth)).balanceOf(address(this));
        pool.deposit{value: msg.value}();
        rethOut = IERC20(address(reth)).balanceOf(address(this)) - beforeBal;
    }

    function _burn(IRETH reth, uint256 rethAmount) internal {
        if (address(reth) == address(0)) revert ZeroAddress();
        if (rethAmount == 0) revert ZeroAmount();
        reth.burn(rethAmount);
    }

    function _exchangeRate(IRETH reth) internal view returns (uint256) {
        return reth.getExchangeRate();
    }
}
