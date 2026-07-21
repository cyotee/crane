// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.24;

// Re-export existing Crane FraxETH interfaces under the staking tree.
import {IfrxETH} from "@crane/contracts/protocols/tokens/stable/frax/FraxETH/IfrxETH.sol";
import {IfrxETHMinter} from "@crane/contracts/protocols/tokens/stable/frax/FraxETH/IfrxETHMinter.sol";
import {IsfrxETH} from "@crane/contracts/protocols/tokens/stable/frax/FraxETH/IsfrxETH.sol";

/// @dev Canonical aliases for staking/ethereum/frax consumers.
interface IFraxETH is IfrxETH {}
interface IFraxETHMinter is IfrxETHMinter {}
interface ISfrxETH is IsfrxETH {}
