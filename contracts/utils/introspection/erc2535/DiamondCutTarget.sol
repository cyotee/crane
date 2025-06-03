// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IDiamondCut
} from "../../../interfaces/IDiamondCut.sol";
import {
    IDiamond,
    DiamondStorage
} from "./utils/DiamondStorage.sol";
import {
    OwnableModifiers
} from "../../../access/ownable/OwnableModifiers.sol";
import { IOwnable } from "../../../interfaces/IOwnable.sol";

contract DiamondCutTarget
is
DiamondStorage
,OwnableModifiers
,IDiamond
,IDiamondCut
{

    /* -------------------------------------------------------------------------- */
    /*                                    LOGIC                                   */
    /* -------------------------------------------------------------------------- */

    function diamondCut(
        IDiamond.FacetCut[] memory diamondCut_,
        address initTarget,
        bytes memory initCalldata
    ) public onlyOwner() virtual {
        _diamondCut(
            diamondCut_,
            initTarget,
            initCalldata
        );
    }

}