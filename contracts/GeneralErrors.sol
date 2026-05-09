// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @dev To be thrown when a function argument must not be 0.
 */
error ArgumentMustNotBeZero(uint256 argument);

error ArgumentMustBeGreaterThan(uint256 greaterArg, uint256 lesserArg);

error InvalidPageSize(uint256 start, uint256 end);
