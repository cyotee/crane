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

/// forge-lint: disable-next-line(unaliased-plain-import)
import "contracts/crane/constants/CraneINITCODE.sol";
import {ICreate2Aware} from "contracts/crane/interfaces/ICreate2Aware.sol";
import {ScriptBase_Crane_ERC20} from "contracts/crane/script/ScriptBase_Crane_ERC20.sol";
import {TestBase_ICreate2Aware} from "contracts/crane/test/bases/TestBase_ICreate2Aware.sol";

contract ERC4626DFPkg_ICreate2Aware_Test is ScriptBase_Crane_ERC20, TestBase_ICreate2Aware {
    function setUp()
        public
        override(
            // Script_BalancerV3,
            TestBase_ICreate2Aware
        )
    {
        super.setUp();
    }

    function run() public override(ScriptBase_Crane_ERC20, TestBase_ICreate2Aware) {}

    function create2TestInstance() public override returns (ICreate2Aware) {
        return ICreate2Aware(erc4626DFPkg());
    }

    function controlOrigin() public override returns (address) {
        return address(factory());
    }

    function controlInitCodeHash() public pure override returns (bytes32) {
        return ERC4626_DFPKG_INITCODE_HASH;
    }

    function controlSalt() public pure override returns (bytes32) {
        return ERC4626_DFPKG_SALT;
    }
}
