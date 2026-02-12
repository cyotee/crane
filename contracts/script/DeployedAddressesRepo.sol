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

    function _layout(bytes32 slot_) internal pure returns (Storage storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }

    function _layout() internal pure returns (Storage storage) {
        return _layout(STORAGE_SLOT);
    }

    function _registerDeployedAddress(Storage storage layout_, address deployedAddress_, uint256 chainId_, bytes32 instanceId_) internal {
        layout_.deployedAddresses._add(deployedAddress_);
        layout_.deployedAddressOfInstanceId[chainId_][instanceId_] = deployedAddress_;
    }

    function _registerDeployedAddress(address deployedAddress_, uint256 chainId_, bytes32 instanceId_) internal {
        _registerDeployedAddress(_layout(), deployedAddress_, chainId_, instanceId_);
    }

    function _registerDeployedAddress(Storage storage layout_, address deployedAddress_, bytes32 instanceId_) internal {
        _registerDeployedAddress(layout_, deployedAddress_, block.chainid, instanceId_);
    }

    function _registerDeployedAddress(address deployedAddress_, bytes32 instanceId_) internal {
        _registerDeployedAddress(_layout(), deployedAddress_, instanceId_);
    }

    function _deployedAddress(Storage storage layout_, uint256 chainId, bytes32 instanceId_)
        internal
        view
        returns (address)
    {
        return layout_.deployedAddressOfInstanceId[chainId][instanceId_];
    }

    function _deployedAddress(uint256 chainId, bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(_layout(), chainId, instanceId_);
    }

    function _deployedAddress(Storage storage layout_, bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(layout_, block.chainid, instanceId_);
    }

    function _deployedAddress(bytes32 instanceId_) internal view returns (address) {
        return _deployedAddress(_layout(), instanceId_);
    }
}