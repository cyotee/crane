//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

import {RLPReader} from "./RLPReader.sol";
import {StateProofVerifier as Verifier} from "./StateProofVerifier.sol";

library MerkleTreeProver {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    function proofStorageRoot(bytes32 stateRootHash, address proofAddress, bytes[] memory _proofBytesArray)
        internal
        pure
        returns (Verifier.Account memory accountPool)
    {
        RLPReader.RLPItem[] memory proof = new RLPReader.RLPItem[](_proofBytesArray.length);
        for (uint256 i = 0; i < _proofBytesArray.length; i++) {
            proof[i] = _proofBytesArray[i].toRlpItem();
        }
        accountPool = Verifier.extractAccountFromProof(keccak256(abi.encodePacked(proofAddress)), stateRootHash, proof);
    }

    function proofStorageSlotValue(bytes32 storageRoot, bytes32 slot, bytes[] memory _proofBytesArray)
        internal
        pure
        returns (Verifier.SlotValue memory slotValue)
    {
        RLPReader.RLPItem[] memory proof = new RLPReader.RLPItem[](_proofBytesArray.length);
        for (uint256 i = 0; i < _proofBytesArray.length; i++) {
            proof[i] = _proofBytesArray[i].toRlpItem();
        }
        slotValue = Verifier.extractSlotValueFromProof(keccak256(abi.encodePacked(slot)), storageRoot, proof);
    }
}
