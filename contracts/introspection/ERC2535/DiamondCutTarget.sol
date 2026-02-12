// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondCut} from "@crane/contracts/interfaces/IDiamondCut.sol";
import {ERC2535Repo} from "@crane/contracts/introspection/ERC2535/ERC2535Repo.sol";
import {MultiStepOwnableModifiers} from "@crane/contracts/access/ERC8023/MultiStepOwnableModifiers.sol";
// import { IOwnable } from "@crane/contracts/crane/interfaces/IOwnable.sol";

contract DiamondCutTarget is MultiStepOwnableModifiers, IDiamond, IDiamondCut {
    /* -------------------------------------------------------------------------- */
    /*                                    LOGIC                                   */
    /* -------------------------------------------------------------------------- */

    function diamondCut(IDiamond.FacetCut[] memory diamondCut_, address initTarget, bytes memory initCalldata)
        public
        virtual
        onlyOwner
    {
        ERC2535Repo._diamondCut(diamondCut_, initTarget, initCalldata);
    }
}
