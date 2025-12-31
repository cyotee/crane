// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/console.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";

/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/src/constants/Constants.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/crane/constants/FoundryConstants.sol";
import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
import {BetterBytes as Bytes} from "contracts/crane/utils/BetterBytes.sol";
import {Bytes32} from "@crane/src/utils/Bytes32.sol";
import {UInt256} from "contracts/crane/utils/UInt256.sol";

library betterconsole {
    using Address for address;
    using Bytes for bytes;
    using Bytes32 for bytes32;
    using UInt256 for uint256;

    /// forge-lint: disable-next-line(screaming-snake-case-const)
    Vm constant vm = Vm(VM_ADDRESS);

    /* ---------------------------------------------------------------------- */
    /*                 Wrappers to enable drope-in replacement                */
    /* ---------------------------------------------------------------------- */

    function log() internal pure {
        console.log();
    }

    function logInt(int256 p0) internal pure {
        console.logInt(p0);
    }

    function logUint(uint256 p0) internal pure {
        console.logUint(p0);
    }

    function logString(string memory p0) internal pure {
        console.logString(p0);
    }

    function logBool(bool p0) internal pure {
        console.logBool(p0);
    }

    function logAddress(address p0) internal pure {
        console.logAddress(p0);
    }

    function logBytes(bytes memory p0) internal pure {
        console.logBytes(p0);
    }

    function logBytes1(bytes1 p0) internal pure {
        console.logBytes1(p0);
    }

    function logBytes2(bytes2 p0) internal pure {
        console.logBytes2(p0);
    }

    function logBytes3(bytes3 p0) internal pure {
        console.logBytes3(p0);
    }

    function logBytes4(bytes4 p0) internal pure {
        console.logBytes4(p0);
    }

    function logBytes5(bytes5 p0) internal pure {
        console.logBytes5(p0);
    }

    function logBytes6(bytes6 p0) internal pure {
        console.logBytes6(p0);
    }

    function logBytes7(bytes7 p0) internal pure {
        console.logBytes7(p0);
    }

    function logBytes8(bytes8 p0) internal pure {
        console.logBytes8(p0);
    }

    function logBytes9(bytes9 p0) internal pure {
        console.logBytes9(p0);
    }

    function logBytes10(bytes10 p0) internal pure {
        console.logBytes10(p0);
    }

    function logBytes11(bytes11 p0) internal pure {
        console.logBytes11(p0);
    }

    function logBytes12(bytes12 p0) internal pure {
        console.logBytes12(p0);
    }

    function logBytes13(bytes13 p0) internal pure {
        console.logBytes13(p0);
    }

    function logBytes14(bytes14 p0) internal pure {
        console.logBytes14(p0);
    }

    function logBytes15(bytes15 p0) internal pure {
        console.logBytes15(p0);
    }

    function logBytes16(bytes16 p0) internal pure {
        console.logBytes16(p0);
    }

    function logBytes17(bytes17 p0) internal pure {
        console.logBytes17(p0);
    }

    function logBytes18(bytes18 p0) internal pure {
        console.logBytes18(p0);
    }

    function logBytes19(bytes19 p0) internal pure {
        console.logBytes19(p0);
    }

    function logBytes20(bytes20 p0) internal pure {
        console.logBytes20(p0);
    }

    function logBytes21(bytes21 p0) internal pure {
        console.logBytes21(p0);
    }

    function logBytes22(bytes22 p0) internal pure {
        console.logBytes22(p0);
    }

    function logBytes23(bytes23 p0) internal pure {
        console.logBytes23(p0);
    }

    function logBytes24(bytes24 p0) internal pure {
        console.logBytes24(p0);
    }

    function logBytes25(bytes25 p0) internal pure {
        console.logBytes25(p0);
    }

    function logBytes26(bytes26 p0) internal pure {
        console.logBytes26(p0);
    }

    function logBytes27(bytes27 p0) internal pure {
        console.logBytes27(p0);
    }

    function logBytes28(bytes28 p0) internal pure {
        console.logBytes28(p0);
    }

    function logBytes29(bytes29 p0) internal pure {
        console.logBytes29(p0);
    }

    function logBytes30(bytes30 p0) internal pure {
        console.logBytes30(p0);
    }

    function logBytes31(bytes31 p0) internal pure {
        console.logBytes31(p0);
    }

    function logBytes32(bytes32 p0) internal pure {
        console.logBytes32(p0);
    }

    function log(uint256 p0) internal pure {
        console.log(p0);
    }

    function log(int256 p0) internal pure {
        console.log(p0);
    }

    function log(string memory p0) internal pure {
        console.log(p0);
    }

    function log(bool p0) internal pure {
        console.log(p0);
    }

    function log(address p0) internal pure {
        console.log(p0);
    }

    function log(uint256 p0, uint256 p1) internal pure {
        console.log(p0, p1);
    }

    function log(uint256 p0, string memory p1) internal pure {
        console.log(p0, p1);
    }

    function log(uint256 p0, bool p1) internal pure {
        console.log(p0, p1);
    }

    function log(uint256 p0, address p1) internal pure {
        console.log(p0, p1);
    }

    function log(string memory p0, uint256 p1) internal pure {
        console.log(p0, p1);
    }

    function log(string memory p0, int256 p1) internal pure {
        console.log(p0, p1);
    }

    function log(string memory p0, string memory p1) internal pure {
        console.log(p0, p1);
    }

    function log(string memory p0, bool p1) internal pure {
        console.log(p0, p1);
    }

    function log(string memory p0, address p1) internal pure {
        console.log(p0, p1);
    }

    function log(bool p0, uint256 p1) internal pure {
        console.log(p0, p1);
    }

    function log(bool p0, string memory p1) internal pure {
        console.log(p0, p1);
    }

    function log(bool p0, bool p1) internal pure {
        console.log(p0, p1);
    }

    function log(bool p0, address p1) internal pure {
        console.log(p0, p1);
    }

    function log(address p0, uint256 p1) internal pure {
        console.log(p0, p1);
    }

    function log(address p0, string memory p1) internal pure {
        console.log(p0, p1);
    }

    function log(address p0, bool p1) internal pure {
        console.log(p0, p1);
    }

    function log(address p0, address p1) internal pure {
        console.log(p0, p1);
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, uint256 p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, uint256 p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, string memory p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, string memory p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, string memory p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, bool p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, bool p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, bool p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, bool p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, address p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, address p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, address p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, address p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, uint256 p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, uint256 p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, uint256 p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, string memory p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, string memory p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, string memory p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, string memory p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, bool p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, bool p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, bool p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, bool p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, address p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, address p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, address p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(string memory p0, address p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, uint256 p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, uint256 p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, uint256 p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, uint256 p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, string memory p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, string memory p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, string memory p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, string memory p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, bool p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, bool p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, bool p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, bool p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, address p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, address p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, address p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(bool p0, address p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, uint256 p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, uint256 p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, uint256 p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, uint256 p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, string memory p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, string memory p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, string memory p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, string memory p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, bool p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, bool p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, bool p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, bool p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, address p1, uint256 p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, address p1, string memory p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, address p1, bool p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(address p0, address p1, address p2) internal pure {
        console.log(p0, p1, p2);
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, string memory p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(uint256 p0, address p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, uint256 p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, string memory p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, bool p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(string memory p0, address p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, string memory p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, bool p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(bool p0, address p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, uint256 p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, string memory p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, bool p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, uint256 p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, uint256 p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, string memory p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, string memory p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, string memory p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, string memory p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, bool p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, bool p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, bool p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, address p2, uint256 p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, address p2, string memory p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, address p2, bool p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    function log(address p0, address p1, address p2, address p3) internal pure {
        console.log(p0, p1, p2, p3);
    }

    /* ---------------------------------------------------------------------- */
    /*                                New Logic                               */
    /* ---------------------------------------------------------------------- */

    function log(string memory logMsg, bytes32 value) public pure {
        log(string.concat(logMsg, value._toHexString()));
    }

    function log(string memory logMsg, bytes memory data) public pure {
        log(logMsg);
        log(DIV);
        console.logBytes(data);
        log(DIV);
    }

    function log(string memory logMsg, bytes4[] memory values) public pure {
        log(logMsg);
        log("values length = ", values.length);
        log(DIV);
        for (uint256 i = 0; i < values.length; i++) {
            console.logBytes4(values[i]);
        }
        log(DIV);
    }

    function log(
        string memory logMsg1,
        address addr1,
        string memory logMsgs2,
        address addr2,
        string memory logMsgs3,
        uint256 num
    ) public pure {
        console.log(string.concat(logMsg1, addr1.toString(), logMsgs2, addr2.toString(), logMsgs3, num.toString()));
    }

    function log(
        string memory logMsg1,
        address addr1,
        string memory logMsgs2,
        address addr2,
        string memory logMsgs3,
        uint256 num,
        string memory logMsg4,
        address addr3
    ) public pure {
        logMsg1 = string.concat(logMsg1, addr1.toString());
        logMsg1 = string.concat(logMsg1, logMsgs2);
        logMsg1 = string.concat(logMsg1, addr2.toString());
        logMsg1 = string.concat(logMsg1, logMsgs3);
        logMsg1 = string.concat(logMsg1, num.toString());
        logMsg1 = string.concat(logMsg1, logMsg4);
        logMsg1 = string.concat(logMsg1, addr3.toString());
        console.log(logMsg1);
    }

    /* ---------------------------------------------------------------------- */
    /*                            Function Logging                            */
    /* ---------------------------------------------------------------------- */

    function logFuncMsg(string memory contractName, string memory functionSig, string memory logMsg) public pure {
        log(string.concat(contractName, ":", functionSig, ":: ", logMsg));
    }

    function logEntry(string memory contractName, string memory functionSig) public pure {
        logFuncMsg(contractName, functionSig, ":: Entering function.");
    }

    function logExit(string memory contractName, string memory functionSig) public pure {
        logFuncMsg(contractName, functionSig, ":: Exiting function.");
    }

    /* ---------------------------------------------------------------------- */
    /*                             Comparison Logs                            */
    /* ---------------------------------------------------------------------- */

    function logCompare(
        string memory subjectLabel,
        string memory logBody,
        string memory expectedLog,
        string memory actualLog
    ) public pure {
        console.log("subject: ", subjectLabel);
        if (bytes(logBody).length > 0) {
            console.log(logBody);
        }
        console.log("expected: ", expectedLog);
        console.log("actual: ", actualLog);
    }

    function logCompare(string memory subjectLabel, string memory logBody, address expected, address actual)
        public
        view
    {
        logCompare(
            subjectLabel,
            logBody,
            string.concat(vm.getLabel(expected), " :: ", expected.toString()),
            string.concat(vm.getLabel(actual), " :: ", actual.toString())
        );
    }

    function logCompare(string memory subjectLabel, string memory logBody, bytes32 expected, bytes32 actual)
        public
        pure
    {
        logCompare(subjectLabel, logBody, uint256(expected).toHexString(), uint256(actual).toHexString());
    }

    /* ------------------------ Behavior Debug Logging ----------------------- */

    function logBehaviorEntry(string memory behaviorName, string memory functionName) public pure {
        log(string.concat(behaviorName, ":", functionName, ":: Entering function."));
    }

    function logBehaviorExit(string memory behaviorName, string memory functionName) public pure {
        log(string.concat(behaviorName, ":", functionName, ":: Exiting function."));
    }

    function logBehaviorExpectation(
        string memory behaviorName,
        string memory functionName,
        string memory expectationType,
        string memory expectedValue
    ) public pure {
        log(string.concat(behaviorName, ":", functionName, ":: Expecting ", expectationType, " to be ", expectedValue));
    }

    function logBehaviorValidation(
        string memory behaviorName,
        string memory functionName,
        string memory validationType,
        bool isValid
    ) public pure {
        log(
            string.concat(behaviorName, ":", functionName, ":: ", validationType, " is ", isValid ? "valid" : "invalid")
        );
    }

    function logBehaviorProcessing(
        string memory behaviorName,
        string memory functionName,
        string memory processType,
        string memory processValue
    ) public pure {
        log(string.concat(behaviorName, ":", functionName, ":: Processing ", processType, ": ", processValue));
    }

    function logBehaviorCompare(
        string memory behaviorName,
        string memory functionName,
        string memory compareType,
        string memory expected,
        string memory actual
    ) public pure {
        log(string.concat(behaviorName, ":", functionName, ":: Comparing ", compareType));
        logCompare(string.concat(behaviorName, ":", functionName), "", expected, actual);
    }

    function logBehaviorCompare(
        string memory behaviorName,
        string memory functionName,
        string memory compareType,
        address expected,
        address actual
    ) public view {
        log(string.concat(behaviorName, ":", functionName, ":: Comparing ", compareType));
        logCompare(string.concat(behaviorName, ":", functionName), "", expected, actual);
    }

    function logBehaviorCompare(
        string memory behaviorName,
        string memory functionName,
        string memory compareType,
        bytes32 expected,
        bytes32 actual
    ) public pure {
        log(string.concat(behaviorName, ":", functionName, ":: Comparing ", compareType));
        logCompare(string.concat(behaviorName, ":", functionName), "", expected, actual);
    }

    function logBehaviorError(
        string memory behaviorName,
        string memory functionName,
        string memory errorPrefix,
        string memory errorSuffix
    ) public pure {
        log(string.concat(behaviorName, ":", functionName, ":: ", errorPrefix, " UNEXPECTED ", errorSuffix));
    }
}
