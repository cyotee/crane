// SPDX-License-Identifier: GPL-2.0-or-later
// Ported from morpho-org/morpho-blue@55d2d99304fb3fb930c688462ae2ccabb1d533ad (v1.0.0) — path: test/forge/helpers/Math.sol
pragma solidity ^0.8.0;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256) {
        return x <= y ? 0 : x - y;
    }
}
