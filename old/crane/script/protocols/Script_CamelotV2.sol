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
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterScript} from "contracts/crane/script/BetterScript.sol";
import {Script_WETH} from "contracts/crane/script/protocols/Script_WETH.sol";
import {Script_ArbOS} from "contracts/crane/script/networks/Script_ArbOS.sol";
import {Script_ApeChain} from "contracts/crane/script/networks/Script_ApeChain.sol";

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {APE_CHAIN_MAIN} from "contracts/crane/constants/networks/APE_CHAIN_MAIN.sol";
import {APE_CHAIN_CURTIS} from "contracts/crane/constants/networks/APE_CHAIN_CURTIS.sol";
import {LOCAL} from "contracts/crane/constants/networks/LOCAL.sol";
import {CamelotFactory} from "contracts/crane/protocols/dexes/camelot/v2/CamelotFactory.sol";
import {CamelotRouter} from "contracts/crane/protocols/dexes/camelot/v2/CamelotRouter.sol";
import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {ScriptBase_Crane_Factories} from "contracts/crane/script/ScriptBase_Crane_Factories.sol";

abstract contract Script_CamelotV2 is
    CommonBase,
    ScriptBase,
    StdChains,
    StdCheatsSafe,
    StdUtils,
    Script,
    BetterScript,
    ScriptBase_Crane_Factories,
    Script_WETH,
    Script_ArbOS,
    Script_ApeChain
{
    function builderKey_CamV2() public pure returns (string memory) {
        return "camelotV2";
    }

    function run() public virtual override(ScriptBase_Crane_Factories, Script_WETH) {
        declare(vm.getLabel(address(camV2Factory())), address(camV2Factory()));
        declare(vm.getLabel(address(camV2Router())), address(camV2Router()));
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

    function camelotV2FeeTo() public virtual returns (address) {
        if (_camelotV2FeeTo[block.chainid] == address(0)) {
            camelotV2FeeTo(block.chainid, address(this));
        }
        return camelotV2FeeTo(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                              ICamelotPair                              */
    /* ---------------------------------------------------------------------- */

    function camelotV2Pair(IERC20 tokenA, IERC20 tokenB) public virtual returns (ICamelotPair camelotV2Pair_) {
        camelotV2Pair_ = ICamelotPair(camV2Factory().createPair(address(tokenA), address(tokenB)));
        if (address(camelotV2Pair_) == address(0)) {
            camelotV2Pair_ = ICamelotPair(camV2Factory().createPair(address(tokenA), address(tokenB)));
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                             ICamelotFactory                            */
    /* ---------------------------------------------------------------------- */

    function camV2Factory(uint256 chainid, ICamelotFactory camV2Factory_) public virtual returns (bool) {
        registerInstance(chainid, keccak256(type(CamelotFactory).creationCode), address(camV2Factory_));
        declare(builderKey_CamV2(), "camV2Factory", address(camV2Factory_));
        return true;
    }

    function camV2Factory(ICamelotFactory camV2Factory_) public virtual returns (bool) {
        camV2Factory(block.chainid, camV2Factory_);
        return true;
    }

    function camV2Factory(uint256 chainid) public view returns (ICamelotFactory) {
        return ICamelotFactory(chainInstance(chainid, keccak256(type(CamelotFactory).creationCode)));
    }

    /**
     * @notice camV2Factory_ Returns the Camelot V2 factory for the current chain.
     */
    // TODO Add deployment if no address is declared for a chain.
    function camV2Factory() public virtual returns (ICamelotFactory camV2Factory_) {
        if (address(camV2Factory(block.chainid)) == address(0)) {
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                camV2Factory_ = ICamelotFactory(APE_CHAIN_MAIN.CAMELOT_FACTORY_V2);
            } else if (block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                camV2Factory_ = ICamelotFactory(APE_CHAIN_CURTIS.CAMELOT_FACTORY_V2);
            } else if (block.chainid == LOCAL.CHAIN_ID) {
                camV2Factory_ = new CamelotFactory(camelotV2FeeTo());
            } else {
                revert("Camelot V2 Factory not declared on this chain");
            }
            camV2Factory(block.chainid, camV2Factory_);
        }
        return camV2Factory(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                            ICamelotV2Router                            */
    /* ---------------------------------------------------------------------- */

    function camV2Router(uint256 chainid, ICamelotV2Router camV2Router_) public virtual returns (bool) {
        registerInstance(chainid, keccak256(type(CamelotRouter).creationCode), address(camV2Router_));
        declare(builderKey_CamV2(), "camV2Router", address(camV2Router_));
        return true;
    }

    function camV2Router(ICamelotV2Router camV2Router_) public virtual returns (bool) {
        camV2Router(block.chainid, camV2Router_);
        return true;
    }

    function camV2Router(uint256 chainid) public view returns (ICamelotV2Router) {
        return ICamelotV2Router(chainInstance(chainid, keccak256(type(CamelotRouter).creationCode)));
    }

    /**
     * @notice camV2Router_ Returns the Camelot V2 router for the current chain.
     */
    // TODO Add deployment if no address is declared for a chain.
    function camV2Router() public virtual returns (ICamelotV2Router camV2Router_) {
        if (address(camV2Router(block.chainid)) == address(0)) {
            if (block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                camV2Router_ = ICamelotV2Router(APE_CHAIN_MAIN.CAMELOT_ROUTER_V2);
            } else if (block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                camV2Router_ = ICamelotV2Router(APE_CHAIN_CURTIS.CAMELOT_ROUTER_V2);
            } else if (block.chainid == LOCAL.CHAIN_ID) {
                camV2Router_ = new CamelotRouter(address(camV2Factory()), address(weth9()));
            } else {
                revert("Camelot V2 Router not deployed on this chain");
            }
            camV2Router(block.chainid, camV2Router_);
        }
        return camV2Router(block.chainid);
    }
}
