// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC5267.sol)
pragma solidity ^0.8.0;

import {
    IERC5267
} from "@openzeppelin/contracts/interfaces/IERC5267.sol";    
import {
    ERC5267Storage
} from "./ERC5267Storage.sol";

/**
 * @title ERC5267Target - ERC712 domain declaration standardization contract.
 * @author cyotee doge <doge.cyotee>
 */
contract ERC5267Target
is
ERC5267Storage,
IERC5267
{
    /**
     * @dev See {IERC-5267}.
     */
    function eip712Domain()
        public
        view
        virtual
        returns (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        )
    {
        return (
            hex"0f", // 01111
            _EIP712Name(),
            _EIP712Version(),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }

}