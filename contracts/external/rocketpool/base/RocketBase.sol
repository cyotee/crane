// SPDX-License-Identifier: GPL-3.0-only
// Adapted from rocket-pool/rocketpool contracts/contract/RocketBase.sol (0.7 → 0.8)
pragma solidity ^0.8.0;

import {RocketStorageInterface} from "@crane/contracts/external/rocketpool/interface/RocketStorageInterface.sol";

abstract contract RocketBase {
    uint256 internal constant calcBase = 1 ether;
    uint8 public version;
    RocketStorageInterface public rocketStorage;

    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(
            _contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))),
            "Invalid or outdated contract"
        );
        _;
    }

    constructor(RocketStorageInterface _rocketStorageAddress) {
        rocketStorage = _rocketStorageAddress;
    }

    function getAddress(bytes32 _key) internal view returns (address) {
        return rocketStorage.getAddress(_key);
    }

    function getUint(bytes32 _key) internal view returns (uint256) {
        return rocketStorage.getUint(_key);
    }

    function getContractAddress(string memory _contractName) internal view returns (address) {
        return getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
    }
}
