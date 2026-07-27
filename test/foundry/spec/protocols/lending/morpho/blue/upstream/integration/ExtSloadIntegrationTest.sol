// SPDX-License-Identifier: GPL-2.0-or-later
// Ported from morpho-org/morpho-blue@55d2d99304fb3fb930c688462ae2ccabb1d533ad (v1.0.0) — path: test/forge/integration/ExtSloadIntegrationTest.sol
pragma solidity ^0.8.0;

import "../BaseTest.sol";

contract ExtSloadIntegrationTest is BaseTest {
    function testExtSloads(uint256 slot, bytes32 value0) public {
        bytes32[] memory slots = new bytes32[](2);
        slots[0] = bytes32(slot);
        slots[1] = bytes32(slot / 2);

        bytes32 value1 = keccak256(abi.encode(value0));
        vm.store(address(morpho), slots[0], value0);
        vm.store(address(morpho), slots[1], value1);

        bytes32[] memory values = morpho.extSloads(slots);

        assertEq(values.length, 2, "values.length");
        assertEq(values[0], slot > 0 ? value0 : value1, "value0");
        assertEq(values[1], value1, "value1");
    }
}
