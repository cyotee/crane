// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {
    IDiamondCut
} from "../interfaces/IDiamondCut.sol";
import {
    IDiamond,
    DiamondStorage
} from "../storage/DiamondStorage.sol";
import {
    IOwnable,
    OwnableModifiers
} from "../../../access/ownable/modifiers/OwnableModifiers.sol";

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