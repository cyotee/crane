// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// import {Vm} from "forge-std/Vm.sol";
/// forge-lint: disable-next-line(unaliased-plain-import)
import "@crane/contracts/constants/FoundryConstants.sol";
import {AddressSet, AddressSetRepo} from "@crane/contracts/utils/collections/sets/AddressSetRepo.sol";

library DeployedAddressesRepo {
    using AddressSetRepo for AddressSet;
    /// forge-lint: disable-next-line(screaming-snake-case-const)
    // Vm constant vm = Vm(VM_ADDRESS);

    bytes32 internal constant STORAGE_SLOT = keccak256(abi.encode("crane.contracts.deployedAddresses"));

    struct Storage {
        AddressSet deployedAddresses;
        mapping(uint256 chainId => mapping(bytes32 instanceId => address deployedAddress)) deployedAddressOfInstanceId;
    }

    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _registerDeployedAddress(
        Storage storage layoutStruct,
        address deployedAddress_,
        uint256 chainId_,
        bytes32 instanceId_
    ) internal {
        layoutStruct.deployedAddresses._add(deployedAddress_);
        layoutStruct.deployedAddressOfInstanceId[chainId_][instanceId_] = deployedAddress_;
    }

    function _registerDeployedAddress(address deployedAddress_, uint256 chainId_, bytes32 instanceId_) internal {
        _registerDeployedAddress(_layoutStruct(), deployedAddress_, chainId_, instanceId_);
    }

    function _registerDeployedAddress(Storage storage layoutStruct, address deployedAddress_, bytes32 instanceId_) internal {
        _registerDeployedAddress(layoutStruct, deployedAddress_, block.chainid, instanceId_);
    }

    function _registerDeployedAddress(address deployedAddress_, bytes32 instanceId_) internal {
        _registerDeployedAddress(_layoutStruct(), deployedAddress_, instanceId_);
    }

    function _deployedAddress(Storage storage layoutStruct, uint256 chainId, bytes32 instanceId_)
        internal
        view
        returns (address)
    {
        return layoutStruct.deployedAddressOfInstanceId[chainId][instanceId_];
    }

    function _deployedAddress(uint256 chainId, bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(_layoutStruct(), chainId, instanceId_);
    }

    function _deployedAddress(Storage storage layoutStruct, bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(layoutStruct, block.chainid, instanceId_);
    }

    function _deployedAddress(bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(_layoutStruct(), instanceId_);
    }
}
