// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/// @title BetterEfficientHashLib Hash Equivalence Tests
/// @notice Proves that BetterEfficientHashLib._hash() produces identical output
///         to keccak256(abi.encode()) for representative values including negatives.
/// @dev Created from CRANE-036 code review suggestion (CRANE-091).
contract BetterEfficientHashLib_equivalence is Test {
    using BetterEfficientHashLib for bytes;

    /* ---------------------------------------------------------------------- */
    /*                         Single bytes32 hash                            */
    /* ---------------------------------------------------------------------- */

    function test_hash_bytes32_zero() public pure {
        bytes32 v = bytes32(0);
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    function test_hash_bytes32_one() public pure {
        bytes32 v = bytes32(uint256(1));
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    function test_hash_bytes32_max() public pure {
        bytes32 v = bytes32(type(uint256).max);
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    function test_hash_bytes32_negativeOne() public pure {
        // int256(-1) in two's complement = all 1s = type(uint256).max
        bytes32 v = bytes32(uint256(int256(-1)));
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    function testFuzz_hash_bytes32(bytes32 v) public pure {
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    /* ---------------------------------------------------------------------- */
    /*                         Single uint256 hash                            */
    /* ---------------------------------------------------------------------- */

    function test_hash_uint256_zero() public pure {
        uint256 v = 0;
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    function test_hash_uint256_one() public pure {
        uint256 v = 1;
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    function test_hash_uint256_max() public pure {
        uint256 v = type(uint256).max;
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    function testFuzz_hash_uint256(uint256 v) public pure {
        assertEq(BetterEfficientHashLib.__hash(v), keccak256(abi.encode(v)));
    }

    /* ---------------------------------------------------------------------- */
    /*                      Two-arg bytes32 hash                              */
    /* ---------------------------------------------------------------------- */

    function test_hash2_bytes32_zeros() public pure {
        bytes32 a = bytes32(0);
        bytes32 b = bytes32(0);
        assertEq(BetterEfficientHashLib._hash(a, b), keccak256(abi.encode(a, b)));
    }

    function test_hash2_bytes32_negatives() public pure {
        // Simulates hashing negative tick/wordPos values as stored in Uniswap V4 StateLibrary
        bytes32 a = bytes32(uint256(int256(-1)));
        bytes32 b = bytes32(uint256(int256(-128)));
        assertEq(BetterEfficientHashLib._hash(a, b), keccak256(abi.encode(a, b)));
    }

    function test_hash2_bytes32_mixed() public pure {
        bytes32 a = bytes32(uint256(42));
        bytes32 b = bytes32(uint256(int256(-1)));
        assertEq(BetterEfficientHashLib._hash(a, b), keccak256(abi.encode(a, b)));
    }

    function testFuzz_hash2_bytes32(bytes32 a, bytes32 b) public pure {
        assertEq(BetterEfficientHashLib._hash(a, b), keccak256(abi.encode(a, b)));
    }

    /* ---------------------------------------------------------------------- */
    /*                      Two-arg uint256 hash                              */
    /* ---------------------------------------------------------------------- */

    function test_hash2_uint256_zeros() public pure {
        assertEq(BetterEfficientHashLib._hash(uint256(0), uint256(0)), keccak256(abi.encode(uint256(0), uint256(0))));
    }

    function test_hash2_uint256_positives() public pure {
        uint256 a = 100;
        uint256 b = 999;
        assertEq(BetterEfficientHashLib._hash(a, b), keccak256(abi.encode(a, b)));
    }

    function testFuzz_hash2_uint256(uint256 a, uint256 b) public pure {
        assertEq(BetterEfficientHashLib._hash(a, b), keccak256(abi.encode(a, b)));
    }

    /* ---------------------------------------------------------------------- */
    /*                      Three-arg bytes32 hash                            */
    /* ---------------------------------------------------------------------- */

    function test_hash3_bytes32_negatives() public pure {
        bytes32 a = bytes32(uint256(int256(-1)));
        bytes32 b = bytes32(uint256(int256(-2)));
        bytes32 c = bytes32(uint256(int256(-3)));
        assertEq(BetterEfficientHashLib._hash(a, b, c), keccak256(abi.encode(a, b, c)));
    }

    function testFuzz_hash3_bytes32(bytes32 a, bytes32 b, bytes32 c) public pure {
        assertEq(BetterEfficientHashLib._hash(a, b, c), keccak256(abi.encode(a, b, c)));
    }

    /* ---------------------------------------------------------------------- */
    /*                      Three-arg uint256 hash                            */
    /* ---------------------------------------------------------------------- */

    function testFuzz_hash3_uint256(uint256 a, uint256 b, uint256 c) public pure {
        assertEq(BetterEfficientHashLib._hash(a, b, c), keccak256(abi.encode(a, b, c)));
    }

    /* ---------------------------------------------------------------------- */
    /*                      Four-arg bytes32 hash                             */
    /* ---------------------------------------------------------------------- */

    function test_hash4_bytes32_mixed() public pure {
        bytes32 a = bytes32(uint256(1));
        bytes32 b = bytes32(uint256(int256(-1)));
        bytes32 c = bytes32(uint256(0));
        bytes32 d = bytes32(type(uint256).max);
        assertEq(BetterEfficientHashLib._hash(a, b, c, d), keccak256(abi.encode(a, b, c, d)));
    }

    function testFuzz_hash4_bytes32(bytes32 a, bytes32 b, bytes32 c, bytes32 d) public pure {
        assertEq(BetterEfficientHashLib._hash(a, b, c, d), keccak256(abi.encode(a, b, c, d)));
    }

    /* ---------------------------------------------------------------------- */
    /*                      Four-arg uint256 hash                             */
    /* ---------------------------------------------------------------------- */

    function testFuzz_hash4_uint256(uint256 a, uint256 b, uint256 c, uint256 d) public pure {
        assertEq(BetterEfficientHashLib._hash(a, b, c, d), keccak256(abi.encode(a, b, c, d)));
    }

    /* ---------------------------------------------------------------------- */
    /*                      bytes32 buffer hash                               */
    /* ---------------------------------------------------------------------- */

    function test_hashBuffer_singleElement() public pure {
        bytes32[] memory buf = new bytes32[](1);
        buf[0] = bytes32(uint256(int256(-1)));
        assertEq(BetterEfficientHashLib._hash(buf), keccak256(abi.encode(buf[0])));
    }

    function test_hashBuffer_multiElement() public pure {
        bytes32[] memory buf = new bytes32[](3);
        buf[0] = bytes32(uint256(42));
        buf[1] = bytes32(uint256(int256(-1)));
        buf[2] = bytes32(uint256(0));
        assertEq(BetterEfficientHashLib._hash(buf), keccak256(abi.encode(buf[0], buf[1], buf[2])));
    }

    /* ---------------------------------------------------------------------- */
    /*                      bytes memory hash                                 */
    /* ---------------------------------------------------------------------- */

    function test_hashBytes_empty() public pure {
        bytes memory b = "";
        assertEq(b._hash(), keccak256(b));
    }

    function test_hashBytes_short() public pure {
        bytes memory b = hex"deadbeef";
        assertEq(b._hash(), keccak256(b));
    }

    function testFuzz_hashBytes(bytes memory b) public pure {
        assertEq(b._hash(), keccak256(b));
    }

    /* ---------------------------------------------------------------------- */
    /*    Negative int round-trip: int → bytes32 → hash equivalence           */
    /* ---------------------------------------------------------------------- */

    /// @notice Proves that hashing negative ints (as bytes32) through the library
    ///         matches keccak256(abi.encode()) of the same bytes32 representation.
    ///         This is the specific scenario from StateLibrary (wordPos, tick).
    function test_negativeInt_roundTrip_wordPos() public pure {
        int24 wordPos = -1;
        bytes32 asBytes32 = bytes32(uint256(int256(wordPos)));
        // The library hash of the bytes32 must equal abi.encode of the same bytes32
        assertEq(BetterEfficientHashLib.__hash(asBytes32), keccak256(abi.encode(asBytes32)));
    }

    function test_negativeInt_roundTrip_tick() public pure {
        int24 tick = -887272; // min tick for Uniswap V3/V4
        bytes32 asBytes32 = bytes32(uint256(int256(tick)));
        assertEq(BetterEfficientHashLib.__hash(asBytes32), keccak256(abi.encode(asBytes32)));
    }

    function test_negativeInt_roundTrip_twoArgs() public pure {
        int24 wordPos = -1;
        int24 tick = -1;
        bytes32 a = bytes32(uint256(int256(wordPos)));
        bytes32 b = bytes32(uint256(int256(tick)));
        assertEq(BetterEfficientHashLib._hash(a, b), keccak256(abi.encode(a, b)));
    }

    function testFuzz_negativeInt_roundTrip(int256 v) public pure {
        bytes32 asBytes32 = bytes32(uint256(v));
        assertEq(BetterEfficientHashLib.__hash(asBytes32), keccak256(abi.encode(asBytes32)));
    }
}
