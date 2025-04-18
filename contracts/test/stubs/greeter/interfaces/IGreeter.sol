// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IGreeter {

    event NewMessage(string oldMessage, string newMessage);

    function getMessage()
    external view returns(string memory);

    function setMessage(
        string memory message
    ) external returns(bool);

}