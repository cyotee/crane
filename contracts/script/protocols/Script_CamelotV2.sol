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
import { Script_WETH } from "./Script_WETH.sol";
import { Script_ArbOS } from "../networks/Script_ArbOS.sol";
import { Script_ApeChain } from "../networks/Script_ApeChain.sol";

import { betterconsole as console } from "../../utils/vm/foundry/tools/betterconsole.sol";
import { APE_CHAIN_MAIN } from "../../constants/networks/APE_CHAIN_MAIN.sol";
import { APE_CHAIN_CURTIS } from "../../constants/networks/APE_CHAIN_CURTIS.sol";
import { LOCAL } from "../../constants/networks/LOCAL.sol";
import { CamelotFactory } from "../../protocols/dexes/camelot/v2/CamelotFactory.sol";
import { CamelotRouter } from "../../protocols/dexes/camelot/v2/CamelotRouter.sol";
import { ICamelotFactory } from "../../interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import { ICamelotV2Router } from "../../interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import { ICamelotPair } from "../../interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import { BetterIERC20 as IERC20 } from "../../interfaces/BetterIERC20.sol";

contract Script_CamelotV2
is
    // CommonBase,
    // ScriptBase,
    // StdChains,
    // StdCheatsSafe,
    // StdUtils,
    // Script,
    // BetterScript,
    Script_WETH,
    // Script_ArbOS,
    Script_ApeChain
{


    function builderKey_CamV2() public pure returns (string memory) {
        return "camelotV2";
    }

    function run()
    public virtual override {
        // console..log("Fixture_CamelotV2:setUp():: Entering function.");
        // console..log("Declaring addresses of Camelot V2 Factory and Router in json of all.");
        // console..log("Declaring Camelot V2 Factory.");
        declare(vm.getLabel(address(camV2Factory())), address(camV2Factory()));
        // console..log("Camelot V2 Factory declared.");
        // console..log("Declaring Camelot V2 Router.");
        declare(vm.getLabel(address(camV2Router())), address(camV2Router()));
        // console..log("Camelot V2 Router declared.");
        // console..log("Fixture_CamelotV2:setUp():: Exiting function.");
    }

    mapping(uint256 chainid => address camelotV2FeeTo) _camelotV2FeeTo;

    function camelotV2FeeTo(uint256 chainid, address camelotV2FeeTo_) public {
        _camelotV2FeeTo[chainid] = camelotV2FeeTo_;
    }

    function camelotV2FeeTo(address camelotV2FeeTo_) public {
        camelotV2FeeTo(block.chainid, camelotV2FeeTo_);
    }

    function camelotV2FeeTo(uint256 chainid) public view returns (address) {
        return _camelotV2FeeTo[chainid];
    }

    function camelotV2FeeTo() public returns (address) {
        if(_camelotV2FeeTo[block.chainid] == address(0)) {
            camelotV2FeeTo(block.chainid, address(this));
        }
        return camelotV2FeeTo(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                              ICamelotPair                              */
    /* ---------------------------------------------------------------------- */

    function camelotV2Pair(
        IERC20 tokenA,
        IERC20 tokenB
    ) public returns(ICamelotPair camelotV2Pair_) {
        camelotV2Pair_ = ICamelotPair(camV2Factory().createPair(address(tokenA), address(tokenB)));
        if(address(camelotV2Pair_) == address(0)) {
            camelotV2Pair_ = ICamelotPair(camV2Factory().createPair(address(tokenA), address(tokenB)));
        }
    }
    
    /* ---------------------------------------------------------------------- */
    /*                             ICamelotFactory                            */
    /* ---------------------------------------------------------------------- */

    function camV2Factory(
        uint256 chainid,
        ICamelotFactory camV2Factory_
    ) public returns(bool) {
        // console..log("Fixture_CamelotV2:camV2Factory(uint256,ICamelotFactory):: Entering function.");
        registerInstance(chainid, keccak256(type(CamelotFactory).creationCode), address(camV2Factory_));
        declare(builderKey_CamV2(), "camV2Factory", address(camV2Factory_));
        // console..log("Fixture_CamelotV2:camV2Factory(uint256,ICamelotFactory):: Exiting function.");
        return true;
    }

    function camV2Factory(ICamelotFactory camV2Factory_) public returns(bool) {
        // console..log("Fixture_CamelotV2:camV2Factory(ICamelotFactory):: Entering function.");
        camV2Factory(block.chainid, camV2Factory_);
        // console..log("Fixture_CamelotV2:camV2Factory(ICamelotFactory):: Exiting function.");
        return true;
    }

    function camV2Factory(uint256 chainid) public view returns(ICamelotFactory) {
        // console..log("Fixture_CamelotV2:camV2Factory(uint256):: Entering function.");
        // console..log("Fixture_CamelotV2:camV2Factory(uint256):: Exiting function.");
        return ICamelotFactory(chainInstance(chainid, keccak256(type(CamelotFactory).creationCode)));
    }

    /**
     * @notice camV2Factory_ Returns the Camelot V2 factory for the current chain.
     */
    // TODO Add deployment if no address is declared for a chain.
    function camV2Factory() public returns (ICamelotFactory camV2Factory_) {
        // console..log("Fixture_CamelotV2:camV2Factory():: Entering function.");
        // console..log("Checking if address is declared for this chain.");
        if(address(camV2Factory(block.chainid)) == address(0)) {
            // console..log("Camelot V2 Factory not set on this chain, setting");
            // console..log("Checking if this is ApeChain Mainnet or Curtis Testnet.");
            if(block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                // console..log("ApeChain Mainnet detected, setting Camelot V2 Factory to APE_CHAIN_MAIN.CAMELOT_FACTORY_V2");
                camV2Factory_ = ICamelotFactory(APE_CHAIN_MAIN.CAMELOT_FACTORY_V2);
            } else if(block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                // console..log("ApeChain Curtis detected, setting Camelot V2 Factory to APE_CHAIN_CURTIS.CAMELOT_FACTORY_V2");
                camV2Factory_ = ICamelotFactory(APE_CHAIN_CURTIS.CAMELOT_FACTORY_V2);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                camV2Factory_ = new CamelotFactory(camelotV2FeeTo());
            } else {
                revert("Camelot V2 Factory not declared on this chain");
            }
            // console..log("ICamelotFactory set to ", address(camV2Factory_));
            // console..log("Declaring address of Camelot V2 Factory.");
            camV2Factory(block.chainid, camV2Factory_);
            // console..log("Camelot V2 Factory declared.");
        }
        // console..log("Fixture_CamelotV2:camV2Factory():: Exiting function.");
        return camV2Factory(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                            ICamelotV2Router                            */
    /* ---------------------------------------------------------------------- */

    function camV2Router(
        uint256 chainid,
        ICamelotV2Router camV2Router_
    ) public returns(bool) {
        // console..log("Fixture_CamelotV2:camV2Router(uint256,ICamelotV2Router):: Entering function.");
        registerInstance(chainid, keccak256(type(CamelotRouter).creationCode), address(camV2Router_));
        declare(builderKey_CamV2(), "camV2Router", address(camV2Router_));
        // console..log("Fixture_CamelotV2:camV2Router(uint256,ICamelotV2Router):: Exiting function.");
        return true;
    }

    function camV2Router(ICamelotV2Router camV2Router_) public returns(bool) {
        // console..log("Fixture_CamelotV2:camV2Router(ICamelotV2Router):: Entering function.");
        camV2Router(block.chainid, camV2Router_);
        // console..log("Fixture_CamelotV2:camV2Router(ICamelotV2Router):: Exiting function.");
        return true;
    }

    function camV2Router(uint256 chainid) public view returns(ICamelotV2Router) {
        // console..log("Fixture_CamelotV2:camV2Router(uint256):: Entering function.");
        // console..log("Fixture_CamelotV2:camV2Router(uint256):: Exiting function.");
        return ICamelotV2Router(chainInstance(chainid, keccak256(type(CamelotRouter).creationCode)));
    }

    /**
     * @notice camV2Router_ Returns the Camelot V2 router for the current chain.
     */
    // TODO Add deployment if no address is declared for a chain.
    function camV2Router() public returns (ICamelotV2Router camV2Router_) {
        // console..log("Fixture_CamelotV2:camV2Router():: Entering function.");
        // console..log("Checking if address is declared for this chain.");
        if(address(camV2Router(block.chainid)) == address(0)) {
            // console..log("Camelot V2 Router not set on this chain, setting");
            // console..log("Checking if this is ApeChain Mainnet or Curtis Testnet.");
            if(block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                // console..log("ApeChain Mainnet detected, setting Camelot V2 Router to APE_CHAIN_MAIN.CAMELOT_ROUTER_V2");
                camV2Router_ = ICamelotV2Router(APE_CHAIN_MAIN.CAMELOT_ROUTER_V2);
            } else if(block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                // console..log("ApeChain Curtis detected, setting Camelot V2 Router to APE_CHAIN_CURTIS.CAMELOT_ROUTER_V2");
                camV2Router_ = ICamelotV2Router(APE_CHAIN_CURTIS.CAMELOT_ROUTER_V2);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                camV2Router_ = new CamelotRouter(address(camV2Factory()), address(weth9()));
            } else {
                revert("Camelot V2 Router not deployed on this chain");
            }
            // console..log("Declaring address of Camelot V2 Router.");
            camV2Router(block.chainid, camV2Router_);
            // console..log("Camelot V2 Router declared.");
        }
        // console..log("Fixture_CamelotV2:camV2Router():: Exiting function.");
        return camV2Router(block.chainid);
    }

}