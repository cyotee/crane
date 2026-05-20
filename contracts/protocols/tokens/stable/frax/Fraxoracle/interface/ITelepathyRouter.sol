pragma solidity ^0.8.35;

interface ITelepathyRouter {
    function send(uint32 destinationChainId, address destinationAddress, bytes calldata data)
        external
        returns (bytes32);
}