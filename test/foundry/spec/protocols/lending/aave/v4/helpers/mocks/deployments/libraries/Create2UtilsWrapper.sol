// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    TransparentUpgradeableProxy
} from "@crane/contracts/external/openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Create2Utils} from "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/Create2Utils.sol";

contract Create2UtilsWrapper {
    function isContractDeployed(address addr) external view returns (bool) {
        return Create2Utils.isContractDeployed(addr);
    }

    function ensureCreate2Factory() external returns (address) {
        return Create2Utils.ensureCreate2Factory();
    }

    function getFactory() external view returns (address) {
        return Create2Utils.getFactory();
    }

    function create2Deploy(bytes32 salt, bytes memory bytecode) external returns (address) {
        return Create2Utils.create2Deploy(salt, bytecode);
    }

    function proxify(bytes32 salt, address logic, address initialOwner, bytes memory data) external returns (address) {
        return Create2Utils.proxify(salt, logic, initialOwner, data);
    }

    function computeCreate2Address(bytes32 salt, bytes32 initcodeHash) external pure returns (address) {
        return Create2Utils.computeCreate2Address(salt, initcodeHash);
    }

    function computeCreate2Address(bytes32 salt, bytes memory bytecode) external pure returns (address) {
        return Create2Utils.computeCreate2Address(salt, bytecode);
    }

    function computeCreate2Address(bytes32 salt, bytes32 initcodeHash, address factory)
        external
        pure
        returns (address)
    {
        return Create2Utils.computeCreate2Address(salt, initcodeHash, factory);
    }

    function addressFromLast20Bytes(bytes32 bytesValue) external pure returns (address) {
        return Create2Utils.addressFromLast20Bytes(bytesValue);
    }
}
