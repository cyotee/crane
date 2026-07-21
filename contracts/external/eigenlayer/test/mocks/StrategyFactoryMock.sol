// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/IERC20.sol";
import "src/contracts/interfaces/IStrategyFactory.sol";

/// @notice Mock StrategyFactory that returns false for isBlacklisted by default.
contract StrategyFactoryMock {
    mapping(IERC20 => bool) public isBlacklisted;

    function setIsBlacklisted(IERC20 token, bool blacklisted) external {
        isBlacklisted[token] = blacklisted;
    }
}

