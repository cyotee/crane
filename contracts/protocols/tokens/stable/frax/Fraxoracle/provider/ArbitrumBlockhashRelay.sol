//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

import "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/interface/IInbox.sol";
import "./ArbitrumBlockhashProvider.sol";

contract ArbitrumBlockhashRelay {
    address public immutable l2Target;
    IInbox public immutable inbox;

    event BlockhashRelayed(uint256 indexed blockNo);

    constructor(address _l2Target, IInbox _inbox) {
        l2Target = _l2Target;
        inbox = _inbox;
    }

    function relayHash(uint256 blockNo, uint256 maxSubmissionCost, uint256 maxGas, uint256 gasPriceBid)
        external
        payable
        returns (uint256 ticketID)
    {
        bytes32 hash = blockhash(blockNo);
        bytes memory data = abi.encodeWithSelector(ArbitrumBlockhashProvider.receiveBlockHash.selector, hash);
        ticketID = inbox.createRetryableTicket{value: msg.value}(
            l2Target, 0, maxSubmissionCost, msg.sender, msg.sender, maxGas, gasPriceBid, data
        );
        emit BlockhashRelayed(blockNo);
    }
}
