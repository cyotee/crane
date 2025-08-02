// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "../../../../../contracts/constants/CraneINITCODE.sol";
import { ICreate2Aware } from "../../../../../contracts/interfaces/ICreate2Aware.sol";
import { ScriptBase_Crane_ERC20 } from "../../../../../contracts/script/ScriptBase_Crane_ERC20.sol";
import { TestBase_ICreate2Aware } from "../../../../../contracts/test/bases/TestBase_ICreate2Aware.sol";

contract ERC20PermitFacet_ICreate2Aware_Test
is 
    ScriptBase_Crane_ERC20,
    TestBase_ICreate2Aware
{

    function setUp() public
    override(
        // Script_BalancerV3,
        TestBase_ICreate2Aware
    ) {}
    
    function run() public
    override(
        ScriptBase_Crane_ERC20,
        TestBase_ICreate2Aware
    ) {}

    function create2TestInstance() public override returns (ICreate2Aware) {
        return ICreate2Aware(erc20PermitFacet());
    }

    function controlOrigin() public override returns (address) {
        return address(factory());
    }

    function controlInitCodeHash() public pure override returns (bytes32) {
        return ERC20_PERMIT_FACET_INIT_CODE_HASH;
    }

    function controlSalt() public pure override returns (bytes32) {
        return ERC20_PERMIT_FACET_SALT;
    }
    
}