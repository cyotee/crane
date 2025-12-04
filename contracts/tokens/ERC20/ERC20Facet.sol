// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {ERC5267Target} from "@crane/contracts/utils/cryptography/ERC5267/ERC5267Target.sol";
import {ERC2612Target} from "@crane/contracts/tokens/ERC2612/ERC2612Target.sol";
import {BetterIERC20Permit} from "@crane/contracts/interfaces/BetterIERC20Permit.sol";
import {ERC20Target} from "@crane/contracts/tokens/ERC20/ERC20Target.sol";
import {ERC20PermitTarget} from "@crane/contracts/tokens/ERC20/ERC20PermitTarget.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
// import {Create3AwareContract} from "@crane/contracts/factories/create2/aware/Create3AwareContract.sol";
// import {ICreate3Aware} from "@crane/contracts/interfaces/ICreate3Aware.sol";

contract ERC20Facet is ERC20Target, IFacet {
    function facetName() public pure returns (string memory name) {
        return type(ERC20Facet).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](3);

        interfaces[0] = type(IERC20).interfaceId;
        interfaces[1] = type(IERC20Metadata).interfaceId;
        interfaces[2] = type(IERC20Metadata).interfaceId ^ type(IERC20).interfaceId;
    }

    function facetFuncs()
        public
        pure
        virtual
        returns (
            // override
            bytes4[] memory funcs
        )
    {
        funcs = new bytes4[](9);

        funcs[0] = IERC20Metadata.name.selector;
        funcs[1] = IERC20Metadata.symbol.selector;
        funcs[2] = IERC20Metadata.decimals.selector;
        funcs[3] = IERC20.totalSupply.selector;
        funcs[4] = IERC20.balanceOf.selector;
        funcs[5] = IERC20.allowance.selector;
        funcs[6] = IERC20.approve.selector;
        funcs[7] = IERC20.transfer.selector;
        funcs[8] = IERC20.transferFrom.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}
