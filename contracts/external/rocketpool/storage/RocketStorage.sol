// SPDX-License-Identifier: GPL-3.0-only
// Minimal RocketStorage for domain tests — key layout matches upstream ("contract.address"+name)
pragma solidity ^0.8.0;

import {RocketStorageInterface} from "@crane/contracts/external/rocketpool/interface/RocketStorageInterface.sol";

contract RocketStorage is RocketStorageInterface {
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => bool) private boolStorage;
    address public guardian;

    constructor() {
        guardian = msg.sender;
    }

    function getGuardian() external view returns (address) {
        return guardian;
    }

    function getAddress(bytes32 _key) external view returns (address) {
        return addressStorage[_key];
    }

    function getUint(bytes32 _key) external view returns (uint256) {
        return uintStorage[_key];
    }

    function getBool(bytes32 _key) external view returns (bool) {
        return boolStorage[_key];
    }

    function setAddress(bytes32 _key, address _value) external {
        addressStorage[_key] = _value;
    }

    function setUint(bytes32 _key, uint256 _value) external {
        uintStorage[_key] = _value;
    }

    function setBool(bytes32 _key, bool _value) external {
        boolStorage[_key] = _value;
    }

    /// @dev Register a network contract under the upstream key layout
    function setContractAddress(string memory _name, address _addr) external {
        addressStorage[keccak256(abi.encodePacked("contract.address", _name))] = _addr;
        boolStorage[keccak256(abi.encodePacked("contract.exists", _addr))] = true;
    }
}
