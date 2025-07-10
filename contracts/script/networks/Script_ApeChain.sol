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
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { BetterScript } from "../../script/BetterScript.sol";
import { Script_ArbOS } from "../../script/networks/Script_ArbOS.sol";
import { LOCAL } from "../../constants/networks/LOCAL.sol";
import { APE_CHAIN_MAIN } from "../../constants/networks/APE_CHAIN_MAIN.sol";
import { APE_CHAIN_CURTIS } from "../../constants/networks/APE_CHAIN_CURTIS.sol";
import { WAPE } from "../../protocols/tokens/wrappers/wape/WAPE.sol";

contract Script_ApeChain
is
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

    function wape(
        uint256 chainid,
        IWETH wape_
    ) public returns(bool) {
        registerInstance(chainid, keccak256(type(WAPE).creationCode), address(wape_));
        declare(builderKey_ApeChain(), "wape", address(wape_));
        return true;
    }

    function wape(IWETH wape_) public returns(bool) {
        // _log("Fixture_ApeChain::wape(IWETH wape_):: Entering function");
        // _log("Fixture_ApeChain::wape(IWETH wape_):: Setting provided wape of %s", address(wape_));
        wape(block.chainid, wape_);
        // _log("Fixture_ApeChain::wape(IWETH wape_):: Declaring address of wape");
        declare(builderKey_ApeChain(), "wape", address(wape_));
        // _log("Fixture_ApeChain::wape(IWETH wape_):: Declared address of wape");
        // _log("Fixture_ApeChain::wape(IWETH wape_):: Exiting function");
        return true;
    }

    function wape(uint256 chainid)
    public virtual view returns(IWETH wape_) {
        wape_ = IWETH(chainInstance(chainid, keccak256(abi.encode(wape_))));
    }

    function wape()
    public virtual
    returns(IWETH wape_) {
        // _log("Fixture_ApeChain::wape():: Entering function");
        // _log("Fixture_ApeChain::wape():: Checking if wape is declared");
        if(address(wape(block.chainid)) == address(0)) {
            // _log("Fixture_ApeChain::wape():: WAPE is not declared, deploying.");
            // _log("Fixture_ApeChain::wape():: Checking if this is a test");
            if(isAnyTest()) {
                // _log("Fixture_ApeChain::wape():: This is a test, initializing precompiles");
                arbOwnerPublic();
                // _log("Fixture_ApeChain::wape():: Precompiles initialized");
            }
            // _log("Fixture_ApeChain::wape():: Deploying wape");
            if(block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                wape_ = IWETH(APE_CHAIN_MAIN.WAPE);
            } else if(block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                wape_ = IWETH(APE_CHAIN_CURTIS.WAPE);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                wape_ = new WAPE();
            }
            // _log("Fixture_ApeChain::wape():: Deployed wape");
            wape(wape_);
        }
        // _log("Fixture_ApeChain::wape():: Returning value from storage presuming it would have been set based on chain state.");
        // _log("Fixture_ApeChain::wape():: Exiting function");
        return wape(block.chainid);
    }

}