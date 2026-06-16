// SPDX-License-Identifier: LicenseRef-BUSL
pragma solidity ^0.8.0;

import {IIntentConsumer} from "@crane/contracts/protocols/lending/aave/v4/interfaces/IIntentConsumer.sol";
import {
    IPositionManagerBase
} from "@crane/contracts/protocols/lending/aave/v4/position-manager/interfaces/IPositionManagerBase.sol";

/// @title IPositionManagerIntentBase
/// @author Aave Labs
/// @notice Interface to extend PositionManagerBase with intent consuming capabilities.
interface IPositionManagerIntentBase is IIntentConsumer, IPositionManagerBase {}
