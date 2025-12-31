// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC5115ExtensionStorage} from "contracts/crane/token/ERC5115/extensions/utils/ERC5115ExtensionStorage.sol";
import {IERC5115Extension} from "contracts/crane/interfaces/IERC5115Extension.sol";
// import { IFacet } from "contracts/crane/interfaces/IFacet.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";

contract ERC5115ExtensionViewFacet is Create3AwareContract, ERC5115ExtensionStorage, IERC5115Extension {
    constructor(CREATE3InitData memory initData_) Create3AwareContract(initData_) {}

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IERC5115Extension).interfaceId;
        return interfaces;
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = IERC5115Extension.yieldTokenTypes.selector;
        return funcs;
    }

    function yieldTokenTypes() external view returns (bytes4[] memory yieldTokenTypes_) {
        return _yieldTokenTypes().values;
    }
}
