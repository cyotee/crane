// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibClone} from "@crane/contracts/solady/utils/LibClone.sol";

/**
 * @dev OpenZeppelin-compatible Clones library using Solady's LibClone.
 * @notice Native Crane implementation - no external dependencies
 *
 * This library provides functions to deploy and predict addresses of
 * minimal proxy contracts (ERC-1167 clones).
 *
 * For more information about EIP-1167, see
 * https://eips.ethereum.org/EIPS/eip-1167[EIP 1167].
 */
library Clones {
    /**
     * @dev A clone instance deployment failed.
     */
    error ERC1167FailedCreateClone();

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        instance = LibClone.clone(implementation);
        if (instance == address(0)) revert ERC1167FailedCreateClone();
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple times will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        instance = LibClone.cloneDeterministic(implementation, salt);
        if (instance == address(0)) revert ERC1167FailedCreateClone();
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        return LibClone.predictDeterministicAddress(implementation, salt, deployer);
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt
    ) internal view returns (address predicted) {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}
