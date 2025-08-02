// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

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

import {betterconsole as console} from "../../utils/vm/foundry/tools/betterconsole.sol";
import {
    AddressSet,
    AddressSetRepo
} from "../../utils/collections/sets/AddressSetRepo.sol";
import { BetterScript } from "../../script/BetterScript.sol";
import {LOCAL} from "../../constants/networks/LOCAL.sol";
import {ETHEREUM_MAIN} from "../../constants/networks/ETHEREUM_MAIN.sol";
import {ETHEREUM_SEPOLIA} from "../../constants/networks/ETHEREUM_SEPOLIA.sol";
import {BetterIERC20 as IERC20} from "../../interfaces/BetterIERC20.sol";
import {IUniswapV2Factory} from "../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import { IUniswapV2Router } from "../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {IUniswapV2Pair} from "../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {UniV2Factory} from "../../protocols/dexes/uniswap/v2/UniV2Factory.sol";
import {UniV2Router02} from "../../protocols/dexes/uniswap/v2/UniV2Router02.sol";
import { Script_WETH } from "../../script/protocols/Script_WETH.sol";
import { ScriptBase_Crane_Factories } from "../../script/ScriptBase_Crane_Factories.sol";

contract Script_UniswapV2
is
    CommonBase,
    ScriptBase,

    StdChains,
    StdCheatsSafe,

    StdUtils,

    Script,
    BetterScript,

    ScriptBase_Crane_Factories,
    
    Script_WETH
{

    using AddressSetRepo for AddressSet;

    error UniswapV2FeeToNotDeclaredOnChain(uint256 chainId);

    function builderKey_UniswapV2() public pure returns (string memory) {
        return "uniswapV2";
    }

    function run() public virtual
    override(
        ScriptBase_Crane_Factories,
        Script_WETH
    ) {
        Script_WETH.run();
        // TODO Add uniswapV2Pairs to json of all.
        declare(vm.getLabel(address(uniswapV2FeeTo())), address(uniswapV2FeeTo()));
        declare(vm.getLabel(address(uniswapV2Router())), address(uniswapV2Router()));
        declare(vm.getLabel(address(uniswapV2Factory())), address(uniswapV2Factory()));
    }

    /* ---------------------------------------------------------------------- */
    /*                             Uniswap V2 Pair                            */
    /* ---------------------------------------------------------------------- */

    AddressSet _uniswapV2Pairs;

    function uniswapV2Pair(
        IERC20 tokenA,
        IERC20 tokenB
    ) public virtual returns(IUniswapV2Pair uniswapV2Pair_) {
        uniswapV2Pair_ = IUniswapV2Pair(uniswapV2Factory().getPair(address(tokenA), address(tokenB)));
        if (address(uniswapV2Pair_) == address(0)) {
            uniswapV2Pair_ = IUniswapV2Pair(uniswapV2Factory().createPair(address(tokenA), address(tokenB)));
            declare(builderKey_UniswapV2(), string.concat("UniswapV2 Pair ", tokenA.name(), " / ", tokenB.name()), address(uniswapV2Pair_));
        }
        _uniswapV2Pairs._add(address(uniswapV2Pair_));
        declare(builderKey_UniswapV2(), string.concat("UniswapV2 Pair ", tokenA.name(), " / ", tokenB.name()), address(uniswapV2Pair_));
        return uniswapV2Pair_;
    }

    /* ---------------------------------------------------------------------- */
    /*                            Uniswap V2 Fee To                           */
    /* ---------------------------------------------------------------------- */

    function uniswapV2FeeTo(uint256 chainId, address uniswapV2FeeTo_) public {
        registerInstance(chainId, IUniswapV2Factory.feeTo.selector, address(uniswapV2FeeTo_));
        declare(builderKey_UniswapV2(), "uniswapV2FeeTo", address(uniswapV2FeeTo_));
    }

    function uniswapV2FeeTo(address uniswapV2FeeTo_) public {
        uniswapV2FeeTo(block.chainid, uniswapV2FeeTo_);
    }

    function uniswapV2FeeTo(uint256 chainId) public view returns (address) {
        // return _uniswapV2FeeTo[chainId];
        return address(chainInstance(chainId, IUniswapV2Factory.feeTo.selector));
    }

    function uniswapV2FeeTo() public virtual returns (address) {
        if(uniswapV2FeeTo(block.chainid) == address(0)) {
            // if(block.chainid == ETHEREUM_MAIN.CHAIN_ID){
            //     uniswapV2FeeTo(uniswapV2Factory().feeTo());
            // }
            // else
            // if(block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
            //     uniswapV2FeeTo(uniswapV2Factory().feeTo());
            // } else
            // {
                revert UniswapV2FeeToNotDeclaredOnChain(block.chainid);
            // }
            // uniswapV2FeeTo(block.chainid, address(this));
            
        }
        return uniswapV2FeeTo(block.chainid);
    }

    /* ---------------------------------------------------------------------- */
    /*                           Uniswap V2 Factory                           */
    /* ---------------------------------------------------------------------- */

    function uniswapV2Factory(
        uint256 chainid,
        IUniswapV2Factory uniswapV2Factory_
    ) public virtual returns(bool) {
        // console.log("Fixture_UniswapV2:uniswapV2Factory(uint256,IUniswapV2Factory):: Entering function.");
        registerInstance(chainid, keccak256(type(UniV2Factory).creationCode), address(uniswapV2Factory_));
        declare(builderKey_UniswapV2(), "uniswapV2Factory", address(uniswapV2Factory_));
        // console.log("Fixture_UniswapV2:uniswapV2Factory(uint256,IUniswapV2Factory):: Exiting function.");
        return true;
    }

    function uniswapV2Factory(IUniswapV2Factory uniswapV2Factory_) public virtual returns(bool) {
        // console.log("Fixture_UniswapV2:uniswapV2Factory(IUniswapV2Factory):: Entering function.");
        uniswapV2Factory(block.chainid, uniswapV2Factory_);
        // console.log("Fixture_UniswapV2:uniswapV2Factory(IUniswapV2Factory):: Exiting function.");
        return true;
    }

    function uniswapV2Factory(uint256 chainid) public view returns(IUniswapV2Factory) {
        // console.log("Fixture_UniswapV2:uniswapV2Factory(uint256):: Entering function.");
        // console.log("Fixture_UniswapV2:uniswapV2Factory(uint256):: Exiting function.");
        return IUniswapV2Factory(chainInstance(chainid, keccak256(type(UniV2Factory).creationCode)));
    }

    function uniswapV2Factory(
        bytes memory initArgs
    ) public virtual returns(IUniswapV2Factory uniswapV2Factory_) {
        // console.log("Fixture_UniswapV2:uniswapV2Factory(bytes):: Entering function.");
        if(address(uniswapV2Factory(block.chainid)) == address(0)) {
            // console.log("Uniswap V2 Factory not set on this chain, setting");
            // console.log("Checking if this is Etherem Mainnet.");
            if(block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                // console.log("Ethereum Mainnet detected, setting Uniswap V2 Factory to ETHEREUM_MAIN.UNISWAP_V2_FACTORY");
                uniswapV2Factory_ = IUniswapV2Factory(ETHEREUM_MAIN.UNISWAP_V2_FACTORY);
            } else if(block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                // console.log("Ethereum Sepolia detected, setting Uniswap V2 Factory to ETHEREUM_SEPOLIA.UNISWAP_V2_FACTORY");
                uniswapV2Factory_ = IUniswapV2Factory(ETHEREUM_SEPOLIA.UNISWAP_V2_FACTORY);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                // console.log("Local detected, setting Uniswap V2 Factory to LOCAL.UNISWAP_V2_FACTORY");
                uniswapV2Factory_ = new UniV2Factory(abi.decode(initArgs, (address)));
            } else {
                revert("Uniswap V2 Factory not declared on this chain");
            }
            // console.log("Uniswap V2 Factory set to ", address(uniswapV2Factory_));
            // console.log("Declaring address of Uniswap V2 Factory.");
            uniswapV2Factory(block.chainid, uniswapV2Factory_);
        }
        // console.log("Fixture_UniswapV2:uniswapV2Factory(bytes):: Exiting function.");
        return uniswapV2Factory(block.chainid);
    }

    function uniswapV2Factory() public virtual returns(IUniswapV2Factory uniswapV2Factory_) {
        // console.log("Fixture_UniswapV2:uniswapV2Factory():: Entering function.");
        uniswapV2Factory_ = uniswapV2Factory(abi.encode(uniswapV2FeeTo()));
        // console.log("Fixture_UniswapV2:uniswapV2Factory():: Exiting function.");
        return uniswapV2Factory_;
    }

    /* ---------------------------------------------------------------------- */
    /*                            Uniswap V2 Router                           */
    /* ---------------------------------------------------------------------- */

    function uniswapV2Router(uint256 chainid, IUniswapV2Router uniswapV2Router_) public virtual returns(bool) {
        // console.log("Fixture_UniswapV2:uniswapV2Router(uint256,IUniswapV2Router02):: Entering function.");
        registerInstance(chainid, keccak256(type(UniV2Router02).creationCode), address(uniswapV2Router_));
        declare(builderKey_UniswapV2(), "uniswapV2Router", address(uniswapV2Router_));
        // console.log("Fixture_UniswapV2:uniswapV2Router(uint256,IUniswapV2Router02):: Exiting function.");
        return true;
    }

    function uniswapV2Router(IUniswapV2Router uniswapV2Router_) public virtual returns(bool) {
        // console.log("Fixture_UniswapV2:uniswapV2Router(IUniswapV2Router02):: Entering function.");
        uniswapV2Router(block.chainid, uniswapV2Router_);
        // console.log("Fixture_UniswapV2:uniswapV2Router(IUniswapV2Router02):: Exiting function.");
        return true;
    }

    function uniswapV2Router(uint256 chainid) public view returns(IUniswapV2Router) {
        // console.log("Fixture_UniswapV2:uniswapV2Router(uint256):: Entering function.");
        // console.log("Fixture_UniswapV2:uniswapV2Router(uint256):: Exiting function.");
        return IUniswapV2Router(chainInstance(chainid, keccak256(type(UniV2Router02).creationCode)));
    }

    function uniswapV2Router(
        IUniswapV2Factory uniswapV2Factory_,
        IWETH weth_
    ) public virtual returns(IUniswapV2Router uniswapV2Router_) {
        // console.log("Fixture_UniswapV2:uniswapV2Router(IUniswapV2Factory,IWETH):: Entering function.");
        if(address(uniswapV2Router(block.chainid)) == address(0)) {
            // console.log("Uniswap V2 Router not set on this chain, setting");
            // console.log("Checking if this is Etherem Mainnet.");
            if(block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                uniswapV2Router_ = IUniswapV2Router(ETHEREUM_MAIN.UNISWAP_V2_ROUTER);
            } else if(block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                uniswapV2Router_ = IUniswapV2Router(ETHEREUM_SEPOLIA.UNISWAP_V2_ROUTER);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                uniswapV2Router_ = IUniswapV2Router(address(new UniV2Router02(address(uniswapV2Factory_), address(weth_))));
            } else {
                revert("Uniswap V2 Router not declared on this chain");
            }
            // console.log("Uniswap V2 Router set to ", address(uniswapV2Router_));
            // console.log("Declaring address of Uniswap V2 Router.");
            uniswapV2Router(block.chainid, uniswapV2Router_);
        }
        // console.log("Fixture_UniswapV2:uniswapV2Router(IUniswapV2Factory,IWETH):: Exiting function.");
        return uniswapV2Router(block.chainid);
    }

    function uniswapV2Router() public virtual returns (IUniswapV2Router uniswapV2Router_) {
        // console.log("Fixture_UniswapV2:uniswapV2Router():: Entering function.");
        // console.log("Fixture_UniswapV2:uniswapV2Router():: Exiting function.");
        return uniswapV2Router(uniswapV2Factory(), weth9());
    }
    
}