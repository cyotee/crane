// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/utils/BetterStrings.sol";

// No external caller — tests call library functions directly.

contract BetterStringsTest is Test {
    // Each test below targets exactly one BetterStrings function.

    function test__toString_uint() public pure {
        string memory s = BetterStrings._toString(123456);
        assertEq(s, "123456");
    }

    function test__toStringSigned_int() public pure {
        string memory s = BetterStrings._toStringSigned(-42);
        assertEq(s, "-42");
    }

    function test__toHexString_uint() public pure {
        string memory s = BetterStrings._toHexString(0xdead);
        assertEq(s, "0xdead");
    }

    function test__toHexString_uint_len() public pure {
        string memory s = BetterStrings._toHexString(0x1234, 2);
        assertEq(s, "0x1234");
    }

    function test__toHexString_address() public pure {
        string memory s = BetterStrings._toHexString(address(0x1234567890123456789012345678901234567890));
        // prefix + 40 hex chars
        assertEq(bytes(s).length, 42);
    }

    function test__toChecksumHexString_address() public pure {
        string memory s = BetterStrings._toChecksumHexString(address(0x1234567890123456789012345678901234567890));
        assertEq(bytes(s).length, 42);
    }

    function test__equal_true() public pure {
        assertTrue(BetterStrings._equal("abc", "abc"));
    }

    function test__equal_false() public pure {
        assertTrue(!BetterStrings._equal("a", "b"));
    }

    function test__parseFixedPoint_standard() public pure {
        string memory out = BetterStrings._parseFixedPoint(12345, 2);
        assertEq(out, "123.45");
    }

    function test__parseFixedPoint_zeroDecimals() public pure {
        string memory out = BetterStrings._parseFixedPoint(1, 0);
        assertEq(out, "1.00");
    }

    function test__parseSecondsToISO() public pure {
        string memory iso = BetterStrings._parseSecondsToISO(86400 + 3600 + 60 + 1);
        assertEq(iso, "01:01:01:01");
    }

    function test__padLeft() public pure {
        string memory pl = BetterStrings._padLeft("7", "0", 3);
        assertEq(pl, "007");
    }

    function test__padRight() public pure {
        string memory pr = BetterStrings._padRight("7", "0", 3);
        assertEq(pr, "700");
    }

    function test__marshall_unmarshallAsString_roundtrip() public pure {
        string memory v = "hello world";
        string memory out = BetterStrings._unmarshallAsString(BetterStrings._marshall(v));
        assertEq(out, v);
    }

    function test__parseUint_valid() public pure {
        uint256 v = BetterStrings._parseUint("00123");
        assertEq(v, 123);
    }

    function test__tryParseUint_invalid() public pure {
        (bool ok, uint256 v) = BetterStrings._tryParseUint("12a");
        assertTrue(!ok && v == 0);
    }

    function test__parseUint_range() public pure {
        uint256 r = BetterStrings._parseUint("x0123y", 1, 5);
        assertEq(r, 123);
    }

    function test__tryParseUint_range_invalid() public pure {
        (bool ok, uint256 v) = BetterStrings._tryParseUint("ab", 1, 3);
        assertTrue(!ok && v == 0);
    }

    function test__parseInt_valid() public pure {
        int256 p = BetterStrings._parseInt("+123");
        assertEq(p, 123);
    }

    function test__tryParseInt_invalid() public pure {
        (bool ok, int256 v) = BetterStrings._tryParseInt("x-");
        assertTrue(!ok && v == 0);
    }

    function test__parseInt_range() public pure {
        int256 p = BetterStrings._parseInt("x-123y", 1, 5);
        assertEq(p, -123);
    }

    function test__tryParseInt_range_invalid() public pure {
        (bool ok, int256 v) = BetterStrings._tryParseInt("ab", 1, 2);
        assertTrue(!ok && v == 0);
    }

    function test__parseHexUint_valid() public pure {
        uint256 h = BetterStrings._parseHexUint("0xdead");
        assertEq(h, 0xdead);
    }

    function test__tryParseHexUint_invalid() public pure {
        (bool ok, uint256 v) = BetterStrings._tryParseHexUint("zz");
        assertTrue(!ok && v == 0);
    }

    function test__parseHexUint_range() public pure {
        uint256 h = BetterStrings._parseHexUint("a0xdeadbeefb", 1, 11);
        assertEq(h, 0xdeadbeef);
    }

    function test__tryParseHexUint_range_invalid() public pure {
        (bool ok, uint256 v) = BetterStrings._tryParseHexUint("aZZb", 1, 3);
        assertTrue(!ok && v == 0);
    }

    function test__parseAddress_valid() public pure {
        address a = BetterStrings._parseAddress("0x1234567890123456789012345678901234567890");
        assertEq(a, address(0x1234567890123456789012345678901234567890));
    }

    function test__tryParseAddress_invalid() public pure {
        (bool ok, address a) = BetterStrings._tryParseAddress("notanaddr");
        assertTrue(!ok && a == address(0));
    }

    function test__parseAddress_range() public pure {
        string memory s = string(abi.encodePacked("p", "0x1234567890123456789012345678901234567890", "q"));
        address a = BetterStrings._parseAddress(s, 1, 1 + 42);
        assertEq(a, address(0x1234567890123456789012345678901234567890));
    }

    function test__tryParseAddress_range_invalid() public pure {
        (bool ok, address a) = BetterStrings._tryParseAddress("px", 1, 2);
        assertTrue(!ok && a == address(0));
    }

    function test__escapeJSON() public pure {
        string memory escaped = BetterStrings._escapeJSON("a\"b");
        assertEq(keccak256(bytes(escaped)), keccak256(bytes("a\\\"b")));
    }
}
