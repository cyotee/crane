// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC5115Storage} from "contracts/crane/token/ERC5115/utils/ERC5115Storage.sol";
import {IERC5115} from "contracts/crane/interfaces/IERC5115.sol";
// import { IFacet } from "contracts/crane/interfaces/IFacet.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";

contract ERC5115ViewFacet is Create3AwareContract, ERC5115Storage {
    constructor(CREATE3InitData memory initData_) Create3AwareContract(initData_) {}

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        // TODO Change to an interface for the exposed functions.
        interfaces[0] = type(IERC5115).interfaceId;
        return interfaces;
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](3);
        funcs[0] = IERC5115.yieldToken.selector;
        funcs[1] = IERC5115.getTokensIn.selector;
        funcs[2] = IERC5115.getTokensOut.selector;
        return funcs;
    }

    function yieldToken() external view returns (address) {
        return _yieldToken();
    }
}
