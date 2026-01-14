// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";

/**
 * @title ERC165RepoStub - Exposes internal ERC165Repo functions for testing
 */
contract ERC165RepoStub {
    using ERC165Repo for ERC165Repo.Storage;

    function registerInterface(bytes4 interfaceId) external {
        ERC165Repo._registerInterface(interfaceId);
    }

    function registerInterfaceWithStorage(bytes4 interfaceId) external {
        ERC165Repo._registerInterface(ERC165Repo._layout(), interfaceId);
    }

    function registerInterfaces(bytes4[] memory interfaceIds) external {
        ERC165Repo._registerInterfaces(interfaceIds);
    }

    function registerInterfacesWithStorage(bytes4[] memory interfaceIds) external {
        ERC165Repo._registerInterfaces(ERC165Repo._layout(), interfaceIds);
    }

    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return ERC165Repo._supportsInterface(interfaceId);
    }
}

/**
 * @title ERC165Repo_Test - Unit tests for ERC165Repo library
 * @dev Tests both overloads of _registerInterface and _registerInterfaces
 */
contract ERC165Repo_Test is Test {
    ERC165RepoStub internal stub;

    bytes4 internal constant TEST_INTERFACE_1 = 0xdeadbeef;
    bytes4 internal constant TEST_INTERFACE_2 = 0xcafebabe;
    bytes4 internal constant TEST_INTERFACE_3 = 0x12345678;

    function setUp() public {
        stub = new ERC165RepoStub();
    }

    /* ------ _registerInterface(bytes4) Tests ------ */

    function test_registerInterface_single_overload() public {
        // Verify interface is not registered initially
        assertFalse(stub.supportsInterface(TEST_INTERFACE_1), "Interface should not be registered initially");

        // Register using single-argument overload (the one that was buggy)
        stub.registerInterface(TEST_INTERFACE_1);

        // Verify interface is now registered
        assertTrue(stub.supportsInterface(TEST_INTERFACE_1), "Interface should be registered after _registerInterface(bytes4)");
    }

    function test_registerInterface_storage_overload() public {
        // Verify interface is not registered initially
        assertFalse(stub.supportsInterface(TEST_INTERFACE_2), "Interface should not be registered initially");

        // Register using storage-parameterized overload
        stub.registerInterfaceWithStorage(TEST_INTERFACE_2);

        // Verify interface is now registered
        assertTrue(stub.supportsInterface(TEST_INTERFACE_2), "Interface should be registered after _registerInterface(Storage, bytes4)");
    }

    function test_registerInterface_both_overloads_equivalent() public {
        // Register two different interfaces using different overloads
        stub.registerInterface(TEST_INTERFACE_1);
        stub.registerInterfaceWithStorage(TEST_INTERFACE_2);

        // Both should be registered
        assertTrue(stub.supportsInterface(TEST_INTERFACE_1), "Interface 1 should be registered");
        assertTrue(stub.supportsInterface(TEST_INTERFACE_2), "Interface 2 should be registered");

        // Unregistered interface should return false
        assertFalse(stub.supportsInterface(TEST_INTERFACE_3), "Unregistered interface should return false");
    }

    /* ------ _registerInterfaces(bytes4[]) Tests ------ */

    function test_registerInterfaces_single_overload() public {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = TEST_INTERFACE_1;
        interfaces[1] = TEST_INTERFACE_2;

        // Verify interfaces are not registered initially
        assertFalse(stub.supportsInterface(TEST_INTERFACE_1), "Interface 1 should not be registered initially");
        assertFalse(stub.supportsInterface(TEST_INTERFACE_2), "Interface 2 should not be registered initially");

        // Register using single-argument overload
        stub.registerInterfaces(interfaces);

        // Verify all interfaces are now registered
        assertTrue(stub.supportsInterface(TEST_INTERFACE_1), "Interface 1 should be registered");
        assertTrue(stub.supportsInterface(TEST_INTERFACE_2), "Interface 2 should be registered");
    }

    function test_registerInterfaces_storage_overload() public {
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = TEST_INTERFACE_1;
        interfaces[1] = TEST_INTERFACE_2;

        // Register using storage-parameterized overload
        stub.registerInterfacesWithStorage(interfaces);

        // Verify all interfaces are now registered
        assertTrue(stub.supportsInterface(TEST_INTERFACE_1), "Interface 1 should be registered");
        assertTrue(stub.supportsInterface(TEST_INTERFACE_2), "Interface 2 should be registered");
    }

    function test_registerInterfaces_empty_array() public {
        bytes4[] memory interfaces = new bytes4[](0);

        // Should not revert with empty array
        stub.registerInterfaces(interfaces);
    }

    /* ------ IERC165 Interface ID Test ------ */

    function test_registerInterface_IERC165() public {
        bytes4 ierc165Id = type(IERC165).interfaceId;

        // Register IERC165 interface
        stub.registerInterface(ierc165Id);

        // Verify IERC165 is supported
        assertTrue(stub.supportsInterface(ierc165Id), "IERC165 interface should be supported");
    }

    /* ------ Fuzz Tests ------ */

    function testFuzz_registerInterface(bytes4 interfaceId) public {
        // Should not be registered initially
        assertFalse(stub.supportsInterface(interfaceId), "Interface should not be registered initially");

        // Register
        stub.registerInterface(interfaceId);

        // Should be registered after
        assertTrue(stub.supportsInterface(interfaceId), "Interface should be registered after registration");
    }
}
