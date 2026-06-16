// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/Fraxoracle/StateProver-test.js` (proof cases).

import {Test} from "forge-std/Test.sol";
import {StateProver} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/StateProver.sol";
import {
    StateProofVerifier as Verifier
} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/library/StateProofVerifier.sol";
import {StateProverFixtures} from "./StateProverFixtures.sol";

contract StateProver_Test is Test {
    StateProver internal stateProver;

    function setUp() public {
        stateProver = new StateProver();
    }

    function test_setupContracts() public view {
        assertTrue(address(stateProver) != address(0));
    }

    function test_proofStorageRoot() public view {
        bytes32 stateRootHash = 0x74433d8ccc5fef51a0e5861484fed9684ccbd1e3bc0c544bc7365ea95cd653c1;
        address proofAddress = 0x85c5f05Ae4CB68190C695a22b292C3bA90696128;
        bytes32 expectedStorageRoot = 0xddedd31b9fb085bdf1d7ec9d85a393890f7d9afa03b581267386020f9be2f7b2;

        Verifier.Account memory accountInfo =
            stateProver.proofStorageRoot(stateRootHash, proofAddress, StateProverFixtures.accountProof1());
        assertEq(accountInfo.storageRoot, expectedStorageRoot);
    }

    function test_proofStorageSlotValue() public view {
        bytes32 storageHash = 0xddedd31b9fb085bdf1d7ec9d85a393890f7d9afa03b581267386020f9be2f7b2;
        bytes32 storageKey = 0x6e1540171b6c0c960b71a7020d9f60077f6af931a8bbf590da0223dacf75c7af;
        bytes32 expectedValue = 0x6372efe7000000003b9aca005180db0237291a6449dda9ed33ad90a38787621c;

        Verifier.SlotValue memory slotValue =
            stateProver.proofStorageSlotValue(storageHash, storageKey, StateProverFixtures.slotProof1());
        assertEq(bytes32(slotValue.value), expectedValue);
    }

    function test_proofStorageRoot_secondCase() public view {
        bytes32 stateRootHash = 0xb2106bb97488c9c3cdf983bce5254fb71ac3d5d8f277e49509e54c7c68e81699;
        address proofAddress = 0x85c5f05Ae4CB68190C695a22b292C3bA90696128;
        bytes32 expectedStorageRoot = 0x25182d7f7a22bc53c57418f96d7aeb97043420a38dfb495bac70c0bc61e27c73;

        Verifier.Account memory accountInfo =
            stateProver.proofStorageRoot(stateRootHash, proofAddress, StateProverFixtures.accountProof2());
        assertEq(accountInfo.storageRoot, expectedStorageRoot);
    }
}
