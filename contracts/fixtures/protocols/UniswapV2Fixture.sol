// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "../../utils/vm/foundry/tools/betterconsole.sol";
import {Fixture} from "../Fixture.sol";
import {LOCAL} from "../../constants/networks/LOCAL.sol";
import {ETHEREUM_MAIN} from "../../constants/networks/ETHEREUM_MAIN.sol";
import {ETHEREUM_SEPOLIA} from "../../constants/networks/ETHEREUM_SEPOLIA.sol";
import {BetterIERC20 as IERC20} from "../../interfaces/BetterIERC20.sol";
import {IUniswapV2Factory} from "../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Router02} from "../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {UniV2Factory} from "../../protocols/dexes/uniswap/v2/UniV2Factory.sol";
import {UniV2Router02} from "../../protocols/dexes/uniswap/v2/UniV2Router02.sol";
import {WETH9Fixture} from "./WETH9Fixture.sol";

contract UniswapV2Fixture is WETH9Fixture {

    function builderKey_UniV2() public pure returns (string memory) {
        return "uniswapV2";
    }

    address _uniswapV2FeeTo;

    function uniswapV2FeeTo(address uniswapV2FeeTo_) public {
        _uniswapV2FeeTo = uniswapV2FeeTo_;
    }

    function uniswapV2FeeTo() public view returns (address) {
        if(_uniswapV2FeeTo == address(0)) {
            return address(this);
        }
        return _uniswapV2FeeTo;
    }

    function initialize()
    public virtual
    override(
        WETH9Fixture
    ) {
        WETH9Fixture.initialize();
    }

    /* ---------------------------------------------------------------------- */
    /*                           Uniswap V2 Factory                           */
    /* ---------------------------------------------------------------------- */

    function uniswapV2Factory(
        uint256 chainid,
        IUniswapV2Factory uniswapV2Factory_
    ) public returns(bool) {
        console.log("UniswapV2Fixture:uniswapV2Factory():: Entering function.");
        registerInstance(chainid, keccak256(type(UniV2Factory).creationCode), address(uniswapV2Factory_));
        declare(builderKey_UniV2(), "uniswapV2Factory", address(uniswapV2Factory_));
        console.log("UniswapV2Fixture:uniswapV2Factory():: Exiting function.");
    }

    function uniswapV2Factory(IUniswapV2Factory uniswapV2Factory_) public returns(bool) {
        console.log("UniswapV2Fixture:uniswapV2Factory():: Entering function.");
        uniswapV2Factory(block.chainid, uniswapV2Factory_);
        console.log("UniswapV2Fixture:uniswapV2Factory():: Exiting function.");
        return true;
    }

    function uniswapV2Factory(uint256 chainid) public view returns(IUniswapV2Factory) {
        console.log("UniswapV2Fixture:uniswapV2Factory():: Entering function.");
        console.log("UniswapV2Fixture:uniswapV2Factory():: Exiting function.");
        return IUniswapV2Factory(chainInstance(chainid, keccak256(type(UniV2Factory).creationCode)));
    }

    function uniswapV2Factory(
        bytes memory initArgs
    ) public returns(IUniswapV2Factory uniswapV2Factory_) {
        if(address(uniswapV2Factory(block.chainid)) == address(0)) {
            console.log("Uniswap V2 Factory not set on this chain, setting");
            console.log("Checking if this is Etherem Mainnet.");
            if(block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                console.log("Ethereum Mainnet detected, setting Uniswap V2 Factory to ETHEREUM_MAIN.UNISWAP_V2_FACTORY");
                uniswapV2Factory_ = IUniswapV2Factory(ETHEREUM_MAIN.UNISWAP_V2_FACTORY);
            } else if(block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                console.log("Ethereum Sepolia detected, setting Uniswap V2 Factory to ETHEREUM_SEPOLIA.UNISWAP_V2_FACTORY");
                uniswapV2Factory_ = IUniswapV2Factory(ETHEREUM_SEPOLIA.UNISWAP_V2_FACTORY);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                console.log("Local detected, setting Uniswap V2 Factory to LOCAL.UNISWAP_V2_FACTORY");
                uniswapV2Factory_ = new UniV2Factory(abi.decode(initArgs, (address)));
            } else {
                revert("Uniswap V2 Factory not declared on this chain");
            }
            console.log("Uniswap V2 Factory set to ", address(uniswapV2Factory_));
            console.log("Declaring address of Uniswap V2 Factory.");
            uniswapV2Factory(block.chainid, uniswapV2Factory_);
        }
        return uniswapV2Factory(block.chainid);
    }

    function uniswapV2Factory() public returns(IUniswapV2Factory uniswapV2Factory_) {
        console.log("UniswapV2Fixture:uniswapV2Factory():: Entering function.");
        uniswapV2Factory_ = uniswapV2Factory(abi.encode(uniswapV2FeeTo()));
        console.log("UniswapV2Fixture:uniswapV2Factory():: Exiting function.");
        return uniswapV2Factory_;
    }

    /* ---------------------------------------------------------------------- */
    /*                            Uniswap V2 Router                           */
    /* ---------------------------------------------------------------------- */

    function uniswapV2Router(uint256 chainid, IUniswapV2Router02 uniswapV2Router_) public returns(bool) {
        console.log("UniswapV2Fixture:uniswapV2Router():: Entering function.");
        registerInstance(chainid, keccak256(type(UniV2Router02).creationCode), address(uniswapV2Router_));
        declare(builderKey_UniV2(), "uniswapV2Router", address(uniswapV2Router_));
        console.log("UniswapV2Fixture:uniswapV2Router():: Exiting function.");
        return true;
    }

    function uniswapV2Router(IUniswapV2Router02 uniswapV2Router_) public returns(bool) {
        console.log("UniswapV2Fixture:uniswapV2Router():: Entering function.");
        uniswapV2Router(block.chainid, uniswapV2Router_);
        console.log("UniswapV2Fixture:uniswapV2Router():: Exiting function.");
        return true;
    }

    function uniswapV2Router(uint256 chainid) public view returns(IUniswapV2Router02) {
        console.log("UniswapV2Fixture:uniswapV2Router():: Entering function.");
        console.log("UniswapV2Fixture:uniswapV2Router():: Exiting function.");
        return IUniswapV2Router02(chainInstance(chainid, keccak256(type(UniV2Router02).creationCode)));
    }

    function uniswapV2Router(
        IUniswapV2Factory uniswapV2Factory_,
        IWETH weth_
    ) public returns(IUniswapV2Router02 uniswapV2Router_) {
        if(address(uniswapV2Router(block.chainid)) == address(0)) {
            console.log("Uniswap V2 Router not set on this chain, setting");
            console.log("Checking if this is Etherem Mainnet.");
            if(block.chainid == ETHEREUM_MAIN.CHAIN_ID) {
                uniswapV2Router_ = IUniswapV2Router02(ETHEREUM_MAIN.UNISWAP_V2_ROUTER);
            } else if(block.chainid == ETHEREUM_SEPOLIA.CHAIN_ID) {
                uniswapV2Router_ = IUniswapV2Router02(ETHEREUM_SEPOLIA.UNISWAP_V2_ROUTER);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                uniswapV2Router_ = new UniV2Router02(address(uniswapV2Factory_), address(weth_));
            } else {
                revert("Uniswap V2 Router not declared on this chain");
            }
        }
    }

    function uniswapV2Router() public returns (IUniswapV2Router02 uniswapV2Router_) {
        return uniswapV2Router(uniswapV2Factory(), weth9());
    }

    function uniswapV2Pair(
        IERC20 tokenA,
        IERC20 tokenB
    ) public returns(IUniswapV2Pair uniswapV2Pair_) {
        uniswapV2Pair_ = IUniswapV2Pair(uniswapV2Factory().getPair(address(tokenA), address(tokenB)));
        if (address(uniswapV2Pair_) == address(0)) {
            uniswapV2Pair_ = IUniswapV2Pair(uniswapV2Factory().createPair(address(tokenA), address(tokenB)));
        }
    }

}