// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "../constants/Constants.sol";
import {Bytecode} from "./Bytecode.sol";
import {UInt256} from "./UInt256.sol";

/**
 * @title Drop-in replacement extension of the OZ Address library.
 * @author various, cyotee doge <doge.cyotee>
 * @dev Attribution to many parties that contributed to the various libraries consolidated into this library.
 */
library BetterAddress {

    using BetterAddress for address;
    using Address for address;
    using Bytecode for address;
    using UInt256 for uint256;

    /* ---------------------------------------------------------------------- */
    /*               Wrapper Functions for Drop-In Compatibility              */
    /* ---------------------------------------------------------------------- */

    /**
     * @dev Wrapper function for the OZ Address.sendValue function.
     * @dev Returns true because the underlying function would revert on a failed send.
     */
    function sendValue(address payable recipient, uint256 amount)
    internal returns (bool success) {
        Address.sendValue(recipient, amount);
        // We can presume true because underlying function would revert on a failed send.
        return true;
    }

    /**
     * @dev Wrapper function for the OZ Address.functionCall function.
     */
    function functionCall(address target, bytes memory data)
    internal returns (bytes memory returnData) {
        return Address.functionCall(target, data);
    }

    /**
     * @dev Wrapper function for the OZ Address.functionCallWithValue function.
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory returnData) {
        return Address.functionCallWithValue(target, data, value);
    }

    /**
     * @dev Wrapper function for the OZ Address.functionStaticCall function.
     */
    function functionStaticCall(address target, bytes memory data)
    internal view returns (bytes memory) {
        return Address.functionStaticCall(target, data);
    }

    /**
     * @dev Wrapper function for the OZ Address.functionDelegateCall function.
     */
    function functionDelegateCall(address target, bytes memory data)
    internal returns (bytes memory) {
        return Address.functionDelegateCall(target, data);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata
    ) internal view returns (bytes memory) {
        return Address.verifyCallResultFromTarget(target, success, returndata);
    }

    function verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        return Address.verifyCallResult(success, returndata);
    }

    /* ---------------------------------------------------------------------- */
    /*                                New Logic                               */
    /* ---------------------------------------------------------------------- */

    error NotAContract(address account);

    /**
     * @dev Considers presence of bytecode as definition of being a "contract".
     * @param account The address of the account to check for being a "contract".
     * @return isContract_ Boolean indicating is address has attached bytecode.
     */
    function isContract(address account)
    internal view returns (bool isContract_) {
        return account._codeSizeOf() > 0;
        // uint256 size;
        // assembly { size := extcodesize(account) }
        // return size > 0;
    }

    // function codeAt(address account)
    // internal view returns (bytes memory code_) {
    //     if(!isContract(account)) {
    //         revert NotAContract(account);
    //     }
    //     return account._codeAt();
    // }

    /**
     * @dev Left pads (prepends) zeroes to provided address
     * @param value Address to convert to bytes32.
     * @return castValue 32 bytes representation of the provided address.
     */
    function toBytes32(address value)
    internal pure returns(bytes32 castValue) {
        castValue = bytes32(uint256(uint160(value)));
    }

    function toString(address account)
    internal pure returns (string memory accountAsString) {
        accountAsString = uint256(uint160(account)).toHexString(20);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     */
    function toHexString(
        address addr
    ) internal pure returns (string memory) {
        return UInt256.toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Converts an `address` to a `uint256`.
     * @param value The address to convert.
     * @return castValue The converted value.
     */
    function toUint256(
        address value
    ) internal pure returns(uint256 castValue) {
        castValue = uint256(uint160(value));
    }

}