//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

interface IBlockhashProvider {
   function hashStored(bytes32 hash) external view returns (bool result);
}

