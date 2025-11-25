// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Bytes32} from "src/utils/Bytes32.sol";

/**
 * @title A library for deploying contracts EIP-3171 style.
 * @author cyotee doge <doge.cyotee>
 * @author Agustin Aguilar <aa@horizon.io>
 * @dev source - https://raw.githubusercontent.com/0xsequence/create3/master/contracts/Create3.sol
 * @notice originally published under Unlicense
 */
library Bytecode {
    using Bytes32 for bytes32;
    using Bytecode for address;
    using Bytecode for bytes;
    using Bytecode for bytes32;

    /**
     * @dev Thrown when attempting to read an invalid range of bytecode from an address.
     */
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);
    error ErrorCreatingProxy();
    error ErrorCreatingContract();
    error TargetAlreadyExists();

    /**
     * @notice The bytecode for a contract that proxies the creation of another contract
     *     @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address
     *
     * 0x67363d3d37363d34f03d5260086018f3:
     *   0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
     *   0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
     *   0x02  0x52  0x52                  MSTORE
     *   0x03  0x60  0x6008                PUSH1 08        8
     *   0x04  0x60  0x6018                PUSH1 18        24 8
     *   0x05  0xf3  0xf3                  RETURN
     *
     * 0x363d3d37363d34f0:
     *   0x00  0x36  0x36                  CALLDATASIZE    cds
     *   0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
     *   0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
     *   0x03  0x37  0x37                  CALLDATACOPY
     *   0x04  0x36  0x36                  CALLDATASIZE    cds
     *   0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
     *   0x06  0x34  0x34                  CALLVALUE       val 0 cds
     *   0x07  0xf0  0xf0                  CREATE          addr
     */
    bytes internal constant CREATE3_PROXY_INITCODE = hex"67363d3d37363d34f03d5260086018f3";

    //                        CREATE3_PROXY_INITCODEHASH = keccak256(PROXY_CHILD_BYTECODE);
    bytes32 internal constant CREATE3_PROXY_INITCODEHASH = keccak256(CREATE3_PROXY_INITCODE);

    // bytes32 internal constant CREATE3_PROXY_INITCODEHASH = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

    //   bytes private constant MINIMAL_PROXY_INIT_CODE_PREFIX = hex'3d602d80600a3d3981f3_363d3d373d3d3d363d73";
    //   bytes private constant MINIMAL_PROXY_INIT_CODE_SUFFIX = hex'5af43d82803e903d91602b57fd5bf3";

    /**
     *  @notice Returns the size of the code on a given address
     * @param addr Address that may or may not contain code
     * @return size of the code on the given `_addr`
     */
    function codeSizeOf(address addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(addr)
        }
    }

    function codeAt(address addr) internal view returns (bytes memory code) {
        assembly {
            // retrieve the size of the code, this needs assembly
            let size := extcodesize(addr)
            // allocate output byte array - this could also be done without assembly
            // by using code = new bytes(size)
            code := mload(0x40)
            // new "memory end" including padding
            mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
            // store length in memory
            mstore(code, size)
            // actually retrieve the code, this needs assembly
            extcodecopy(addr, add(code, 0x20), 0, size)
        }
    }

    /**
     * @notice Returns the code of a given address
     * @dev It will fail if `_end < _start`
     * @param addr Address that may or may not contain code
     * @param start number of bytes of code to skip on read
     * @param end index before which to end extraction
     * @return oCode read from `_addr` deployed bytecode
     * Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
     */
    function codeAt(address addr, uint256 start, uint256 end) internal view returns (bytes memory oCode) {
        uint256 csize = addr.codeSizeOf();
        if (csize == 0) return bytes("");

        if (start > csize) revert InvalidCodeAtRange(csize, start, end);
        if (end < start) revert InvalidCodeAtRange(csize, start, end);

        unchecked {
            uint256 reqSize = end - start;
            uint256 maxSize = csize - start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(addr, add(oCode, 0x20), start, size)
            }
        }
    }

    /**
     * @notice Generate a creation code that results on a contract with `_code` as bytecode
     * @param code The returning value of the resulting `creationCode`
     * @return creationCode (constructor) for new contract
     */
    function _initCodeFor(bytes memory code) internal pure returns (bytes memory creationCode) {
        /*
            0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
            0x01    0x80         0x80        DUP1                size size
            0x02    0x60         0x600e      PUSH1 14            14 size size
            0x03    0x60         0x6000      PUSH1 00            0 14 size size
            0x04    0x39         0x39        CODECOPY            size
            0x05    0x60         0x6000      PUSH1 00            0 size
            0x06    0xf3         0xf3        RETURN
            <CODE>
        */

        return abi.encodePacked(hex"63", uint32(code.length), hex"80600E6000396000F3", code);
    }

    /**
     * @dev Intended to be used in cases where you only have the initCode for deployment.
     *  Typically you would just use "new" to deploy a contract.
     *  Primarily, this is used for Metamorphic deployments.
     * @param initCode The provided initCode that will be deployed using CREATE.
     * @return deployment The address of the newly deployed contract.
     */
    function create(bytes memory initCode) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create(0, encoded_data, encoded_size)
        }
        require(deployment != address(0), "ByteCodeUtils:_create(bytes):: failed deployment");
    }

    /**
     * @dev Attaches constructor arguments to the provided init code.
     * @param initCode The init code for which the provided arguments will be attached.
     * @param initCodeArgs The ABI encoded constructor arguments to be attached to the provided init code.
     * @return argedInitCode The provided init code with attached constructor args.
     */
    function _encodeInitArgs(bytes memory initCode, bytes memory initCodeArgs)
        internal
        pure
        returns (bytes memory argedInitCode)
    {
        argedInitCode = abi.encodePacked(initCode, initCodeArgs);
    }

    /**
     * @notice deploy contract code using "CREATE" opcode
     * @param initCode contract initialization code
     * @param constructorArgs The arguments to be applied to the provided initCode for deployment.
     * @return deployment address of deployed contract
     */
    function createWithArgs(bytes memory initCode, bytes memory constructorArgs)
        internal
        returns (address deployment)
    {
        deployment = create(_encodeInitArgs(initCode, constructorArgs));
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
        return keccak256(abi.encodePacked(hex"ff", deployer, salt, initCodeHash_))._toAddress();
    }

    /**
     * @notice calculates the creation code hash for calculating determinstic contract addresses.
     * @dev Use this to ensure standardized execution.
     * @param initCode The creation code that will be deployed to a deterministic address.
     * @return initCodeHash The calculated hash for a given creation code.
     */
    function _calcInitCodeHash(bytes memory initCode) internal pure returns (bytes32 initCodeHash) {
        initCodeHash = keccak256(initCode);
    }

    /**
     * @notice calculate the deployment address for a given salt
     * @param initCode The init code for which the provided arguments will be attached.
     * @param initCodeArgs The ABI encoded constructor arguments to be attached to the provided init code.
     * @param salt input for deterministic address calculation
     * @return deployment address
     */
    function _create2WithArgsAddressFromOf(
        address deployer,
        // bytes32 initCodeHash_,
        bytes memory initCode,
        bytes memory initCodeArgs,
        bytes32 salt
    ) internal pure returns (address deployment) {
        // return keccak256(abi.encodePacked(hex'ff', deployer, salt, initCodeHash_))._toAddress();
        return keccak256(
                abi.encodePacked(hex"ff", deployer, salt, initCode._encodeInitArgs(initCodeArgs)._calcInitCodeHash())
            )._toAddress();
    }

    /**
     * @dev Intended to be used in cases where you only have the initCode for deployment.
     *  Typically you would just use "new" to deploy a contract.
     *  Primarily, this is used for Metamorphic deployments.
     * @param initCode The provided initCode that will be deployed using CREATE2.
     * @param salt The value to be used with CREATE2 to get a deterministic address.
     * @return deployment The address of the newly deployed contract.
     */
    function create2(bytes memory initCode, bytes32 salt) internal returns (address deployment) {
        assembly {
            let encoded_data := add(0x20, initCode)
            let encoded_size := mload(initCode)
            deployment := create2(0, encoded_data, encoded_size, salt)
        }
        require(deployment != address(0), "ByteCodeUtils:_create2(bytes,bytes32):: failed deployment");
    }

    /**
     * @dev Deploys the provided init code using CREATE2 after attaching constructor arguments.
     * @dev Intended to be used in cases where you only have the initCode for deployment.
     *  Typically you would just use "new" to deploy a contract.
     *  Primarily, this is used for Metamorphic deployments.
     * @param initCode The provided initCode that will be deployed using CREATE2.
     * @param salt The value to be used with CREATE2 to get a deterministic address.
     * @param initArgs The ABI encoded constructor arguments to be attached to the provided init code.
     */
    function create2WithArgs(bytes memory initCode, bytes32 salt, bytes memory initArgs)
        internal
        returns (address deployment)
    {
        deployment = initCode._encodeInitArgs(initArgs).create2(salt);
    }

    /**
     * @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
     * @param salt Salt of the contract creation, resulting address will be derivated from this value only
     * @return deployment addr of the deployed contract, reverts on error
     * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
     */
    function _create3AddressFromOf(address deployer, bytes32 salt) internal pure returns (address deployment) {
        address proxy =
            keccak256(abi.encodePacked(hex"ff", deployer, salt, Bytecode.CREATE3_PROXY_INITCODEHASH))._toAddress();

        return keccak256(abi.encodePacked(hex"d694", proxy, hex"01"))._toAddress();
    }

    /**
     * @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
     * @param salt Salt of the contract creation, resulting address will be derivated from this value only
     * @return deployedAddress addr of the deployed contract, reverts on error
     * @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
     */
    function _create3AddressOf(bytes32 salt) internal view returns (address deployedAddress) {
        deployedAddress = address(this)._create3AddressFromOf(salt);
    }

    /**
     * @notice Creates a new contract with given `_creationCode` and `_salt`
     * @param initCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
     * @param salt Salt of the contract creation, resulting address will be derivated from this value only
     * @param value In WEI of ETH to be forwarded to child contract
     * @return deployment addr of the deployed contract, reverts on error
     */
    function create3(bytes memory initCode, bytes32 salt, uint256 value) internal returns (address deployment) {
        // // Creation code
        bytes memory creationCode = Bytecode.CREATE3_PROXY_INITCODE;

        // Get target final address
        deployment = salt._create3AddressOf();
        if (deployment.codeSizeOf() != 0) revert TargetAlreadyExists();

        // Create CREATE2 proxy
        address proxy;
        assembly {
            proxy := create2(0, add(creationCode, 32), mload(creationCode), salt)
        }
        if (proxy == address(0)) revert ErrorCreatingProxy();

        // Call proxy with final init code
        (bool success,) = proxy.call{value: value}(initCode);
        if (!success || deployment.codeSizeOf() == 0) revert ErrorCreatingContract();
    }

    /**
     * @notice Creates a new contract with given `_creationCode` and `_salt`
     * @param salt Salt of the contract creation, resulting address will be derivated from this value only
     * @param initCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
     * @return addr of the deployed contract, reverts on error
     */
    function create3(bytes memory initCode, bytes32 salt) internal returns (address addr) {
        // return _create3(_salt, _creationCode, 0);
        return initCode.create3(salt, 0);
    }
}
