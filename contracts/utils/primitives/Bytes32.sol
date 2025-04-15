// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../constants/Constants.sol";

/**
 * @title Bytes32 - Standardized operations for bytes32.
 * @author cyotee doge <doge.cyotee>
 */
library Bytes32 {

    // bytes16 private constant HEX_DIGITS = "0123456789abcdef";

    // TODO Could it be possible to calculate and store this immutably on creation?
    // Proxies will be DELEGATECALLING targets.
    // Targets couldn't store this.
    // Maybe proxies can caculate and store their obfuscation value?
    // Viable to reserve slot 0 for this?
    // FML for having to deal with this.
    // Why do humans have to suck sometimes?
    function _scramble(
        bytes32 value
    ) internal view returns(bytes32) {
        return value ^ bytes32((uint256(keccak256(abi.encodePacked(address(this)))) - 1));
    }

    /**
     * @dev Converts an bytes32 to an address truncating from the left.
     * @dev All values over 2^160-1 will be returned as 2^160-1.
     * @param value The value to convert.
     * @return result The converted value.
     */
    function _toAddress(
        bytes32 value
    ) internal pure returns(address result)  {
        //               address(bytes20(value)) is NOT equivalent.
        result = address(uint160(uint256(value)));
    }
  
    function _toHexString(bytes32 _bytes32) internal pure returns (string memory) {
        // 2 characters per byte + "0x" prefix = 66 characters total
        bytes memory result = new bytes(66);
        
        // Set "0x" prefix
        result[0] = "0";
        result[1] = "x";
        
        // Convert each byte to two hex characters
        for (uint256 i = 0; i < 32; i++) {
            uint8 b = uint8(_bytes32[i]);
            // First nibble (high 4 bits)
            result[2 + i * 2] = HEX_SYMBOLS[b >> 4];
            // Second nibble (low 4 bits)
            result[3 + i * 2] = HEX_SYMBOLS[b & 0x0f];
        }
        
        return string(result);
    }

}