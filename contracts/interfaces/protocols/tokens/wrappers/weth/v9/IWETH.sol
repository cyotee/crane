// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { IWETH as BalancerIWETH } from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";

/// @notice Crane-canonical WETH interface.
/// @dev Alias of Balancer's IWETH (deposit/withdraw/transfer/approve).
interface IWETH is BalancerIWETH {}
