// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {EIP712Storage} from "contracts/crane/utils/cryptography/eip712/EIP712Storage.sol";
import {ERC5267Storage} from "contracts/crane/utils/cryptography/erc5267/ERC5267Storage.sol";
import {IERC20Storage, ERC20Storage} from "contracts/crane/token/ERC20/utils/ERC20Storage.sol";
import {ERC2612Storage} from "contracts/crane/token/ERC20/extensions/utils/ERC2612Storage.sol";
// import {
//     BetterIERC20Permit
// } from "contracts/crane/interfaces/BetterIERC20Permit.sol";

interface IERC20PermitStorage {
    struct ERC20PermitTargetInit {
        IERC20Storage.ERC20StorageInit erc20Init;
        string version;
    }
}

contract ERC20PermitStorage is EIP712Storage, ERC5267Storage, ERC20Storage, ERC2612Storage, IERC20PermitStorage {
    // tag::_initERC20(string,string,uint8)[]
    /**
     * @dev Set minimal values REQUIRED per ERC20.
     * @dev Allows for 0 supply tokens that expose external supply management.
     * @param name The value to set as the token name.
     * @param symbol The value to set as the token symbol.
     * @param decimals The value to set as the token precision.
     */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC20Permit(string memory name, string memory symbol, uint8 decimals, string memory version)
        internal
    {
        _initERC20(name, symbol, decimals);
        _initEIP721(
            // string memory name,
            name,
            // string memory version
            version
        );
    }

    // end::_initERC20(string,string,uint8)[]

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC20Permit(IERC20PermitStorage.ERC20PermitTargetInit memory erc20PermitInit) internal {
        _initERC20(erc20PermitInit.erc20Init);
        _initEIP721(
            // string memory name,
            erc20PermitInit.erc20Init.name,
            // string memory version
            erc20PermitInit.version
        );
    }
}
