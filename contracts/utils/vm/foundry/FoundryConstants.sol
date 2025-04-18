// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// Cheat code address, 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D.
address constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
// console.sol and console2.sol work by executing a staticcall to this address.
address constant CONSOLE = 0x000000000000000000636F6e736F6c652e6c6f67;