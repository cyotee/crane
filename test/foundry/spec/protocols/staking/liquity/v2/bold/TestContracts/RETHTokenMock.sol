// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

import "@crane/contracts/protocols/staking/liquity/v2/bold/Interfaces/IRETHToken.sol";
import "forge-std/console2.sol";

contract RETHTokenMock is IRETHToken {
    uint256 ethPerReth;

    function getExchangeRate() external view returns (uint256) {
        return ethPerReth;
    }

    function setExchangeRate(uint256 _ethPerReth) external {
        ethPerReth = _ethPerReth;
    }
}
