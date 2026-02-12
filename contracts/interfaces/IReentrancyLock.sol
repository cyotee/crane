// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

interface IReentrancyLock {
    error IsLocked();

    function isLocked() external view returns (bool);
}
