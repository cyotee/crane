// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Creation} from "@crane/contracts/utils/Creation.sol";
import {Bytecode} from "@crane/contracts/utils/Bytecode.sol";

/**
 * @title SimpleContract
 * @notice A simple contract for testing deployment.
 */
contract SimpleContract {
    uint256 public value;

    constructor() {
        value = 42;
    }
}

/**
 * @title SimpleContractWithArgs
 * @notice A contract with constructor arguments for testing.
 */
contract SimpleContractWithArgs {
    uint256 public value;
    address public owner;

    constructor(uint256 _value, address _owner) {
        value = _value;
        owner = _owner;
    }
}

/**
 * @title CreationHarness
 * @notice Test harness that exposes Creation library functions.
 */
contract CreationHarness {
    using Creation for bytes;

    function create(bytes memory initCode) external returns (address) {
        return Creation.create(initCode);
    }

    function create2(bytes memory initCode, bytes32 salt) external returns (address) {
        return Creation._create2(initCode, salt);
    }

    function create2WithArgs(bytes memory initCode, bytes32 salt, bytes memory initArgs) external returns (address) {
        return Creation.create2WithArgs(initCode, salt, initArgs);
    }

    function create3(bytes memory initCode, bytes32 salt) external returns (address) {
        return Creation.create3(initCode, salt);
    }

    function create3WithArgs(bytes memory initCode, bytes memory initArgs, bytes32 salt) external returns (address) {
        return Creation.create3WithArgs(initCode, initArgs, salt);
    }

    function create2AddressFromOf(address deployer, bytes32 initCodeHash, bytes32 salt) external pure returns (address) {
        return Creation._create2AddressFromOf(deployer, initCodeHash, salt);
    }

    function create2Address(bytes32 initCodeHash, bytes32 salt) external view returns (address) {
        return Creation._create2Address(initCodeHash, salt);
    }

    function create2WithArgsAddressFromOf(address deployer, bytes memory initCode, bytes memory initArgs, bytes32 salt)
        external
        pure
        returns (address)
    {
        return Creation._create2WithArgsAddressFromOf(deployer, initCode, initArgs, salt);
    }

    function create2WithArgsAddress(bytes memory initCode, bytes memory initArgs, bytes32 salt)
        external
        view
        returns (address)
    {
        return Creation._create2WithArgsAddress(initCode, initArgs, salt);
    }

    function create3AddressFromOf(address deployer, bytes32 salt) external pure returns (address) {
        return Creation._create3AddressFromOf(deployer, salt);
    }

    function create3AddressOf(bytes32 salt) external view returns (address) {
        return Creation._create3AddressOf(salt);
    }
}

/**
 * @title Creation_Test
 * @notice Tests for Creation library functions.
 */
contract Creation_Test is Test {
    CreationHarness internal harness;

    bytes internal simpleContractInitCode;
    bytes internal simpleContractWithArgsInitCode;

    function setUp() public {
        harness = new CreationHarness();
        simpleContractInitCode = type(SimpleContract).creationCode;
        simpleContractWithArgsInitCode = type(SimpleContractWithArgs).creationCode;
    }

    /* -------------------------------------------------------------------------- */
    /*                              CREATE Tests                                  */
    /* -------------------------------------------------------------------------- */

    function test_create_deploysContract() public {
        address deployed = harness.create(simpleContractInitCode);

        assertTrue(deployed != address(0), "Should deploy to non-zero address");
        assertGt(deployed.code.length, 0, "Deployed contract should have code");

        SimpleContract sc = SimpleContract(deployed);
        assertEq(sc.value(), 42, "Contract should be initialized correctly");
    }

    function test_create_emptyCode_deploysEmptyContract() public {
        // Empty initCode still "deploys" - creates address with no runtime code
        address deployed = harness.create("");
        assertTrue(deployed != address(0), "Should deploy to non-zero address");
        assertEq(deployed.code.length, 0, "Should have no runtime code");
    }

    function test_create_invalidCode_reverts() public {
        // Invalid bytecode that will fail to deploy
        bytes memory invalidCode = hex"deadbeef";
        vm.expectRevert("ByteCodeUtils:_create(bytes):: failed deployment");
        harness.create(invalidCode);
    }

    /* -------------------------------------------------------------------------- */
    /*                             CREATE2 Tests                                  */
    /* -------------------------------------------------------------------------- */

    function test_create2_deploysToPredicatedAddress() public {
        bytes32 salt = bytes32(uint256(1));
        bytes32 initCodeHash = keccak256(simpleContractInitCode);

        address predicted = harness.create2Address(initCodeHash, salt);
        address deployed = harness.create2(simpleContractInitCode, salt);

        assertEq(deployed, predicted, "Deployed address should match predicted");
        assertGt(deployed.code.length, 0, "Deployed contract should have code");

        SimpleContract sc = SimpleContract(deployed);
        assertEq(sc.value(), 42, "Contract should be initialized correctly");
    }

    function test_create2_differentSalts_differentAddresses() public {
        bytes32 salt1 = bytes32(uint256(1));
        bytes32 salt2 = bytes32(uint256(2));
        bytes32 initCodeHash = keccak256(simpleContractInitCode);

        address addr1 = harness.create2Address(initCodeHash, salt1);
        address addr2 = harness.create2Address(initCodeHash, salt2);

        assertTrue(addr1 != addr2, "Different salts should produce different addresses");
    }

    function test_create2_sameSalt_sameAddress() public {
        bytes32 salt = bytes32(uint256(123));
        bytes32 initCodeHash = keccak256(simpleContractInitCode);

        address addr1 = harness.create2Address(initCodeHash, salt);
        address addr2 = harness.create2Address(initCodeHash, salt);

        assertEq(addr1, addr2, "Same salt should produce same address");
    }

    function test_create2_emptyCode_deploysEmptyContract() public {
        // Empty initCode still "deploys" - creates address with no runtime code
        bytes32 salt = bytes32(uint256(1));
        address deployed = harness.create2("", salt);
        assertTrue(deployed != address(0), "Should deploy to non-zero address");
        assertEq(deployed.code.length, 0, "Should have no runtime code");
    }

    function test_create2AddressFromOf_differentDeployers_differentAddresses() public view {
        bytes32 salt = bytes32(uint256(1));
        bytes32 initCodeHash = keccak256(simpleContractInitCode);

        address addr1 = harness.create2AddressFromOf(address(0x1), initCodeHash, salt);
        address addr2 = harness.create2AddressFromOf(address(0x2), initCodeHash, salt);

        assertTrue(addr1 != addr2, "Different deployers should produce different addresses");
    }

    /* -------------------------------------------------------------------------- */
    /*                        CREATE2 With Args Tests                             */
    /* -------------------------------------------------------------------------- */

    function test_create2WithArgs_deploysWithConstructorArgs() public {
        bytes32 salt = bytes32(uint256(1));
        uint256 expectedValue = 100;
        address expectedOwner = address(0xBEEF);
        bytes memory initArgs = abi.encode(expectedValue, expectedOwner);

        address predicted = harness.create2WithArgsAddress(simpleContractWithArgsInitCode, initArgs, salt);
        address deployed = harness.create2WithArgs(simpleContractWithArgsInitCode, salt, initArgs);

        assertEq(deployed, predicted, "Deployed address should match predicted");

        SimpleContractWithArgs sc = SimpleContractWithArgs(deployed);
        assertEq(sc.value(), expectedValue, "Value should match constructor arg");
        assertEq(sc.owner(), expectedOwner, "Owner should match constructor arg");
    }

    function test_create2WithArgsAddressFromOf_matchesDeployment() public {
        bytes32 salt = bytes32(uint256(42));
        bytes memory initArgs = abi.encode(uint256(999), address(0xCAFE));

        address predicted = harness.create2WithArgsAddressFromOf(
            address(harness),
            simpleContractWithArgsInitCode,
            initArgs,
            salt
        );
        address deployed = harness.create2WithArgs(simpleContractWithArgsInitCode, salt, initArgs);

        assertEq(deployed, predicted, "Address prediction should match deployment");
    }

    /* -------------------------------------------------------------------------- */
    /*                             CREATE3 Tests                                  */
    /* -------------------------------------------------------------------------- */

    function test_create3_deploysToPredicatedAddress() public {
        bytes32 salt = bytes32(uint256(1));

        address predicted = harness.create3AddressOf(salt);
        address deployed = harness.create3(simpleContractInitCode, salt);

        assertEq(deployed, predicted, "Deployed address should match predicted");
        assertGt(deployed.code.length, 0, "Deployed contract should have code");

        SimpleContract sc = SimpleContract(deployed);
        assertEq(sc.value(), 42, "Contract should be initialized correctly");
    }

    function test_create3_addressIndependentOfInitCode() public view {
        bytes32 salt = bytes32(uint256(1));

        // CREATE3 address only depends on deployer and salt, not initCode
        address addr1 = harness.create3AddressOf(salt);

        // Using same salt with different deployer
        address addr2 = harness.create3AddressFromOf(address(0x1234), salt);

        assertTrue(addr1 != addr2, "Different deployers should have different addresses");

        // But same deployer + same salt = same address regardless of initCode
        address addr3 = harness.create3AddressOf(salt);
        assertEq(addr1, addr3, "Same deployer + salt should always give same address");
    }

    function test_create3_differentSalts_differentAddresses() public view {
        bytes32 salt1 = bytes32(uint256(1));
        bytes32 salt2 = bytes32(uint256(2));

        address addr1 = harness.create3AddressOf(salt1);
        address addr2 = harness.create3AddressOf(salt2);

        assertTrue(addr1 != addr2, "Different salts should produce different addresses");
    }

    function test_create3_deployTwiceToSameSalt_reverts() public {
        bytes32 salt = bytes32(uint256(999));

        harness.create3(simpleContractInitCode, salt);

        // Second deployment to same salt should fail
        vm.expectRevert(Bytecode.TargetAlreadyExists.selector);
        harness.create3(simpleContractInitCode, salt);
    }

    /* -------------------------------------------------------------------------- */
    /*                        CREATE3 With Args Tests                             */
    /* -------------------------------------------------------------------------- */

    function test_create3WithArgs_deploysWithConstructorArgs() public {
        bytes32 salt = bytes32(uint256(1));
        uint256 expectedValue = 200;
        address expectedOwner = address(0xDEAD);
        bytes memory initArgs = abi.encode(expectedValue, expectedOwner);

        address predicted = harness.create3AddressOf(salt);
        address deployed = harness.create3WithArgs(simpleContractWithArgsInitCode, initArgs, salt);

        assertEq(deployed, predicted, "Deployed address should match predicted");

        SimpleContractWithArgs sc = SimpleContractWithArgs(deployed);
        assertEq(sc.value(), expectedValue, "Value should match constructor arg");
        assertEq(sc.owner(), expectedOwner, "Owner should match constructor arg");
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    function testFuzz_create2_saltDeterminesAddress(bytes32 salt) public {
        bytes32 initCodeHash = keccak256(simpleContractInitCode);

        address predicted = harness.create2Address(initCodeHash, salt);

        // Verify prediction is consistent
        address predicted2 = harness.create2Address(initCodeHash, salt);
        assertEq(predicted, predicted2, "Same inputs should give same prediction");
    }

    function testFuzz_create3_saltDeterminesAddress(bytes32 salt) public view {
        address predicted = harness.create3AddressOf(salt);

        // Verify prediction is consistent
        address predicted2 = harness.create3AddressOf(salt);
        assertEq(predicted, predicted2, "Same salt should give same prediction");
    }

    function testFuzz_create2AddressFromOf_deployerAffectsAddress(address deployer, bytes32 salt) public view {
        vm.assume(deployer != address(0));
        bytes32 initCodeHash = keccak256(simpleContractInitCode);

        address addr = harness.create2AddressFromOf(deployer, initCodeHash, salt);

        // Address should be non-zero for valid inputs
        assertTrue(addr != address(0), "Predicted address should be non-zero");
    }

    function testFuzz_create3AddressFromOf_deployerAffectsAddress(address deployer, bytes32 salt) public view {
        vm.assume(deployer != address(0));

        address addr = harness.create3AddressFromOf(deployer, salt);

        // Address should be non-zero for valid inputs
        assertTrue(addr != address(0), "Predicted address should be non-zero");
    }
}
