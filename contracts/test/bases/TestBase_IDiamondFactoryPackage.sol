// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { Test_Crane } from "../../test/Test_Crane.sol";
import { IFacet } from "../../interfaces/IFacet.sol";
import { Behavior_IDiamondFactoryPackage } from "../../test/behaviors/Behavior_IDiamondFactoryPackage.sol";

abstract contract TestBase_IDiamondFactoryPackage is Test_Crane, Behavior_IDiamondFactoryPackage {

    // TODO Implement common test logic for IDiamondFactoryPackage implementations
    
}