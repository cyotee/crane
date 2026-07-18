// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibClone} from "@crane/contracts/external/solady/utils/LibClone.sol";

// tag::Clones[]
/**
 * @title Clones
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice OpenZeppelin-compatible ERC-1167 minimal proxy (clone) library implemented as a thin re-export over Solady LibClone.
 * @dev Internal-only API (all functions `internal`). Re-exports `clone`, `cloneDeterministic`, and the two `predictDeterministicAddress` overloads with zero-address failure check + revert.
 * @dev Provides deterministic deployment of minimal proxies for use in factories (e.g. Aerodrome CL/pool factories) and stubs. Preserves exact reexport behavior to LibClone with no logic changes.
 * @dev See AGENTS.md (utility library NatSpec + tags + hyphen for overloads; ConstProdUtils/Better* gold patterns), PRD LR-1 (full tags + rich NatSpec for libs), and LibClone source.
 * @dev No storage (LR-6 n/a). No @custom:selector values on functions (internal); error selector provided via pattern (central values not present for this error so not fabricated here).
 */
library Clones {
    // tag::ERC1167FailedCreateClone[]
    /**
     * @notice Thrown when clone deployment fails (LibClone returned the zero address).
     * @custom:signature ERC1167FailedCreateClone()
     * @custom:selector 0xc2f868f4
     */
    error ERC1167FailedCreateClone();

    // end::ERC1167FailedCreateClone[]

    // tag::clone(address)[]
    /**
     * @notice Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     * @dev This function uses the create opcode, which should never revert.
     * @param implementation The address of the implementation contract the clone will delegate to.
     * @return instance The address of the newly deployed clone.
     */
    function clone(address implementation) internal returns (address instance) {
        instance = LibClone.clone(implementation);
        if (instance == address(0)) revert ERC1167FailedCreateClone();
    }

    // end::clone(address)[]

    // tag::cloneDeterministic(address-bytes32)[]
    /**
     * @notice Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     * @dev This function uses the create2 opcode and a `salt` to deterministically deploy the clone.
     *      Using the same `implementation` and `salt` multiple times will revert, since the clones cannot be deployed twice at the same address.
     * @param implementation The address of the implementation contract the clone will delegate to.
     * @param salt A unique salt used for deterministic deployment.
     * @return instance The address of the newly deployed clone.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        instance = LibClone.cloneDeterministic(implementation, salt);
        if (instance == address(0)) revert ERC1167FailedCreateClone();
    }

    // end::cloneDeterministic(address-bytes32)[]

    // tag::predictDeterministicAddress(address-bytes32-address)[]
    /**
     * @notice Computes the address of a clone deployed using {Clones-cloneDeterministic} with explicit deployer.
     * @dev This is the base overload that accepts the deployer address (used for CREATE2 address prediction).
     * @param implementation The address of the implementation contract.
     * @param salt The salt used at deployment time.
     * @param deployer The address that will perform (or performed) the deterministic deployment.
     * @return predicted The address at which the clone will be / was deployed.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt, address deployer)
        internal
        pure
        returns (address predicted)
    {
        return LibClone.predictDeterministicAddress(implementation, salt, deployer);
    }

    // end::predictDeterministicAddress(address-bytes32-address)[]

    // tag::predictDeterministicAddress(address-bytes32)[]
    /**
     * @notice Computes the address of a clone deployed using {Clones-cloneDeterministic} using `address(this)` as deployer.
     * @dev Convenience overload that delegates to the 3-arg version using `address(this)` as the deployer.
     * @param implementation The address of the implementation contract.
     * @param salt The salt used at deployment time.
     * @return predicted The address at which the clone will be / was deployed.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
    // end::predictDeterministicAddress(address-bytes32)[]
}
// end::Clones[]
