// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {BetterBytes} from "contracts/utils/BetterBytes.sol";

contract StorageHolder {
    bytes public s;

    function set(bytes memory b) public {
        s = b;
    }

    function equalTo(bytes memory b) public view returns (bool) {
        return BetterBytes._equalStorage(s, b);
    }
}

contract BetterBytesRevertHarness {
    function callToAddress(bytes memory b, uint256 start) external pure returns (address) {
        return BetterBytes._toAddress(b, start);
    }

    function callToUint16(bytes memory b, uint256 start) external pure returns (uint16) {
        return BetterBytes._toUint16(b, start);
    }
}

contract BetterBytesTest is Test {
    using BetterBytes for bytes;

    function test_indexOf_and_indexOf_fromPos() public pure {
        bytes memory buf = "hello world";
        // 'o' first at 4, second at 7
        assertEq(BetterBytes._indexOf(buf, bytes1("o")), 4);
        assertEq(BetterBytes._indexOf(buf, bytes1("o"), 5), 7);
    }

    function test_lastIndexOf_and_fromPos() public pure {
        bytes memory buf = "abca";
        // last 'a' is at index 3
        assertEq(BetterBytes._lastIndexOf(buf, bytes1("a")), 3);
        // searching backwards from pos 2 finds index 0
        assertEq(BetterBytes._lastIndexOf(buf, bytes1("a"), 2), 0);
    }

    function test_slice_start_and_slice_start_end() public pure {
        bytes memory data = hex"01020304";
        bytes memory s1 = BetterBytes._slice(data, 1);
        assertEq(s1, hex"020304");

        bytes memory s2 = BetterBytes._slice(data, 1, 3);
        // should return bytes at indexes 1 and 2
        assertEq(s2, hex"0203");
    }

    function test_prependToArray_putsValueFirst() public pure {
        bytes[] memory arr = new bytes[](2);
        arr[0] = hex"01";
        arr[1] = hex"02";
        bytes[] memory out = BetterBytes._prependToArray(hex"00", arr);
        assertEq(out.length, 3);
        assertEq(out[0], hex"00");
        assertEq(out[1], hex"01");
        assertEq(out[2], hex"02");
    }

    function test_toAddress_roundtrip() public pure {
        address expected = address(bytes20(hex"1234567890abcdef1234567890abcdef12345678"));
        bytes memory b = abi.encodePacked(expected);
        address got = BetterBytes._toAddress(b, 0);
        assertEq(got, expected);
    }

    function test_toHexString_prefixAndChars() public pure {
        bytes memory b = hex"0a1b";
        string memory s = BetterBytes._toHexString(b);
        assertEq(s, string("0x0a1b"));
    }

    function test_toUint_variants() public pure {
        bytes memory b1 = abi.encodePacked(uint8(0x7f));
        assertEq(BetterBytes._toUint8(b1, 0), uint8(0x7f));

        bytes memory b2 = abi.encodePacked(uint16(0x1234));
        assertEq(BetterBytes._toUint16(b2, 0), uint16(0x1234));

        bytes memory b4 = abi.encodePacked(uint32(0xabcdef01));
        assertEq(BetterBytes._toUint32(b4, 0), uint32(0xabcdef01));

        bytes memory b8 = abi.encodePacked(uint64(0x1122334455667788));
        assertEq(BetterBytes._toUint64(b8, 0), uint64(0x1122334455667788));

        bytes memory b12 = abi.encodePacked(uint96(0x0102030405060708090a0b0c));
        assertEq(BetterBytes._toUint96(b12, 0), uint96(0x0102030405060708090a0b0c));

        bytes memory b16 = abi.encodePacked(uint128(0x11223344556677881122334455667788));
        assertEq(BetterBytes._toUint128(b16, 0), uint128(0x11223344556677881122334455667788));

        bytes memory b32 = abi.encodePacked(uint256(0xdeadbeef));
        assertEq(BetterBytes._toUint256(b32, 0), uint256(0xdeadbeef));
    }

    function test_toBytes32_roundtrip() public pure {
        bytes32 v = bytes32(uint256(0xabcdef));
        bytes memory b = abi.encodePacked(v);
        assertEq(BetterBytes._toBytes32(b, 0), v);
    }

    function test_equal_memory_comparisons() public pure {
        bytes memory a = hex"010203";
        bytes memory b = hex"010203";
        bytes memory c = hex"010204";
        assertTrue(BetterBytes._equal(a, b));
        assertTrue(!BetterBytes._equal(a, c));
    }

    function test_equalStorage_matchesMemory() public {
        StorageHolder sh = new StorageHolder();
        bytes memory mem = hex"cafebabe";
        sh.set(mem);
        assertTrue(sh.equalTo(mem));

        bytes memory other = hex"deadbeef";
        assertTrue(!sh.equalTo(other));
    }

    // Bounds checks: ensure functions revert on out of bounds accesses
    function test_toUint_outOfBounds_revert() public {
        bytes memory small = hex"01";
        BetterBytesRevertHarness h = new BetterBytesRevertHarness();
        vm.expectRevert();
        h.callToUint16(small, 0);
    }

    function test_toAddress_outOfBounds_revert() public {
        bytes memory small = hex"01";
        BetterBytesRevertHarness h = new BetterBytesRevertHarness();
        vm.expectRevert();
        h.callToAddress(small, 0);
    }

    /* -------------------------------------------------------------------------- */
    /*                         Additional Edge Case Tests                         */
    /* -------------------------------------------------------------------------- */

    function test_indexOf_notFound_returnsMax() public pure {
        bytes memory buf = "hello";
        assertEq(BetterBytes._indexOf(buf, bytes1("z")), type(uint256).max);
    }

    function test_indexOf_emptyBytes_returnsMax() public pure {
        bytes memory buf = "";
        assertEq(BetterBytes._indexOf(buf, bytes1("a")), type(uint256).max);
    }

    function test_lastIndexOf_notFound_returnsMax() public pure {
        bytes memory buf = "hello";
        assertEq(BetterBytes._lastIndexOf(buf, bytes1("z")), type(uint256).max);
    }

    function test_slice_fromZero_returnsAll() public pure {
        bytes memory data = hex"01020304";
        bytes memory result = BetterBytes._slice(data, 0);
        assertEq(result, data);
    }

    function test_slice_fromEnd_returnsEmpty() public pure {
        bytes memory data = hex"01020304";
        bytes memory result = BetterBytes._slice(data, 4);
        assertEq(result.length, 0);
    }

    function test_sliceRange_sameStartEnd_returnsEmpty() public pure {
        bytes memory data = hex"01020304";
        bytes memory result = BetterBytes._slice(data, 2, 2);
        assertEq(result.length, 0);
    }

    function test_prependToArray_emptyArray_createsOne() public pure {
        bytes[] memory arr = new bytes[](0);
        bytes[] memory out = BetterBytes._prependToArray(hex"01", arr);
        assertEq(out.length, 1);
        assertEq(out[0], hex"01");
    }

    function test_toHexString_emptyBytes_returnsPrefix() public pure {
        bytes memory b = "";
        string memory s = BetterBytes._toHexString(b);
        assertEq(s, "0x");
    }

    function test_toHexString_leadingZeros() public pure {
        bytes memory b = hex"00ff00";
        string memory s = BetterBytes._toHexString(b);
        assertEq(s, "0x00ff00");
    }

    function test_equal_emptyBytes_returnsTrue() public pure {
        bytes memory a = "";
        bytes memory b = "";
        assertTrue(BetterBytes._equal(a, b));
    }

    function test_equal_emptyVsNonEmpty_returnsFalse() public pure {
        bytes memory a = "";
        bytes memory b = hex"01";
        assertFalse(BetterBytes._equal(a, b));
    }

    function test_equal_differentLengths_returnsFalse() public pure {
        bytes memory a = hex"010203";
        bytes memory b = hex"01020304";
        assertFalse(BetterBytes._equal(a, b));
    }

    function test_equal_longBytes_identical() public pure {
        // Test with data longer than 32 bytes
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041";
        bytes memory b = hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041";
        assertTrue(BetterBytes._equal(a, b));
    }

    function test_equal_longBytes_differentAtEnd() public pure {
        bytes memory a = hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041";
        bytes memory b = hex"01020304050607080910111213141516171819202122232425262728293031323334353637383940ff";
        assertFalse(BetterBytes._equal(a, b));
    }

    function test_equalStorage_emptyBytes() public {
        StorageHolder sh = new StorageHolder();
        sh.set("");
        assertTrue(sh.equalTo(""));
    }

    function test_equalStorage_shortBytes_lessThan32() public {
        StorageHolder sh = new StorageHolder();
        bytes memory data = hex"0102030405060708";
        sh.set(data);
        assertTrue(sh.equalTo(data));
    }

    function test_equalStorage_longBytes_greaterThan32() public {
        StorageHolder sh = new StorageHolder();
        bytes memory data = hex"0102030405060708091011121314151617181920212223242526272829303132333435363738394041";
        sh.set(data);
        assertTrue(sh.equalTo(data));
    }

    function test_equalStorage_differentLengths_returnsFalse() public {
        StorageHolder sh = new StorageHolder();
        sh.set(hex"010203");
        assertFalse(sh.equalTo(hex"01020304"));
    }

    function test_toAddress_withOffset() public pure {
        address expected = address(bytes20(hex"1234567890abcdef1234567890abcdef12345678"));
        bytes memory b = abi.encodePacked(bytes4(0xdeadbeef), expected);
        address got = BetterBytes._toAddress(b, 4);
        assertEq(got, expected);
    }

    function test_toBytes32_withOffset() public pure {
        bytes32 v = bytes32(uint256(0xabcdef));
        bytes memory b = abi.encodePacked(bytes4(0x12345678), v);
        assertEq(BetterBytes._toBytes32(b, 4), v);
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    function testFuzz_toHexString_correctLength(bytes memory data) public pure {
        string memory hexStr = BetterBytes._toHexString(data);
        assertEq(bytes(hexStr).length, data.length * 2 + 2);
    }

    function testFuzz_equal_reflexive(bytes memory data) public pure {
        assertTrue(BetterBytes._equal(data, data));
    }

    function testFuzz_slice_validRange(bytes memory data, uint256 start) public pure {
        vm.assume(data.length > 0);
        start = bound(start, 0, data.length);
        bytes memory result = BetterBytes._slice(data, start);
        assertEq(result.length, data.length - start);
    }

    function testFuzz_toAddress_roundtrip(address expected) public pure {
        bytes memory b = abi.encodePacked(expected);
        address got = BetterBytes._toAddress(b, 0);
        assertEq(got, expected);
    }

    function testFuzz_toUint256_roundtrip(uint256 expected) public pure {
        bytes memory b = abi.encodePacked(expected);
        uint256 got = BetterBytes._toUint256(b, 0);
        assertEq(got, expected);
    }

    function testFuzz_toBytes32_roundtrip(bytes32 expected) public pure {
        bytes memory b = abi.encodePacked(expected);
        bytes32 got = BetterBytes._toBytes32(b, 0);
        assertEq(got, expected);
    }

    function testFuzz_prependToArray_increasesLength(bytes memory value, uint8 arrLen) public pure {
        arrLen = uint8(bound(arrLen, 0, 10));
        bytes[] memory arr = new bytes[](arrLen);
        for (uint256 i = 0; i < arrLen; i++) {
            arr[i] = abi.encodePacked(i);
        }
        bytes[] memory result = BetterBytes._prependToArray(value, arr);
        assertEq(result.length, arr.length + 1);
        assertEq(result[0], value);
    }
}
