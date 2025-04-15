// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "../../constants/Constants.sol";

import {
    UInt
} from "./UInt.sol";

/**
 * @title Library with standardized operations involving address variables.
 * @author various, cyotee doge <doge.cyotee>
 * @dev Attribution to many parties that contributed to the various libraries consolidated into this library.
 */
library Address {

    using Address for address;
    // using Bytecode for address;
    using UInt for uint256;

    /**
     * @dev Considers presence of bytecode as definition of being a "contract".
     * @param account The address of the account to check for being a "contract".
     * @return isContract Boolean indicating is address has attached bytecode.
     */
    function _isContract(address account)
    internal view returns (bool isContract) {
        // return account._codeSizeOf() > 0;
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Left pads (prepends) zeroes to provided address
     * @param value Address to convert to bytes32.
     * @return castValue 32 bytes representation of the provided address.
     */
    function _toBytes32(address value)
    internal pure returns(bytes32 castValue) {
        castValue = bytes32(uint256(uint160(value)));
    }

    function _toString(address account)
    internal pure returns (string memory accountAsString) {
        accountAsString = uint256(uint160(account))._toHexString(20);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function _toHexString(
        address addr
    ) internal pure returns (string memory) {
        return UInt._toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    function _toUint256(
        address value
    ) internal pure returns(uint256 castValue) {
        castValue = uint256(uint160(value));
    }

    function _sendValue(address payable account, uint256 amount)
    internal returns (bool success) { 
        (success, ) = account.call{ value: amount }("");
        require(success, "Address: failed to send value");
    }

    function _functionCall(address target, bytes memory data)
    internal returns (bytes memory returnData) {
        returnData = _functionCall(target, data, "Address: failed low-level call");
    }

    function _functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory returnData) {
        returnData = _functionCallWithValue(target, data, 0, error);
    }

    // function _functionCallWithValue(
    //     address target,
    //     bytes memory data,
    //     uint256 value
    // ) internal returns (bytes memory returnData) {
    //     returnData = _functionCallWithValue(
    //         target,
    //         data,
    //         value,
    //         "Address: failed low-level call with value"
    //     );
    // }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory returnData) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        ( ,returnData) = __functionCallWithValue(target, data, value, error);
    }

    function __functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bool success, bytes memory returnData) {
        require(
            _isContract(target),
            "Address: function call to non-contract"
        );

        (success, returnData) = target.call{ value: value }(data);

        if (success) {
      
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }

    // function _delegateCall(
    //     address target
    // ) internal {
    //     assembly {
    //         calldatacopy(0, 0, calldatasize())
    //         let result := delegatecall(gas(), target, 0, calldatasize(), 0, 0)
    //         returndatacopy(0, 0, returndatasize())

    //         switch result
    //             case 0 {revert(0, returndatasize())}
    //             default {return(0, returndatasize())}
    //     }
    // }

    function _delegateCall(
        address target,
        bytes memory data
    ) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = target.delegatecall(data);
        require(result == true, "Address:_delegateCall:: delegatecall failed");
    }

    function _delegateCall(
        address target,
        bytes4 func,
        bytes memory args
    ) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = target.delegatecall(bytes.concat(func, args));
        require(result == true, "Address:_delegateCall:: delegatecall failed");
    }

    function _delegateCall(
        address target,
        bytes4 func
    ) internal returns(bytes memory returnData) {
        bool result;
        (result, returnData) = target.delegatecall(abi.encodeWithSelector(func));
        require(result == true, "Address:_delegateCall:: delegatecall failed");
    }

}