// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC5267.sol)
pragma solidity ^0.8.0;

import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";
import {EIP712Layout, EIP712Repo} from "@crane/contracts/utils/cryptography/EIP712/EIP712Repo.sol";

/**
 * @title ERC5267Target - ERC712 domain declaration standardization contract.
 * @author cyotee doge <doge.cyotee>
 */
contract ERC5267Target is IERC5267 {
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
        EIP712Layout storage layout = EIP712Repo._layout();
        return (
            hex"0f", // 01111
            EIP712Repo._EIP712Name(layout),
            EIP712Repo._EIP712Version(layout),
            block.chainid,
            address(this),
            bytes32(0),
            new uint256[](0)
        );
    }
}
