// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {InitializeParams} from "./FluidDexLiteStructs.sol";

interface IFluidDexLiteAdminModule {
    function initialize(InitializeParams memory params) external payable;
}
