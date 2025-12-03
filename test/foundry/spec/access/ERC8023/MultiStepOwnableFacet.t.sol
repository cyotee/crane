// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IMultiStepOwnable} from "contracts/interfaces/IMultiStepOwnable.sol";
import {MultiStepOwnableFacetStub} from "contracts/access/ERC8023/MultiStepOwnableFacetStub.sol";
import {TestBase_IMultiStepOwnable} from "contracts/access/ERC8023/TestBase_IMultiStepOwnable.sol";

contract MultiStepOwnableFacetTest is TestBase_IMultiStepOwnable {
    address owner = makeAddr("owner");

    function _deployOwnable() internal virtual override returns (IMultiStepOwnable) {
        return new MultiStepOwnableFacetStub(owner, 1 days);
    }
}
