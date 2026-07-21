// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@crane/contracts/external/openzeppelin-contracts-v4/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
    constructor(
        address _implementation,
        bytes memory _data
    ) ERC1967Proxy(_implementation, _data) {}
}
