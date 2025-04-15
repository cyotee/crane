// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IReentrancyLock {

    error IsLocked();

    function isLocked()
    external view returns(bool);

}
