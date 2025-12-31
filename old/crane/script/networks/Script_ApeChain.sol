// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase, TestBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe, StdCheats} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {Script_ArbOS} from "contracts/crane/script/networks/Script_ArbOS.sol";
import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
import {APE_CHAIN_MAIN} from "contracts/crane/constants/networks/APE_CHAIN_MAIN.sol";
import {APE_CHAIN_CURTIS} from "contracts/crane/constants/networks/APE_CHAIN_CURTIS.sol";
import {WAPE} from "contracts/crane/protocols/tokens/wrappers/wape/WAPE.sol";

abstract contract Script_ApeChain is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript,
    Script_ArbOS
{
    function builderKey_ApeChain() public pure returns (string memory) {
        return "apeChain";
    }

    /* ---------------------------------------------------------------------- */
    /*                                  WAPE                                  */
    /* ---------------------------------------------------------------------- */

    function wape(uint256 chainid, IWETH wape_) public returns (bool) {
        registerInstance(chainid, keccak256(type(WAPE).creationCode), address(wape_));
        declare(builderKey_ApeChain(), "wape", address(wape_));
        return true;
    }

    function wape(IWETH wape_) public returns (bool) {
        wape(block.chainid, wape_);
        declare(builderKey_ApeChain(), "wape", address(wape_));
        return true;
    }

    function wape(uint256 chainid) public view virtual returns (IWETH wape_) {
        wape_ = IWETH(chainInstance(chainid, keccak256(abi.encode(wape_))));
    }

    function wape() public virtual returns (IWETH wape_) {
        if (address(wape(block.chainid)) == address(0)) {
            if (isAnyTest()) {
                arbOwnerPublic();
            }
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                wape_ = IWETH(APE_CHAIN_MAIN.WAPE);
            } else if (block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                wape_ = IWETH(APE_CHAIN_CURTIS.WAPE);
            } else if (block.chainid == LOCAL.CHAIN_ID) {
                wape_ = new WAPE();
            }
            wape(wape_);
        }
        return wape(block.chainid);
    }
}
