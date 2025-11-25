// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "src/utils/Bytes4.sol";

contract Bytes4Test is Test {
	using Bytes4 for bytes4;

	function toU32(bytes4 v) internal pure returns (uint32) {
		return uint32(v);
	}

	function test_xor_pair() public pure {
		bytes4 a = bytes4(0x01020304);
		bytes4 b = bytes4(0x04030201);
		bytes4 expected = bytes4(0x05010105);

		bytes4 result = Bytes4._xor(a, b);
		assertEq(toU32(result), toU32(expected));

		// xor with zero returns the original
		bytes4 zero = bytes4(0);
		bytes4 identity = Bytes4._xor(a, zero);
		assertEq(toU32(identity), toU32(a));
	}

	function test_xor_array() public pure {
		// empty array should return zero
		bytes4[] memory empty = new bytes4[](0);
		bytes4 emptyRes = Bytes4._xor(empty);
		assertEq(toU32(emptyRes), toU32(bytes4(0)));

		// single-element array should return that element
		bytes4[] memory single = new bytes4[](1);
		single[0] = bytes4(0xdeadbeef);
		bytes4 singleRes = Bytes4._xor(single);
		assertEq(toU32(singleRes), toU32(single[0]));

		// multi-element array
		bytes4 a = bytes4(0x01020304);
		bytes4 b = bytes4(0x0a0b0c0d);
		bytes4 c = bytes4(0xffffffff);
		bytes4[] memory multi = new bytes4[](3);
		multi[0] = a;
		multi[1] = b;
		multi[2] = c;

		// compute expected using bitwise XOR on uint32 to avoid depending on library
		uint32 expectedU = uint32(a) ^ uint32(b) ^ uint32(c);
		bytes4 expected = bytes4(expectedU);

		bytes4 multiRes = Bytes4._xor(multi);
		assertEq(toU32(multiRes), toU32(expected));
	}

	function test_toHexString() public pure {
		bytes4 v = bytes4(0xdeadbeef);
		string memory s = Bytes4._toHexString(v);
		assertEq(s, "0xdeadbeef");

		// additional sanity checks
		assertEq(Bytes4._toHexString(bytes4(0x00000000)), "0x00000000");
		assertEq(Bytes4._toHexString(bytes4(0xffffffff)), "0xffffffff");
	}

	function test_toString_behavior() public pure {
		// Current implementation returns "0x" + raw bytes cast to string.
		bytes4 v = bytes4(0x01020304);
		string memory s = Bytes4._toString(v);
		bytes memory bs = bytes(s);

		// Expect prefix "0x" then 4 raw bytes -> total length 6
		assertEq(bs.length, 6);
		assertEq(bs[0], bytes1('0'));
		assertEq(bs[1], bytes1('x'));

		// Verify the subsequent bytes match the original bytes (in order)
		assertEq(bs[2], bytes1(uint8(0x01)));
		assertEq(bs[3], bytes1(uint8(0x02)));
		assertEq(bs[4], bytes1(uint8(0x03)));
		assertEq(bs[5], bytes1(uint8(0x04)));

		// Another value
		bytes4 w = bytes4(0xdeadbeef);
		string memory s2 = Bytes4._toString(w);
		bytes memory bs2 = bytes(s2);
		assertEq(bs2.length, 6);
		assertEq(bs2[0], bytes1('0'));
		assertEq(bs2[1], bytes1('x'));
		assertEq(bs2[2], bytes1(uint8(0xde)));
		assertEq(bs2[3], bytes1(uint8(0xad)));
		assertEq(bs2[4], bytes1(uint8(0xbe)));
		assertEq(bs2[5], bytes1(uint8(0xef)));
	}

	function test_append_arrays() public {
		bytes4 a = bytes4(0x01020304);
		bytes4 b = bytes4(0x0a0b0c0d);
		bytes4 c = bytes4(0x11121314);
		bytes4 d = bytes4(0x21222324);

		bytes4[] memory arr1 = new bytes4[](2);
		arr1[0] = a;
		arr1[1] = b;

		bytes4[] memory arr2 = new bytes4[](2);
		arr2[0] = c;
		arr2[1] = d;

		bytes4[] memory merged = Bytes4._append(arr1, arr2);
		// check length
		assertEq(merged.length, 4);
		// check ordering
		assertEq(toU32(merged[0]), toU32(a));
		assertEq(toU32(merged[1]), toU32(b));
		assertEq(toU32(merged[2]), toU32(c));
		assertEq(toU32(merged[3]), toU32(d));
	}

	function test_append_value() public {
		bytes4 a = bytes4(0xdeadbeef);
		bytes4 b = bytes4(0xbeefdead);

		bytes4[] memory base = new bytes4[](1);
		base[0] = a;

		bytes4[] memory appended = Bytes4._append(base, b);
		assertEq(appended.length, 2);
		assertEq(toU32(appended[0]), toU32(a));
		assertEq(toU32(appended[1]), toU32(b));
	}
}