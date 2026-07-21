// SPDX-License-Identifier: GPL-3.0-only
// From rocket-pool/rocketpool interface/RocketStorageInterface.sol (pin in README)
pragma solidity ^0.8.0;

interface RocketStorageInterface {
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint256);
    function getBool(bytes32 _key) external view returns (bool);
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint256 _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function getGuardian() external view returns (address);
}
