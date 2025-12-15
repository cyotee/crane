// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ADDRESS_LENGTH} from "@crane/contracts/constants/Constants.sol";
import {IERC20 as OZIERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {BetterIERC20 as IERC20} from "@crane/contracts/interfaces/BetterIERC20.sol";
import {Bytecode} from "@crane/contracts/utils/Bytecode.sol";
import {UInt256} from "@crane/contracts/utils/UInt256.sol";

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
    function sendValue(address payable recipient, uint256 amount) internal returns (bool success) {
        Address.sendValue(recipient, amount);
        // We can presume true because underlying function would revert on a failed send.
        return true;
    }

    /**
     * @dev Wrapper function for the OZ Address.functionCall function.
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory returnData) {
        return Address.functionCall(target, data);
    }

    /**
     * @dev Wrapper function for the OZ Address.functionCallWithValue function.
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value)
        internal
        returns (bytes memory returnData)
    {
        return Address.functionCallWithValue(target, data, value);
    }

    /**
     * @dev Wrapper function for the OZ Address.functionStaticCall function.
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return Address.functionStaticCall(target, data);
    }

    /**
     * @dev Wrapper function for the OZ Address.functionDelegateCall function.
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return Address.functionDelegateCall(target, data);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResultFromTarget function.
     */
    function _verifyCallResultFromTarget(address target, bool success, bytes memory returndata)
        internal
        view
        returns (bytes memory)
    {
        return Address.verifyCallResultFromTarget(target, success, returndata);
    }

    /**
     * @dev Wrapper function for the OZ Address.verifyCallResult function.
     */
    function _verifyCallResult(bool success, bytes memory returndata) internal pure returns (bytes memory) {
        return Address.verifyCallResult(success, returndata);
    }

    /* ---------------------------------------------------------------------- */
    /*                                New Logic                               */
    /* ---------------------------------------------------------------------- */

    error NotAContract(address account);

    /**
     * @dev Considers presence of bytecode as definition of being a "contract".
     * @dev Marked as external call because it does access extcodesize.
     * @param account The address of the account to check for being a "contract".
     * @return isContract_ Boolean indicating is address has attached bytecode.
     */
    function isContract(address account) internal view returns (bool isContract_) {
        return account.codeSizeOf() > 0;
    }

    /**
     * @dev Returns the bytecode stored at the provided address.
     * @dev Will return an empty value if the address has no bytecode.
     * @param account The address for which to get the bytecode.
     */
    function codeAt(address account) internal view returns (bytes memory code_) {
        if (!isContract(account)) {
            return "";
        }
        return Bytecode.codeAt(account);
    }

    /**
     * @dev Left pads (prepends) zeroes to provided address
     * @param value Address to convert to bytes32.
     * @return castValue 32 bytes representation of the provided address.
     */
    function _toBytes32(address value) internal pure returns (bytes32 castValue) {
        castValue = bytes32(uint256(uint160(value)));
    }

    /**
     * @dev Converts the address to a string.
     * @param account The address to convert to a string representation.
     * @return accountAsString The string representation of the provided address.
     */
    function _toString(address account) internal pure returns (string memory accountAsString) {
        accountAsString = uint256(uint160(account))._toHexString(20);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal
     * representation.
     * @param addr The addreess for which to get a string representation.
     * @return The string representation of the provided address.
     */
    function _toHexString(address addr) internal pure returns (string memory) {
        return UInt256._toHexString(uint256(uint160(addr)), ADDRESS_LENGTH);
    }

    /**
     * @dev Converts an `address` to a `uint256`.
     * @param value The address to convert.
     * @return castValue The converted value.
     */
    function _toUint256(address value) internal pure returns (uint256 castValue) {
        castValue = uint256(uint160(value));
    }

    /**
     * @dev Converts an array of addresses into an array of BetterIERC20.
     * @param addresses The array to convert to BetterIERC20.
     * @return erc20s The array of addresses as BetterIERC20.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _toIERC20(address[] memory addresses) internal pure returns (IERC20[] memory erc20s) {
        erc20s = new IERC20[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            erc20s[i] = IERC20(addresses[i]);
        }
        return erc20s;
    }

    /**
     * @dev Converts an array of addresses into and array of Open Zeppelin IERC20.
     * @param addresses The array to convert ot Open Zeppelin IERC20.
     * @return erc20s The array of addresses as Open Zeppelin IERC20.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _toOZIERC20(address[] memory addresses) internal pure returns (OZIERC20[] memory erc20s) {
        erc20s = new OZIERC20[](addresses.length);
        for (uint256 i = 0; i < addresses.length; i++) {
            erc20s[i] = OZIERC20(addresses[i]);
        }
    }

    /**
     * @dev In-place BubbleSort in ascending order
     * @param array The array to sort in ascending order.
     * @return The array sorted in ascending order.
     */
    function _sort(address[] memory array) internal pure returns (address[] memory) {
        bool swapped;
        for (uint256 i = 1; i < array.length; i++) {
            swapped = false;
            for (uint256 j = 0; j < array.length - i; j++) {
                address next = array[j + 1];
                address actual = array[j];
                if (next < actual) {
                    array[j] = next;
                    array[j + 1] = actual;
                    swapped = true;
                }
            }
            if (!swapped) {
                return array;
            }
        }

        return array;
    }

    /**
     * @dev Recursive Bubble Sort in ascending order.
     * @dev Takes advantage of operating on a memory pointer and does not return a sorted array.
     * @dev Simply edits via the memory pointer.
     * @param _arr The array to sort in ascending order.
     * @param unsortedLen The unsorted portion of the array.
     */
    function _sort(address[] memory _arr, uint256 unsortedLen) internal pure {
        if (unsortedLen == 0 || unsortedLen == 1) {
            return;
        }

        for (uint256 i = 0; i < unsortedLen - 1;) {
            if (_arr[i] > _arr[i + 1]) {
                (_arr[i], _arr[i + 1]) = (_arr[i + 1], _arr[i]);
            }
            unchecked {
                ++i;
            }
        }
        _sort(_arr, unsortedLen - 1);
    }
}
