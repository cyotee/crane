// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// tag::Counter[]
/**
 * @title Counter - Simple counter stub.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Basic counter for use in tests and stubs. Exposes read via public getter, setNumber and increment.
 * @dev Not intended for production use. A minimal low-complexity test subject (like GreeterTarget, OperableTargetStub, MultiStep* stubs).
 */
contract Counter {
    // tag::number()[]
    /**
     * @notice The current counter value.
     * @dev Public state variable; the compiler generates an implicit getter `number()`.
     * @return The stored number.
     */
    uint256 public number;

    // end::number()[]

    // tag::setNumber(uint256)[]
    /**
     * @notice Sets the counter to an arbitrary new value.
     * @param newNumber The new value for the counter.
     */
    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    // end::setNumber(uint256)[]

    // tag::increment()[]
    /**
     * @notice Increments the counter by 1.
     */
    function increment() public {
        number++;
    }
    // end::increment()[]
}
// end::Counter[]
