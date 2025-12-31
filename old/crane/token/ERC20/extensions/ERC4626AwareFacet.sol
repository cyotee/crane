// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {IERC4626Aware} from "contracts/crane/interfaces/IERC4626Aware.sol";
import {ERC4626AwareStorage} from "./utils/ERC4626AwareStorage.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";

contract ERC4626AwareFacet is ERC4626AwareStorage, Create3AwareContract, IFacet {
    constructor(CREATE3InitData memory create3InitData_) Create3AwareContract(create3InitData_) {}

    function facetInterfaces() public pure virtual returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC4626Aware).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IERC4626Aware.erc4626Wrapper.selector;
        funcs[1] = IERC4626Aware.underlying.selector;
    }

    function erc4626Wrapper() public view returns (IERC4626) {
        return _wrapper();
    }

    function underlying() public view returns (IERC20) {
        return _underlying();
    }
}
