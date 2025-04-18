// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/StdAssertions.sol";
// import {
//     BetterLog
// } from "contracts/crane/utils/vm/foundry/tools/log/BetterLog.sol";
import {betterconsole as console} from "../../utils/vm/foundry/tools/console/betterconsole.sol";
import {
    DeclaredAddrs
} from "../../utils/vm/foundry/tools/DeclaredAddrs.sol";

import {
    IBehavior
} from "../../test/behavior/interfaces/IBehavior.sol";

import {
    Behavior
} from "../../test/behavior/Behavior.sol";

import {
    IFacet_Behavior
} from "../../factories/create2/callback/diamondPkg/behaviors/IFacet_Behavior.sol";
import {
    IDiamondFactoryPackage_Behavior
} from "../../factories/create2/callback/diamondPkg/behaviors/IDiamondFactoryPackage_Behavior.sol";
import {
    ICreate2Aware_Behavior
} from "../../factories/create2/aware/behaviors/ICreate2Aware_Behavior.sol";
import {
    IERC165_Behavior
} from "../../introspection/erc165/behaviors/IERC165_Behavior.sol";
import {
    IDiamondLoupe_Behavior
} from "../../introspection/erc2535/behaviors/IDiamondLoupe_Behavior.sol";

contract CraneBehaviors
is
DeclaredAddrs,
StdAssertions,
IBehavior,
Behavior,
IFacet_Behavior,
IDiamondFactoryPackage_Behavior,
ICreate2Aware_Behavior,
IERC165_Behavior,
IDiamondLoupe_Behavior
{}