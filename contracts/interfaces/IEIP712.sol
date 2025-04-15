// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IEIP712 {
    /**
     * @custom:selector 0x3644e515
     */
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}
