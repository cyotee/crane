// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (interfaces/IERC5267.sol)
pragma solidity ^0.8.0;

import {
    EIP712Storage
} from "../eip712/EIP712Storage.sol";

interface IERC5267Storage {

    struct ERC5267Init {
        string name;
        string version;
    }

}

contract ERC5267Storage
is
EIP712Storage,
IERC5267Storage
{

    function _initERC5267(
        string memory name,
        string memory version
    ) internal {
        _initEIP721(
            // string memory name,
            name,
            // string memory version
            version
        );
    }

    function _initERC5267(
        IERC5267Storage.ERC5267Init memory erc5267Init
    ) internal {
        _initERC5267(
            erc5267Init.name,
            erc5267Init.version
        );
    }

}
