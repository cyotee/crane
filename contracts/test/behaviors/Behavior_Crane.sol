// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/StdAssertions.sol";
import { betterconsole as console } from "../../utils/vm/foundry/tools/betterconsole.sol";
// import { DeclaredAddrs } from "../../utils/vm/foundry/tools/DeclaredAddrs.sol";
// import {
//     FoundryVM
// } from "../../utils/vm/foundry/FoundryVM.sol";
import { Behavior } from "./Behavior.sol";
import { IBehavior } from "../../interfaces/IBehavior.sol";
import { Behavior_IFacet } from "./Behavior_IFacet.sol";
import { Behavior_IDiamondFactoryPackage } from "./Behavior_IDiamondFactoryPackage.sol";
import { Behavior_ICreate2Aware } from "./Behavior_ICreate2Aware.sol";
import { Behavior_IERC165 } from "./Behavior_IERC165.sol";
import { Behavior_IDiamondLoupe } from "./Behavior_IDiamondLoupe.sol";

contract Behavior_Crane
is
// DeclaredAddrs,
// FoundryVM,
// StdAssertions,
Behavior,
// IBehavior,
Behavior_IFacet,
Behavior_IDiamondFactoryPackage,
Behavior_ICreate2Aware,
Behavior_IERC165,
Behavior_IDiamondLoupe
{}