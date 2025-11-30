// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "src/utils/Bytecode.sol";

library Creation {
    using Bytecode for address;
    using Bytecode for bytes;

    function create(bytes memory initCode) internal returns (address deployment) {
        deployment = initCode.create();
    }

    /**
     * @notice calculate the deployment address for a given salt
     * @param initCodeHash_ hash of contract initialization code
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function _create2AddressFromOf(address deployer, bytes32 initCodeHash_, bytes32 salt)
        internal
        pure
        returns (address deployment)
    {
        //     address(bytes20(value)) is NOT equivalent.
        return address(uint160(uint256(keccak256(abi.encodePacked(hex"ff", deployer, salt, initCodeHash_)))));
    }

    function _create2Address(bytes32 initCodeHash, bytes32 salt) internal view returns (address deployment) {
        return _create2AddressFromOf(address(this), initCodeHash, salt);
    }

    function _create2WithArgsAddressFromOf(address deployer, bytes memory initCode, bytes memory initArgs, bytes32 salt)
        internal
        pure
        returns (address deployment)
    {
        return deployer._create2WithArgsAddressFromOf(initCode, initArgs, salt);
    }

    function _create2WithArgsAddress(bytes memory initCode, bytes memory initArgs, bytes32 salt)
        internal
        view
        returns (address deployment)
    {
        return _create2WithArgsAddressFromOf(address(this), initCode, initArgs, salt);
    }

    /**
     * @dev Intended to be used in cases where you only have the initCode for deployment.
     *  Typically you would just use "new" to deploy a contract.
     *  Primarily, this is used for Metamorphic deployments.
     * @param initCode The provided initCode that will be deployed using CREATE2.
     * @param salt The value to be used with CREATE2 to get a deterministic address.
     * @return deployment The address of the newly deployed contract.
     */
    function _create2(bytes memory initCode, bytes32 salt) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create2(0, encoded_data, encoded_size, salt)
        }
        require(deployment != address(0), "ByteCodeUtils:_create2(bytes,bytes32):: failed deployment");
    }

    function create2WithArgs(bytes memory initCode, bytes32 salt, bytes memory initArgs)
        internal
        returns (address deployment)
    {
        deployment = initCode.create2WithArgs(salt, initArgs);
    }

    function _create3AddressFromOf(address deployer, bytes32 salt) internal pure returns (address deployment) {
        return deployer._create3AddressFromOf(salt);
    }

    function _create3AddressOf(bytes32 salt) internal view returns (address deployedAddress) {
        return _create3AddressFromOf(address(this), salt);
    }

    function create3(bytes memory initCode, bytes32 salt) internal returns (address deployment) {
        return initCode.create3(salt);
    }

    function _create3WithArgs(bytes memory initCode, bytes memory initArgs, bytes32 salt)
        internal
        returns (address deployment)
    {
        return create3(abi.encodePacked(initCode, initArgs), salt);
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
