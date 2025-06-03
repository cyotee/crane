// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { CraneScript } from "../CraneScript.sol";
import { CamelotV2Fixture } from "../../fixtures/protocols/CamelotV2Fixture.sol";

contract CamelotV2Script is CamelotV2Fixture, CraneScript {


    function initialize()
    public virtual
    override(
        CraneScript,
        CamelotV2Fixture
    ) {

    }
}