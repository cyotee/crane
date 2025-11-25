// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {Bytecode} from "src/utils/Bytecode.sol";

contract Simple {
    uint256 public v;
    constructor(uint256 _v) {
        v = _v;
    }
}

contract BytecodeRevertHarness {
    function callCodeAt(address target, uint256 start, uint256 end) external view returns (bytes memory) {
        return Bytecode.codeAt(target, start, end);
    }
}

// No external harness needed — tests call the library functions directly.

contract BytecodeTest is Test {

    function testCreate_deploysSimpleContract() public {
        bytes memory init = abi.encodePacked(type(Simple).creationCode, abi.encode(uint256(123)));
        address d = Bytecode.create(init);
        assertTrue(d != address(0));
        assertEq(Simple(d).v(), 123);
    }

    function test_initCodeFor_and_deploysRuntime() public {
        // Deploy original contract
        bytes memory init = abi.encodePacked(type(Simple).creationCode, abi.encode(uint256(55)));
        address original = Bytecode.create(init);
        bytes memory runtime = Bytecode.codeAt(original);
        assertTrue(runtime.length > 0);

        // Build creation code that returns `runtime`
        bytes memory creation = Bytecode._initCodeFor(runtime);
        address recreated = Bytecode.create(creation);
        bytes memory runtime2 = Bytecode.codeAt(recreated);

        assertEq(runtime2, runtime);
    }

    function test_codeSizeAndCodeAt_range() public {
        bytes memory init = abi.encodePacked(type(Simple).creationCode, abi.encode(uint256(7)));
        address d = Bytecode.create(init);
        uint256 sz = Bytecode.codeSizeOf(d);
        bytes memory code = Bytecode.codeAt(d);
        assertEq(code.length, sz);

        if (sz >= 4) {
            bytes memory prefix = Bytecode.codeAt(d, 0, 4);
            for (uint256 i = 0; i < 4; ++i) {
                assertEq(prefix[i], code[i]);
            }
        }
    }

    function test_create2WithArgsAddressDerivation_matchesManual() public {
        bytes memory init = type(Simple).creationCode;
        bytes memory args = abi.encode(uint256(9));
        bytes32 salt = bytes32(uint256(0x123));
        address addr = Bytecode._create2WithArgsAddressFromOf(address(this), init, args, salt);

        bytes32 initHash = keccak256(abi.encodePacked(init, args));
        bytes32 digest = keccak256(abi.encodePacked(hex"ff", address(this), salt, initHash));
        address expected = address(uint160(uint256(digest)));
        assertEq(addr, expected);
    }

    function test_createWithArgs_deploysContractWithArgs() public {
        bytes memory init = type(Simple).creationCode;
        bytes memory args = abi.encode(uint256(77));
        address deployed = Bytecode.createWithArgs(init, args);
        assertTrue(deployed != address(0));
        assertEq(Simple(deployed).v(), 77);
    }

    function test_encodeInitArgs_concatenatesInitAndArgs() public {
        bytes memory init = type(Simple).creationCode;
        bytes memory args = abi.encode(uint256(77));
        bytes memory enc = Bytecode._encodeInitArgs(init, args);
        assertEq(enc, abi.encodePacked(init, args));
    }

    function test_create2WithArgs_deploysToDeterministicAddress() public {
        bytes memory init = type(Simple).creationCode;
        bytes memory args = abi.encode(uint256(77));
        bytes32 salt = bytes32(uint256(0xBEEF));
        address expected = Bytecode._create2WithArgsAddressFromOf(address(this), init, args, salt);
        address d2 = Bytecode.create2WithArgs(init, salt, args);
        assertEq(d2, expected);
        assertTrue(Bytecode.codeSizeOf(d2) > 0);
    }

    function test_calcInitCodeHash_returnsKeccak() public {
        bytes memory init = type(Simple).creationCode;
        bytes32 initHash = Bytecode._calcInitCodeHash(init);
        assertEq(initHash, keccak256(init));
    }

    function test_create2AddressFromOf_matchesManual() public {
        bytes memory init = type(Simple).creationCode;
        bytes32 initHash = Bytecode._calcInitCodeHash(init);
        bytes32 salt = bytes32(uint256(0xA1));

        address expected = Bytecode._create2AddressFromOf(address(this), initHash, salt);

        // manual expected
        bytes32 digest = keccak256(abi.encodePacked(hex"ff", address(this), salt, initHash));
        address manual = address(uint160(uint256(digest)));
        assertEq(expected, manual);
    }

    function test_create3AddressFromOf_matchesManual() public {
        bytes32 salt = bytes32(uint256(0xCAFE));
        address deployer = address(this);

        address calc = Bytecode._create3AddressFromOf(deployer, salt);

        // manual calculation: compute proxy then final
        bytes32 proxyHash = keccak256(abi.encodePacked(hex"ff", deployer, salt, Bytecode.CREATE3_PROXY_INITCODEHASH));
        address proxy = address(uint160(uint256(proxyHash)));
        bytes32 finalHash = keccak256(abi.encodePacked(hex"d694", proxy, hex"01"));
        address manual = address(uint160(uint256(finalHash)));

        assertEq(calc, manual);
    }

    function test_create3AddressOf_usesCallerAddress() public {
        bytes32 salt = bytes32(uint256(0xCAFE));
        address calc2 = Bytecode._create3AddressOf(salt);
        address calc = Bytecode._create3AddressFromOf(address(this), salt);
        assertEq(calc2, calc);
    }

    function test_codeAt_startOutside_reverts() public {
        // Deploy a contract so codeSize != 0
        bytes memory init = abi.encodePacked(type(Simple).creationCode, abi.encode(uint256(5)));
        address d = Bytecode.create(init);
        uint256 csize = Bytecode.codeSizeOf(d);
        // start beyond code size should revert when called externally
        BytecodeRevertHarness h = new BytecodeRevertHarness();
        vm.expectRevert();
        h.callCodeAt(d, csize + 1, csize + 10);
    }

    function test_codeAt_endOutside_truncatesToAvailable() public {
        // Deploy a contract so codeSize != 0
        bytes memory init = abi.encodePacked(type(Simple).creationCode, abi.encode(uint256(6)));
        address d = Bytecode.create(init);

        bytes memory full = Bytecode.codeAt(d);
        uint256 csize = full.length;

        // Request end beyond code size; should return truncated (up to available bytes)
        bytes memory part = Bytecode.codeAt(d, 0, csize + 50);
        assertEq(part.length, csize);
        assertEq(part, full);
    }

    function test_codeAt_endLessThanStart_reverts() public {
        // Deploy a contract so codeSize != 0
        bytes memory init = abi.encodePacked(type(Simple).creationCode, abi.encode(uint256(5)));
        address d = Bytecode.create(init);
        // end < start should revert InvalidCodeAtRange when called externally
        BytecodeRevertHarness h = new BytecodeRevertHarness();
        vm.expectRevert();
        h.callCodeAt(d, 2, 1);
    }
}
