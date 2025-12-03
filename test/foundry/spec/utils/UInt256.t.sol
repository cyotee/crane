// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/UInt256.sol";

contract UInt256Caller {
    function toHexWithLen(uint256 v, uint256 len) external pure returns (string memory) {
        return UInt256._toHexString(v, len);
    }
}

contract UInt256Test is Test {
    using UInt256 for uint256;

    function test_toAddress_truncation() public pure {
        uint256 small = 0x1234;
        address aSmall = UInt256._toAddress(small);
        assertEq(aSmall, address(uint160(small)));

        // value larger than 2^160 will be truncated (mod 2^160)
        uint256 big = (uint256(1) << 160) + 0x1234;
        address aBig = UInt256._toAddress(big);
        assertEq(aBig, address(uint160(big)));
    }

    function test_toBytes32_and_roundtrip() public pure {
        uint256 v = 0xdeadbeef;
        bytes32 b = UInt256._toBytes32(v);
        assertEq(b, bytes32(v));
    }

    function test_toString_values() public pure {
        assertEq(UInt256._toString(0), "0");
        assertEq(UInt256._toString(1), "1");
        assertEq(UInt256._toString(1234567890), "1234567890");
    }

    function test_toHexString_known() public pure {
        // 0 should map to 0x00
        assertEq(UInt256._toHexString(0), "0x00");

        // known small value
        uint256 v = 0xdeadbeef;
        string memory s = UInt256._toHexString(v);
        // lowercase expected
        assertEq(s, "0xdeadbeef");
    }

    function test_toHexString_with_length_revert() public pure {
        uint256 v = 0xdeadbeef;
        // length too small should revert with the require message
        // call the two-arg overload and expect revert
        // Note: using try/catch is not available in pure context here; instead assert by encoding expected revert string
        // But since this is a pure test helper, keep it simple by invoking the 2-arg and letting test framework catch revert
        // Use a low-level approach in a separate non-pure test instead.
    }

    function test_toHexString_with_length_revert_external() public {
        uint256 v = 0xdeadbeef;
        // call the two-arg overload with an insufficient length and expect revert
        UInt256Caller c = new UInt256Caller();
        vm.expectRevert(bytes("UintUtils: hex length insufficient"));
        c.toHexWithLen(v, 1);
    }

    function test_equals_behavior() public pure {
        assertTrue(UInt256._equals("abc", "abc"));
        assertFalse(UInt256._equals("abc", "abcd"));
    }
}
