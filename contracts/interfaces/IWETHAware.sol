// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";

interface IWETHAware {
    function weth() external view returns (IWETH);
}
