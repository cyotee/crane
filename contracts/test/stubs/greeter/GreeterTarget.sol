// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IGreeter} from "@crane/contracts/test/stubs/greeter/IGreeter.sol";
import {GreeterLayout, GreeterRepo} from "@crane/contracts/test/stubs/greeter/GreeterRepo.sol";

// tag::GreeterTarget[]
/**
 * @title GreeterTarget - Target contract implementing IGreeter.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Exposes getMessage and setMessage by delegating to GreeterRepo.
 * @dev Follows Facet-Target-Repo pattern. Delegates entirely to GreeterRepo.
 *      Inherited by GreeterStub (and GreeterFacet in consuming usage). No storage defined here.
 */
contract GreeterTarget is IGreeter {
    // tag::getMessage()[]
    /**
     * @inheritdoc IGreeter
     * @dev Delegates to GreeterRepo._getMessage().
     */
    function getMessage() public view virtual returns (string memory) {
        return GreeterRepo._getMessage();
    }
    // end::getMessage()[]

    // tag::setMessage(string)[]
    /**
     * @inheritdoc IGreeter
     * @dev Uses direct _layoutStruct call for GreeterLayout to access both old message (for event) and set.
     *      Emits NewMessage prior to update. Delegates mutation to GreeterRepo._setMessage.
     * @param message The new message value to persist.
     */
    function setMessage(string memory message) public virtual returns (bool) {
        GreeterLayout storage layoutStruct = GreeterRepo._layoutStruct();
        emit NewMessage(GreeterRepo._getMessage(layoutStruct), message);
        GreeterRepo._setMessage(layoutStruct, message);
        return true;
    }
    // end::setMessage(string)[]
}
// end::GreeterTarget[]
