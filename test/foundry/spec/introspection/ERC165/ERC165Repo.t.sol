// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {ERC165Repo} from "@crane/contracts/introspection/ERC165/ERC165Repo.sol";

/**
 * @title ERC165RepoStub - Exposes internal ERC165Repo functions for testing
 */
contract ERC165RepoStub {
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

    function supportsInterfaceWithStorage(bytes4 interfaceId) external view returns (bool) {
        return ERC165Repo._supportsInterface(ERC165Repo._layout(), interfaceId);
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

    /// @dev ERC-165 specifies this as an invalid interface ID that must always return false
    bytes4 internal constant INVALID_INTERFACE_ID = 0xffffffff;

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

    /* ------ _supportsInterface(Storage, bytes4) Tests ------ */

    function test_supportsInterface_storage_overload_registered() public {
        // Register an interface first
        stub.registerInterface(TEST_INTERFACE_1);

        // Verify using storage-parameterized overload
        assertTrue(
            stub.supportsInterfaceWithStorage(TEST_INTERFACE_1),
            "_supportsInterface(Storage, bytes4) should return true for registered interface"
        );
    }

    function test_supportsInterface_storage_overload_unregistered() public {
        // Verify unregistered interface returns false via storage-parameterized overload
        assertFalse(
            stub.supportsInterfaceWithStorage(TEST_INTERFACE_1),
            "_supportsInterface(Storage, bytes4) should return false for unregistered interface"
        );
    }

    function test_supportsInterface_storage_overload_multiple() public {
        // Register multiple interfaces
        bytes4[] memory interfaces = new bytes4[](2);
        interfaces[0] = TEST_INTERFACE_1;
        interfaces[1] = TEST_INTERFACE_2;
        stub.registerInterfaces(interfaces);

        // Verify all registered interfaces via storage-parameterized overload
        assertTrue(
            stub.supportsInterfaceWithStorage(TEST_INTERFACE_1),
            "_supportsInterface(Storage, bytes4) should return true for first registered interface"
        );
        assertTrue(
            stub.supportsInterfaceWithStorage(TEST_INTERFACE_2),
            "_supportsInterface(Storage, bytes4) should return true for second registered interface"
        );

        // Verify unregistered interface returns false
        assertFalse(
            stub.supportsInterfaceWithStorage(TEST_INTERFACE_3),
            "_supportsInterface(Storage, bytes4) should return false for unregistered interface"
        );
    }

    function test_supportsInterface_both_overloads_equivalent() public {
        // Register an interface
        stub.registerInterface(TEST_INTERFACE_1);

        // Both overloads should return the same result
        bool resultDefault = stub.supportsInterface(TEST_INTERFACE_1);
        bool resultStorage = stub.supportsInterfaceWithStorage(TEST_INTERFACE_1);

        assertEq(
            resultDefault,
            resultStorage,
            "Both _supportsInterface overloads should return equivalent results for registered interface"
        );

        // Test unregistered interface
        bool unregDefault = stub.supportsInterface(TEST_INTERFACE_2);
        bool unregStorage = stub.supportsInterfaceWithStorage(TEST_INTERFACE_2);

        assertEq(
            unregDefault,
            unregStorage,
            "Both _supportsInterface overloads should return equivalent results for unregistered interface"
        );
    }

    /* ------ 0xffffffff Behavior Documentation Tests ------ */

    /**
     * @notice Documents that ERC165Repo is a generic mapping that does NOT enforce ERC-165 strict semantics.
     * @dev ERC-165 specifies that supportsInterface(0xffffffff) MUST return false.
     * This Repo intentionally allows any bytes4 to be registered; higher-level contracts
     * (ERC165Target/ERC165Facet) are responsible for enforcing ERC-165 compliance.
     *
     * This test documents the behavior: if 0xffffffff is registered, the Repo will return true.
     * This would violate ERC-165 if exposed directly, but the Repo is internal infrastructure.
     */
    function test_registerInterface_0xffffffff_allowed_by_repo() public {
        // Initially not registered
        assertFalse(
            stub.supportsInterface(INVALID_INTERFACE_ID),
            "0xffffffff should not be registered initially"
        );

        // Repo allows registration (it's a generic mapping)
        stub.registerInterface(INVALID_INTERFACE_ID);

        // Repo returns true after registration (violates ERC-165 if exposed directly)
        assertTrue(
            stub.supportsInterface(INVALID_INTERFACE_ID),
            "Repo allows 0xffffffff registration - higher-level contracts must enforce ERC-165 compliance"
        );
    }

    /* ------ Fuzz Tests ------ */

    /**
     * @notice Fuzz test for _registerInterface excluding ERC-165 invalid interface ID.
     * @dev Excludes 0xffffffff because:
     * 1. ERC-165 specifies it as invalid and must always return false
     * 2. The Repo is a generic mapping that doesn't enforce this constraint
     * 3. Testing it would assert true for a value that ERC-165 says must be false
     * See test_registerInterface_0xffffffff_allowed_by_repo for explicit 0xffffffff behavior documentation.
     */
    function testFuzz_registerInterface(bytes4 interfaceId) public {
        // Exclude ERC-165 invalid interface ID - see NatSpec above for rationale
        vm.assume(interfaceId != INVALID_INTERFACE_ID);

        // Should not be registered initially
        assertFalse(stub.supportsInterface(interfaceId), "Interface should not be registered initially");

        // Register
        stub.registerInterface(interfaceId);

        // Should be registered after
        assertTrue(stub.supportsInterface(interfaceId), "Interface should be registered after registration");
    }

    /**
     * @notice Fuzz test for _supportsInterface storage overload excluding ERC-165 invalid interface ID.
     * @dev Excludes 0xffffffff for ERC-165 compliance reasons. See testFuzz_registerInterface NatSpec.
     */
    function testFuzz_supportsInterface_storage_overload(bytes4 interfaceId) public {
        // Exclude ERC-165 invalid interface ID
        vm.assume(interfaceId != INVALID_INTERFACE_ID);

        // Should not be registered initially via storage overload
        assertFalse(
            stub.supportsInterfaceWithStorage(interfaceId),
            "_supportsInterface(Storage, bytes4) should return false for unregistered interface"
        );

        // Register
        stub.registerInterface(interfaceId);

        // Should be registered after via storage overload
        assertTrue(
            stub.supportsInterfaceWithStorage(interfaceId),
            "_supportsInterface(Storage, bytes4) should return true after registration"
        );
    }
}
