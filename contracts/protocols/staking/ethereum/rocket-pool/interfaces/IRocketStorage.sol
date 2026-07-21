// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IRocketStorage
 * @notice Rocket Pool address book.
 * @dev Mainnet: 0x1d8f8f00cfa6758d7bE78336684788Fb0ee0Fa46
 */
interface IRocketStorage {
    function getAddress(bytes32 key) external view returns (address);

    function getBool(bytes32 key) external view returns (bool);

    function getUint(bytes32 key) external view returns (uint256);
}
