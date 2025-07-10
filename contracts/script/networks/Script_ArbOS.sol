// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {
    CommonBase,
    ScriptBase,
    TestBase
} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {
    StdCheatsSafe,
    StdCheats
} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import { Script } from "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { BetterScript } from "../BetterScript.sol";
import {LOCAL} from "../../constants/networks/LOCAL.sol";
import {ARB_OS_PRECOMPILES} from "../../constants/networks/ARB_OS_PRECOMPILES.sol";

// import { ArbOSVM } from "../../utils/vm/arbOS/ArbOSVM.sol";
import { IArbOwnerPublic } from "../../interfaces/networks/IArbOwnerPublic.sol";
import { ArbOwnerPublicStub } from "../../utils/vm/arbOS/stubs/precompiles/ArbOwnerPublicStub.sol";

contract Script_ArbOS
is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript
{

    uint64 constant DEFAULT_SHARE_PRICE = 1060183780;

    function initPrecompiles_ArbOS()
    public {
        vm.etch(
            address(arbOwnerPublic()),
            address(arbOwnerPublicStub()).code
        );
        setSharePrice(DEFAULT_SHARE_PRICE);
    }

    function setSharePrice(
        uint64 newSharePrice
    ) public returns(bool) {
        ArbOwnerPublicStub(ARB_OS_PRECOMPILES.ARB_OWNER_PUBLIC)
        .setSharePrice(newSharePrice);
        return true;
    }

    function arbOwnerPublic()
    public virtual
    returns(IArbOwnerPublic) {
        return IArbOwnerPublic(ARB_OS_PRECOMPILES.ARB_OWNER_PUBLIC);
    }

    IArbOwnerPublic internal _arbOwnerPublic;

    function arbOwnerPublicStub()
    public virtual
    returns(IArbOwnerPublic) {
        if(block.chainid == LOCAL.CHAIN_ID) {
            revert("Fixture_ArbOS: ArbOwnerPublicStub is NOT supported on LOCAL");
        }
        if(address(_arbOwnerPublic) == address(0)) {
            if(block.chainid != LOCAL.CHAIN_ID) {
                _arbOwnerPublic = new ArbOwnerPublicStub();
                initPrecompiles_ArbOS();
            }
        }
        return _arbOwnerPublic;
    }
    
}