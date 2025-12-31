// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import {CommonBase, ScriptBase} from 
// TestBase
"forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheatsSafe} from 
// StdCheats
"forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Script} from "forge-std/Script.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "contracts/crane/constants/CraneINITCODE.sol";
// import { betterconsole as console } from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {ETHEREUM_MAIN} from "contracts/crane/constants/networks/ETHEREUM_MAIN.sol";
import {ETHEREUM_SEPOLIA} from "contracts/crane/constants/networks/ETHEREUM_SEPOLIA.sol";
import {WETH9} from "contracts/crane/protocols/tokens/wrappers/weth/v9/WETH9.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";

abstract contract Script_WETH is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories
{
    /// forge-lint: disable-next-line(mixed-case-function)
    function builderKey_WETH9() public pure returns (string memory) {
        return "weth9";
    }

    function run() public virtual override(ScriptBase_Crane_Factories) {
        declare(vm.getLabel(address(weth9())), address(weth9()));
    }

    function weth9(uint256 chainid, IWETH weth9_) public virtual returns (bool) {
        registerInstance(chainid, keccak256(type(WETH9).creationCode), address(weth9_));
        declare(builderKey_WETH9(), "weth9", address(weth9_));
        return true;
    }

    function weth9(IWETH weth9_) public virtual returns (bool) {
        weth9(block.chainid, weth9_);
        return true;
    }

    function weth9(uint256 chainid) public view virtual returns (IWETH weth9_) {
        weth9_ = IWETH(chainInstance(chainid, keccak256(type(WETH9).creationCode)));
    }

    function weth9() public virtual returns (IWETH weth9_) {
        if (address(weth9(block.chainid)) == address(0)) {
            if (block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                weth9_ = IWETH(ETHEREUM_MAIN.WETH9);
            } else if (block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                weth9_ = IWETH(ETHEREUM_SEPOLIA.WETH9);
            } else {
                weth9_ = new WETH9();
            }
            weth9(block.chainid, weth9_);
        }
        return weth9(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                             WETHAwareFacet                             */
    /* ---------------------------------------------------------------------- */

    function wethAwareFacet(uint256 chainId, WETHAwareFacet wethAwareFacet_) public virtual returns (bool) {
        registerInstance(chainId, WETH_AWARE_FACET_INITCODE_HASH, address(wethAwareFacet_));
        declare(builderKey_WETH9(), "wethAwareFacet", address(wethAwareFacet_));
        return true;
    }

    function wethAwareFacet(WETHAwareFacet wethAwareFacet_) public virtual returns (bool) {
        wethAwareFacet(block.chainid, wethAwareFacet_);
        return true;
    }

    function wethAwareFacet(uint256 chainId) public view returns (WETHAwareFacet wethAwareFacet_) {
        wethAwareFacet_ = WETHAwareFacet(chainInstance(chainId, WETH_AWARE_FACET_INITCODE_HASH));
    }

    function wethAwareFacet() public virtual returns (WETHAwareFacet wethAwareFacet_) {
        if (address(wethAwareFacet(block.chainid)) == address(0)) {
            wethAwareFacet_ = WETHAwareFacet(
                factory()
                    .create3(
                        WETH_AWARE_FACET_INITCODE,
                        "",
                        WETH_AWARE_FACET_SALT
                    )
            );
            wethAwareFacet(block.chainid, wethAwareFacet_);
        }
        return wethAwareFacet(block.chainid);
    }
}
