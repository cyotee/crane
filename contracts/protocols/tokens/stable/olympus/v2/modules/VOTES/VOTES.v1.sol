// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.15;

import {ERC4626} from "@crane/contracts/external/solmate/mixins/ERC4626.sol";
import {ERC20} from "@crane/contracts/external/solmate/tokens/ERC20.sol";

import "@crane/contracts/protocols/tokens/stable/olympus/v2/Kernel.sol";

abstract contract VOTESv1 is Module, ERC4626 {
    // =========  STATE ========= //

    ERC20 public gOHM;
    mapping(address => uint256) public lastActionTimestamp;
    mapping(address => uint256) public lastDepositTimestamp;

    // =========  FUNCTIONS ========= //

    function resetActionTimestamp(address wallet_) external virtual;
}
