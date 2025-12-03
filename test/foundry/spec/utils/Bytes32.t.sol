// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/Bytes32.sol";

contract Bytes32Test is Test {
    using Bytes32 for bytes32;

    function test_scramble_behavior() public view {
        bytes32 v = bytes32(uint256(0x1111111111111111111111111111111111111111111111111111111111111111));
        bytes32 scrambled = Bytes32._scramble(v);

        // compute expected: value ^ (keccak(address(this)) - 1)
        bytes32 expected = bytes32(uint256(v) ^ (uint256(keccak256(abi.encodePacked(address(this)))) - 1));
        assertEq(uint256(scrambled), uint256(expected));
    }

    function test_toAddress_roundtrip() public pure {
        address a = address(0x1234567890123456789012345678901234567890);
        bytes32 packed = bytes32(uint256(uint160(a)));
        address out = Bytes32._toAddress(packed);
        assertEq(out, a);
    }

    function test_toHexString_known() public pure {
        bytes32 v = bytes32(uint256(0x00000000000000000000000000000000000000000000000000000000deadbeef));
        string memory s = Bytes32._toHexString(v);
        assertEq(s, "0x00000000000000000000000000000000000000000000000000000000deadbeef");
        // check prefix and length
        bytes memory bs = bytes(s);
        assertEq(bs[0], bytes1("0"));
        assertEq(bs[1], bytes1("x"));
        assertEq(bs.length, 66);
    }

    function test_partions_extract_insert() public pure {
        bytes4 p0 = bytes4(0x01020304);
        bytes4 p1 = bytes4(0x05060708);
        bytes4 p2 = bytes4(0x11121314);

        bytes4[] memory parts = new bytes4[](3);
        parts[0] = p0;
        parts[1] = p1;
        parts[2] = p2;

        bytes32 packed = Bytes32._packEqualPartitions(parts);

        // verify partitions
        bytes4[] memory partitions = Bytes32._equalPartitions(packed);
        assertEq(uint32(partitions.length), uint32(8));
        assertEq(uint32(partitions[0]), uint32(p0));
        assertEq(uint32(partitions[1]), uint32(p1));
        assertEq(uint32(partitions[2]), uint32(p2));
        // remaining should be zero
        for (uint256 i = 3; i < 8; i++) {
            assertEq(uint32(partitions[i]), uint32(bytes4(0)));
        }

        // test extract
        assertEq(uint32(Bytes32._extractEqPartition(packed, 0)), uint32(p0));
        assertEq(uint32(Bytes32._extractEqPartition(packed, 1)), uint32(p1));
        assertEq(uint32(Bytes32._extractEqPartition(packed, 2)), uint32(p2));

        // test insert
        bytes4 newPart = bytes4(0xdeadbeef);
        bytes32 modified = Bytes32._insertEqPartition(packed, newPart, 1);
        assertEq(uint32(Bytes32._extractEqPartition(modified, 1)), uint32(newPart));
    }
}
