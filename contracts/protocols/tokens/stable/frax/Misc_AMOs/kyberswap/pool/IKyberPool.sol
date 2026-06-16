// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.35;

import {IPoolActions} from "./IPoolActions.sol";
import {IPoolEvents} from "./IPoolEvents.sol";
import {IPoolStorage} from "./IPoolStorage.sol";

interface IKyberPool is IPoolActions, IPoolEvents, IPoolStorage {}
