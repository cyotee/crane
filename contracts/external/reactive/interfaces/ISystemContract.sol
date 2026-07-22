// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

import '@crane/contracts/external/reactive/interfaces/IPayable.sol';
import '@crane/contracts/external/reactive/interfaces/ISubscriptionService.sol';

/// @title Interface for the Reactive Network's system contract.
interface ISystemContract is IPayable, ISubscriptionService {
}
