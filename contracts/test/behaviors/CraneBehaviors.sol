// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/StdAssertions.sol";
// import {
//     BetterLog
// } from "contracts/crane/utils/vm/foundry/tools/log/BetterLog.sol";
import {betterconsole as console} from "../../utils/vm/foundry/tools/betterconsole.sol";
import {
    DeclaredAddrs
} from "../../utils/vm/foundry/tools/DeclaredAddrs.sol";
import { Behavior } from "./Behavior.sol";
import {
    IBehavior
} from "../../interfaces/IBehavior.sol";
import {
    IFacet_Behavior
} from "./IFacet_Behavior.sol";
import {
    IDiamondFactoryPackage_Behavior
} from "./IDiamondFactoryPackage_Behavior.sol";
import {
    ICreate2Aware_Behavior
} from "./ICreate2Aware_Behavior.sol";
import {
    IERC165_Behavior
} from "./IERC165_Behavior.sol";
import {
    IDiamondLoupe_Behavior
} from "./IDiamondLoupe_Behavior.sol";

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