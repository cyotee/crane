// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC5267Facet} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Facet.sol";
import {ERC5267Target} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Target.sol";
import {EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {TestBase_IFacet} from "@crane/contracts/factories/diamondPkg/TestBase_IFacet.sol";

/**
 * @title ERC5267Harness
 * @notice Test harness that exposes ERC5267Target functions with EIP712 initialization.
 */
contract ERC5267Harness is ERC5267Target {
    function initialize(string memory name, string memory version) external {
        EIP712Repo._initialize(name, version);
    }
}

/**
 * @title ERC5267Facet_Test
 * @notice Comprehensive tests for ERC-5267 domain separator declaration.
 * @dev Tests verify the eip712Domain() function returns correct values.
 */
contract ERC5267Facet_Test is Test {
    ERC5267Harness internal harness;

    string constant NAME = "TestToken";
    string constant VERSION = "1";

    function setUp() public {
        harness = new ERC5267Harness();
        harness.initialize(NAME, VERSION);
    }

    /* -------------------------------------------------------------------------- */
    /*                          eip712Domain() Return Values                      */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_returnsAllExpectedFields() public view {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = harness.eip712Domain();

        // Verify all fields have expected values
        assertEq(fields, hex"0f", "Fields bitmap should be 0x0f");
        assertEq(name, NAME, "Name should match initialized value");
        assertEq(version, VERSION, "Version should match initialized value");
        assertEq(chainId, block.chainid, "ChainId should match block.chainid");
        assertEq(verifyingContract, address(harness), "VerifyingContract should be address(this)");
        assertEq(salt, bytes32(0), "Salt should be zero");
        assertEq(extensions.length, 0, "Extensions array should be empty");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Fields Bitmap Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_fieldsBitmap_correctBits() public view {
        (bytes1 fields,,,,,, ) = harness.eip712Domain();

        // 0x0f = 00001111 in binary
        // Bit 0 (0x01): name is present
        // Bit 1 (0x02): version is present
        // Bit 2 (0x04): chainId is present
        // Bit 3 (0x08): verifyingContract is present
        // Bit 4 (0x10): salt is NOT present
        // Bit 5 (0x20): extensions is NOT present

        assertEq(fields, bytes1(0x0f), "Fields should indicate name, version, chainId, verifyingContract");

        // Verify each bit explicitly
        assertTrue((fields & bytes1(0x01)) != 0, "Bit 0 (name) should be set");
        assertTrue((fields & bytes1(0x02)) != 0, "Bit 1 (version) should be set");
        assertTrue((fields & bytes1(0x04)) != 0, "Bit 2 (chainId) should be set");
        assertTrue((fields & bytes1(0x08)) != 0, "Bit 3 (verifyingContract) should be set");
        assertTrue((fields & bytes1(0x10)) == 0, "Bit 4 (salt) should NOT be set");
        assertTrue((fields & bytes1(0x20)) == 0, "Bit 5 (extensions) should NOT be set");
    }

    function test_eip712Domain_fieldsBitmap_valueIs0x0f() public view {
        (bytes1 fields,,,,,, ) = harness.eip712Domain();
        assertEq(uint8(fields), 0x0f, "Fields bitmap should equal 15 (0x0f)");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Name Tests                                       */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_name_matchesInitialized() public view {
        (, string memory name,,,,, ) = harness.eip712Domain();
        assertEq(name, NAME, "Name should match initialized value");
    }

    function test_eip712Domain_name_differentInitValues() public {
        ERC5267Harness harness2 = new ERC5267Harness();
        string memory differentName = "DifferentToken";
        harness2.initialize(differentName, VERSION);

        (, string memory name,,,,, ) = harness2.eip712Domain();
        assertEq(name, differentName, "Name should match different initialized value");
    }

    function test_eip712Domain_name_longName() public {
        ERC5267Harness harness2 = new ERC5267Harness();
        string memory longName = "This is a very long token name that exceeds 31 bytes for ShortString storage";
        harness2.initialize(longName, VERSION);

        (, string memory name,,,,, ) = harness2.eip712Domain();
        assertEq(name, longName, "Long name should be correctly returned");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Version Tests                                    */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_version_matchesInitialized() public view {
        (,, string memory version,,,, ) = harness.eip712Domain();
        assertEq(version, VERSION, "Version should match initialized value");
    }

    function test_eip712Domain_version_differentVersions() public {
        ERC5267Harness harness2 = new ERC5267Harness();
        harness2.initialize(NAME, "2");

        (,, string memory version,,,, ) = harness2.eip712Domain();
        assertEq(version, "2", "Version should match initialized version 2");
    }

    function test_eip712Domain_version_semverFormat() public {
        ERC5267Harness harness2 = new ERC5267Harness();
        string memory semver = "1.0.0";
        harness2.initialize(NAME, semver);

        (,, string memory version,,,, ) = harness2.eip712Domain();
        assertEq(version, semver, "Semver format should be correctly returned");
    }

    /* -------------------------------------------------------------------------- */
    /*                            ChainId Tests                                    */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_chainId_matchesBlockChainid() public view {
        (,,, uint256 chainId,,, ) = harness.eip712Domain();
        assertEq(chainId, block.chainid, "ChainId should match block.chainid");
    }

    function test_eip712Domain_chainId_updatesOnChainChange() public {
        // Get chainId on original chain
        (,,, uint256 originalChainId,,, ) = harness.eip712Domain();
        assertEq(originalChainId, block.chainid, "Should match original chain");

        // Change to Arbitrum
        vm.chainId(42161);
        (,,, uint256 arbitrumChainId,,, ) = harness.eip712Domain();
        assertEq(arbitrumChainId, 42161, "Should return Arbitrum chainId");

        // Change to Mainnet
        vm.chainId(1);
        (,,, uint256 mainnetChainId,,, ) = harness.eip712Domain();
        assertEq(mainnetChainId, 1, "Should return Mainnet chainId");
    }

    function test_eip712Domain_chainId_multipleChains() public {
        uint256[] memory chainIds = new uint256[](5);
        chainIds[0] = 1;      // Mainnet
        chainIds[1] = 10;     // Optimism
        chainIds[2] = 137;    // Polygon
        chainIds[3] = 42161;  // Arbitrum
        chainIds[4] = 8453;   // Base

        for (uint256 i = 0; i < chainIds.length; i++) {
            vm.chainId(chainIds[i]);
            (,,, uint256 returnedChainId,,, ) = harness.eip712Domain();
            assertEq(returnedChainId, chainIds[i], "ChainId should match for each chain");
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                        VerifyingContract Tests                              */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_verifyingContract_matchesAddressThis() public view {
        (,,,, address verifyingContract,, ) = harness.eip712Domain();
        assertEq(verifyingContract, address(harness), "VerifyingContract should be address(this)");
    }

    function test_eip712Domain_verifyingContract_differentContractsDifferentAddresses() public {
        ERC5267Harness harness2 = new ERC5267Harness();
        harness2.initialize(NAME, VERSION);

        (,,,, address vc1,, ) = harness.eip712Domain();
        (,,,, address vc2,, ) = harness2.eip712Domain();

        assertTrue(vc1 != vc2, "Different contracts should have different verifyingContract");
        assertEq(vc1, address(harness), "First should be harness address");
        assertEq(vc2, address(harness2), "Second should be harness2 address");
    }

    /* -------------------------------------------------------------------------- */
    /*                              Salt Tests                                     */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_salt_isZero() public view {
        (,,,,, bytes32 salt, ) = harness.eip712Domain();
        assertEq(salt, bytes32(0), "Salt should be zero");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Extensions Tests                                   */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_extensions_isEmpty() public view {
        (,,,,,, uint256[] memory extensions) = harness.eip712Domain();
        assertEq(extensions.length, 0, "Extensions array should be empty");
    }

    function test_eip712Domain_extensions_isNewEmptyArray() public view {
        (,,,,,, uint256[] memory extensions1) = harness.eip712Domain();
        (,,,,,, uint256[] memory extensions2) = harness.eip712Domain();

        // Both should be empty but separate array allocations
        assertEq(extensions1.length, 0, "First extensions should be empty");
        assertEq(extensions2.length, 0, "Second extensions should be empty");
    }

    /* -------------------------------------------------------------------------- */
    /*                             Consistency Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_eip712Domain_consistentAcrossMultipleCalls() public view {
        (
            bytes1 fields1,
            string memory name1,
            string memory version1,
            uint256 chainId1,
            address verifyingContract1,
            bytes32 salt1,
            uint256[] memory extensions1
        ) = harness.eip712Domain();

        (
            bytes1 fields2,
            string memory name2,
            string memory version2,
            uint256 chainId2,
            address verifyingContract2,
            bytes32 salt2,
            uint256[] memory extensions2
        ) = harness.eip712Domain();

        assertEq(fields1, fields2, "Fields should be consistent");
        assertEq(keccak256(bytes(name1)), keccak256(bytes(name2)), "Name should be consistent");
        assertEq(keccak256(bytes(version1)), keccak256(bytes(version2)), "Version should be consistent");
        assertEq(chainId1, chainId2, "ChainId should be consistent");
        assertEq(verifyingContract1, verifyingContract2, "VerifyingContract should be consistent");
        assertEq(salt1, salt2, "Salt should be consistent");
        assertEq(extensions1.length, extensions2.length, "Extensions length should be consistent");
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                    */
    /* -------------------------------------------------------------------------- */

    function testFuzz_eip712Domain_name(string memory fuzzName) public {
        vm.assume(bytes(fuzzName).length > 0);
        vm.assume(bytes(fuzzName).length < 1000); // Reasonable limit

        ERC5267Harness harness2 = new ERC5267Harness();
        harness2.initialize(fuzzName, VERSION);

        (, string memory returnedName,,,,, ) = harness2.eip712Domain();
        assertEq(returnedName, fuzzName, "Name should match fuzzed input");
    }

    function testFuzz_eip712Domain_version(string memory fuzzVersion) public {
        vm.assume(bytes(fuzzVersion).length > 0);
        vm.assume(bytes(fuzzVersion).length < 1000); // Reasonable limit

        ERC5267Harness harness2 = new ERC5267Harness();
        harness2.initialize(NAME, fuzzVersion);

        (,, string memory returnedVersion,,,, ) = harness2.eip712Domain();
        assertEq(returnedVersion, fuzzVersion, "Version should match fuzzed input");
    }

    function testFuzz_eip712Domain_chainId(uint64 fuzzChainId) public {
        vm.assume(fuzzChainId > 0);

        vm.chainId(fuzzChainId);
        (,,, uint256 returnedChainId,,, ) = harness.eip712Domain();
        assertEq(returnedChainId, fuzzChainId, "ChainId should match fuzzed chainId");
    }

    function testFuzz_eip712Domain_fieldsAlways0x0f(string memory fuzzName, string memory fuzzVersion) public {
        vm.assume(bytes(fuzzName).length > 0);
        vm.assume(bytes(fuzzVersion).length > 0);
        vm.assume(bytes(fuzzName).length < 500);
        vm.assume(bytes(fuzzVersion).length < 500);

        ERC5267Harness harness2 = new ERC5267Harness();
        harness2.initialize(fuzzName, fuzzVersion);

        (bytes1 fields,,,,,, ) = harness2.eip712Domain();
        assertEq(fields, hex"0f", "Fields should always be 0x0f regardless of name/version");
    }
}

/* -------------------------------------------------------------------------- */
/*                            IFacet Pattern Tests                             */
/* -------------------------------------------------------------------------- */

/**
 * @title ERC5267Facet_IFacet_Test
 * @notice Tests ERC5267Facet's IFacet implementation using the TestBase_IFacet pattern.
 * @dev Validates facet metadata (name, interfaces, functions) using Behavior_IFacet.
 */
contract ERC5267Facet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public virtual override returns (IFacet) {
        return new ERC5267Facet();
    }

    function controlFacetName() public view virtual override returns (string memory facetName) {
        return type(ERC5267Facet).name;
    }

    function controlFacetInterfaces() public view virtual override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);

        controlInterfaces[0] = type(IERC5267).interfaceId;
    }

    function controlFacetFuncs() public view virtual override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](1);

        controlFuncs[0] = IERC5267.eip712Domain.selector;
    }
}
