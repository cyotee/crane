// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title RecipientStub
 * @notice Test recipient contract for verifying Forwarder appended sender semantics
 * @dev When a Forwarder executes a meta-tx, it appends the original sender (20 bytes)
 *      to the calldata. This contract extracts and returns that appended sender.
 */
contract RecipientStub {
    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    event Called(address msgSender, address extractedFrom, bytes data);

    /* -------------------------------------------------------------------------- */
    /*                                   State                                    */
    /* -------------------------------------------------------------------------- */

    address public lastMsgSender;
    address public lastExtractedFrom;
    bytes public lastData;

    /* -------------------------------------------------------------------------- */
    /*                              Test Functions                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Stub function that extracts the appended sender from calldata
     * @return msgSender The actual msg.sender (the Forwarder)
     * @return extractedFrom The appended original sender from meta-tx
     * @return data The original data without the appended sender
     */
    function stubCall(uint256) external returns (address msgSender, address extractedFrom, bytes memory data) {
        msgSender = msg.sender;
        extractedFrom = _getForwardedSender();

        // Original data is everything except the last 20 bytes (the appended address)
        // For this function, original data is the 4-byte selector + 32-byte uint256 argument
        data = msg.data[:msg.data.length - 20];

        lastMsgSender = msgSender;
        lastExtractedFrom = extractedFrom;
        lastData = data;

        emit Called(msgSender, extractedFrom, data);

        return (msgSender, extractedFrom, data);
    }

    /**
     * @notice Stub function that reverts with a custom message
     * @param message The revert message
     */
    function stubRevert(string calldata message) external pure {
        revert(message);
    }

    /**
     * @notice Stub function that accepts ETH value
     * @return value The ETH value received
     */
    function stubValue() external payable returns (uint256 value) {
        value = msg.value;
        return value;
    }

    /**
     * @notice Extract the appended sender from Forwarder calldata
     * @dev The Forwarder appends 20 bytes (the original sender address) to calldata
     */
    function _getForwardedSender() internal pure returns (address sender) {
        // Read the last 20 bytes of calldata as the appended sender address
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    /**
     * @notice Receive ETH
     */
    receive() external payable {}
}
