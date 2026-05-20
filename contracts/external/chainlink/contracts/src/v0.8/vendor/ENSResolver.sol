// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

abstract contract ENSResolver {
  function addr(bytes32 node) public view virtual returns (address);
}
