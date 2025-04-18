// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./primitives/Bytecode.sol";

library Creation {

    using Bytecode for address;
    using Bytecode for bytes;

    function _create(
        bytes memory initCode
    ) internal returns(address deployment) {
        deployment = initCode._create();
    }

    // function create(
    //     bytes memory initCode
    // ) external returns(address deployment) {
    //     deployment = _create(initCode);
    // }

    /**
     * @notice calculate the deployment address for a given salt
     * @param initCodeHash_ hash of contract initialization code
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function _create2AddressFromOf(
        address deployer,
        bytes32 initCodeHash_,
        bytes32 salt
    ) internal pure returns (address deployment) {
        //     address(bytes20(value)) is NOT equivalent.
        return address(uint160(uint256(keccak256(abi.encodePacked(hex'ff', deployer, salt, initCodeHash_)))));
    }

    /**
     * @dev Intended to be used in cases where you only have the initCode for deployment.
     *  Typically you would just use "new" to deploy a contract.
     *  Primarily, this is used for Metamorphic deployments.
     * @param initCode The provided initCode that will be deployed using CREATE2.
     * @param salt The value to be used with CREATE2 to get a deterministic address.
     * @return deployment The address of the newly deployed contract.
     */
    function _create2(
        bytes memory initCode,
        bytes32 salt
    ) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create2(0, encoded_data, encoded_size, salt)
        }
        require(deployment != address(0), "ByteCodeUtils:_create2(bytes,bytes32):: failed deployment");
    }

    function _create2WithArgs(
        bytes memory initCode,
        bytes32 salt,
        bytes memory initArgs
    ) internal returns(address deployment) {
        deployment = initCode._create2WithArgs(
        salt,
        initArgs
        );
    }

    // function create2WithArgs(
    //     bytes memory initCode,
    //     bytes32 salt,
    //     bytes memory initArgs
    // ) external returns(address deployment) {
    //     deployment = _create2WithArgs(
    //     initCode,
    //     salt,
    //     initArgs
    //     );
    // }

}