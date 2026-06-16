// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// tag::Proxy[]
/**
 * @title Proxy
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Abstract base contract providing a fallback that delegates all calls to an implementation contract
 *         using the EVM `delegatecall` instruction.
 * @dev Native Crane implementation - no external dependencies.
 * @dev This is the low-level proxy utility. The implementation address is supplied by overriding the virtual
 *      {_implementation} function. Delegation can also be triggered via {_fallback} or directly via {_delegate}.
 * @dev The success status and return data from the delegated call are forwarded directly to the proxy's caller.
 *      No other functions are defined; inheritors supply the resolution logic.
 */
abstract contract Proxy {
    // tag::_delegate(address)[]
    /**
     * @notice Delegates the current call to `implementation`.
     * @dev This function does not return to its internal call site; it returns directly to the external caller.
     * @dev The assembly takes full control of memory (overwrites Solidity scratch pad at position 0) and never
     *      returns to calling Solidity code.
     * @param implementation The address of the contract to which the call is delegated.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    // end::_delegate(address)[]

    // tag::_implementation()[]
    /**
     * @notice Returns the address of the implementation contract to which calls should be delegated.
     * @dev This is a virtual function that must be overridden by inheritors to supply the delegation target.
     * @return The implementation address.
     */
    function _implementation() internal view virtual returns (address);
    // end::_implementation()[]

    // tag::_fallback()[]
    /**
     * @notice Delegates the current call to the address returned by {_implementation()}.
     * @dev This function does not return to its internal call site; it returns directly to the external caller.
     */
    function _fallback() internal virtual {
        _delegate(_implementation());
    }
    // end::_fallback()[]

    // tag::fallback()[]
    /**
     * @notice Fallback function that delegates calls to the address returned by {_implementation()}.
     * @dev Will run if no other function in the contract matches the call data. Payable to support value transfers.
     */
    fallback() external payable virtual {
        _fallback();
    }
    // end::fallback()[]
}
// end::Proxy[]
