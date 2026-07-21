// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IRateProvider} from "@crane/contracts/protocols/dexes/balancer/common/interfaces/IRateProvider.sol";

/**
 * @title IStakingRateProvider
 * @notice Thin alias documenting that staking rate helpers implement Balancer `IRateProvider`.
 * @dev `getRate()` returns an 18-decimal fixed-point exchange rate of the LST/wrapper to underlying ETH (or protocol asset).
 */
interface IStakingRateProvider is IRateProvider {}
