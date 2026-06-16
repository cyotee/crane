//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

import {RLPReader} from "./library/RLPReader.sol";
import {StateProofVerifier as Verifier} from "./library/StateProofVerifier.sol";
import "forge-std/console.sol";

contract StateProver {
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    function logHash(bytes memory _proofRlpBytes) public pure {
        console.logBytes(_proofRlpBytes);
        RLPReader.RLPItem memory item = _proofRlpBytes.toRlpItem();
        console.logBytes32(item.rlpBytesKeccak256());
    }

    function proofStorageRoot(bytes32 stateRootHash, address proofAddress, bytes[] memory _proofBytesArray)
        public
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
        public
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
