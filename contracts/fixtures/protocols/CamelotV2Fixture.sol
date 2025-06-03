// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "../../utils/vm/foundry/tools/betterconsole.sol";
import {Fixture} from "../Fixture.sol";
import {ICamelotFactory} from "../../interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotPair} from "../../interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "../../interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {LOCAL} from "../../constants/networks/LOCAL.sol";
import {APE_CHAIN_MAIN} from "../../constants/networks/APE_CHAIN_MAIN.sol";
import {APE_CHAIN_CURTIS} from "../../constants/networks/APE_CHAIN_CURTIS.sol";
import {WETH9Fixture} from "./WETH9Fixture.sol";
import {ApeChainFixture} from "../networks/ApeChainFixture.sol";
import {CamelotFactory} from "../../protocols/dexes/camelot/v2/CamelotFactory.sol";
import {CamelotRouter} from "../../protocols/dexes/camelot/v2/CamelotRouter.sol";

/**
 * @title Camelot V2 Fixture
 * @notice Fixture for the Camelot V2 protocol.
 * @notice Determines which address to use for a discovered chain.
 */
// TODO Port Camelot V2 pools intto this repo, add deployment to this fixture when no address is declared for a chain.
contract CamelotV2Fixture
is
WETH9Fixture,
ApeChainFixture
{

    function builderKey_CamV2() public pure returns (string memory) {
        return "camelotV2";
    }

    address _camelotV2FeeTo;

    function camelotV2FeeTo(address camelotV2FeeTo_) public {
        _camelotV2FeeTo = camelotV2FeeTo_;
    }

    function camelotV2FeeTo() public view returns (address) {
        if(_camelotV2FeeTo == address(0)) {
            return address(this);
        }
        return _camelotV2FeeTo;
    }

    function initialize()
    public virtual
    override(
        WETH9Fixture,
        ApeChainFixture
    ) {
        WETH9Fixture.initialize();
        ApeChainFixture.initialize();
        console.log("CamelotV2Fixture:setUp():: Entering function.");
        console.log("Declaring addresses of Camelot V2 Factory and Router in json of all.");
        console.log("Declaring Camelot V2 Factory.");
        declare(vm.getLabel(address(camV2Factory())), address(camV2Factory()));
        console.log("Camelot V2 Factory declared.");
        console.log("Declaring Camelot V2 Router.");
        declare(vm.getLabel(address(camV2Router())), address(camV2Router()));
        console.log("Camelot V2 Router declared.");
        console.log("CamelotV2Fixture:setUp():: Exiting function.");
    }

    /* ---------------------------------------------------------------------- */
    /*                                External                                */
    /* ---------------------------------------------------------------------- */

    /* ----------------------------- Camelot V2 ----------------------------- */

    // ICamelotFactory internal _camV2Factory;

    function camV2Factory(
        uint256 chainid,
        ICamelotFactory camV2Factory_
    ) public returns(bool) {
        console.log("CamelotV2Fixture:camV2Factory():: Entering function.");
        registerInstance(chainid, keccak256(type(CamelotFactory).creationCode), address(camV2Factory_));
        declare(builderKey_CamV2(), "camV2Factory", address(camV2Factory_));
        console.log("CamelotV2Fixture:camV2Factory():: Exiting function.");
        return true;
    }

    function camV2Factory(ICamelotFactory camV2Factory_) public returns(bool) {
        console.log("CamelotV2Fixture:camV2Factory():: Entering function.");
        camV2Factory(block.chainid, camV2Factory_);
        console.log("CamelotV2Fixture:camV2Factory():: Exiting function.");
        return true;
    }

    function camV2Factory(uint256 chainid) public view returns(ICamelotFactory) {
        console.log("CamelotV2Fixture:camV2Factory():: Entering function.");
        console.log("CamelotV2Fixture:camV2Factory():: Exiting function.");
        return ICamelotFactory(chainInstance(chainid, keccak256(type(CamelotFactory).creationCode)));
    }

    /**
     * @notice camV2Factory_ Returns the Camelot V2 factory for the current chain.
     */
    // TODO Add deployment if no address is declared for a chain.
    function camV2Factory() public returns (ICamelotFactory camV2Factory_) {
        console.log("CamelotV2Fixture:camV2Factory():: Entering function.");
        console.log("Checking if address is declared for this chain.");
        if(address(camV2Factory(block.chainid)) == address(0)) {
            console.log("Camelot V2 Factory not set on this chain, setting");
            console.log("Checking if this is ApeChain Mainnet or Curtis Testnet.");
            if(block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                console.log("ApeChain Mainnet detected, setting Camelot V2 Factory to APE_CHAIN_MAIN.CAMELOT_FACTORY_V2");
                camV2Factory_ = ICamelotFactory(APE_CHAIN_MAIN.CAMELOT_FACTORY_V2);
            } else if(block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                console.log("ApeChain Curtis detected, setting Camelot V2 Factory to APE_CHAIN_CURTIS.CAMELOT_FACTORY_V2");
                camV2Factory_ = ICamelotFactory(APE_CHAIN_CURTIS.CAMELOT_FACTORY_V2);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                camV2Factory_ = new CamelotFactory(camelotV2FeeTo());
            } else {
                revert("Camelot V2 Factory not declared on this chain");
            }
            console.log("ICamelotFactory set to ", address(camV2Factory_));
            console.log("Declaring address of Camelot V2 Factory.");
            camV2Factory(block.chainid, camV2Factory_);
            console.log("Camelot V2 Factory declared.");
        }
        console.log("CamelotV2Fixture:camV2Factory():: Exiting function.");
        return camV2Factory(block.chainid);
    }

    // ICamelotV2Router internal _camV2Router;

    function camV2Router(
        uint256 chainid,
        ICamelotV2Router camV2Router_
    ) public returns(bool) {
        console.log("CamelotV2Fixture:camV2Router():: Entering function.");
        registerInstance(chainid, keccak256(type(CamelotRouter).creationCode), address(camV2Router_));
        declare(builderKey_CamV2(), "camV2Router", address(camV2Router_));
        console.log("CamelotV2Fixture:camV2Router():: Exiting function.");
        return true;
    }

    function camV2Router(ICamelotV2Router camV2Router_) public returns(bool) {
        console.log("CamelotV2Fixture:camV2Router():: Entering function.");
        camV2Router(block.chainid, camV2Router_);
        console.log("CamelotV2Fixture:camV2Router():: Exiting function.");
        return true;
    }

    function camV2Router(uint256 chainid) public view returns(ICamelotV2Router) {
        console.log("CamelotV2Fixture:camV2Router():: Entering function.");
        console.log("CamelotV2Fixture:camV2Router():: Exiting function.");
        return ICamelotV2Router(chainInstance(chainid, keccak256(type(CamelotRouter).creationCode)));
    }

    /**
     * @notice camV2Router_ Returns the Camelot V2 router for the current chain.
     */
    // TODO Add deployment if no address is declared for a chain.
    function camV2Router() public returns (ICamelotV2Router camV2Router_) {
        console.log("CamelotV2Fixture:camV2Router():: Entering function.");
        console.log("Checking if address is declared for this chain.");
        if(address(camV2Router(block.chainid)) == address(0)) {
            console.log("Camelot V2 Router not set on this chain, setting");
            console.log("Checking if this is ApeChain Mainnet or Curtis Testnet.");
            if(block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                console.log("ApeChain Mainnet detected, setting Camelot V2 Router to APE_CHAIN_MAIN.CAMELOT_ROUTER_V2");
                camV2Router_ = ICamelotV2Router(APE_CHAIN_MAIN.CAMELOT_ROUTER_V2);
            } else if(block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                console.log("ApeChain Curtis detected, setting Camelot V2 Router to APE_CHAIN_CURTIS.CAMELOT_ROUTER_V2");
                camV2Router_ = ICamelotV2Router(APE_CHAIN_CURTIS.CAMELOT_ROUTER_V2);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                camV2Router_ = new CamelotRouter(address(camV2Factory()), address(weth9()));
            } else {
                revert("Camelot V2 Router not deployed on this chain");
            }
            console.log("Declaring address of Camelot V2 Router.");
            camV2Router(block.chainid, camV2Router_);
            console.log("Camelot V2 Router declared.");
        }
        console.log("CamelotV2Fixture:camV2Router():: Exiting function.");
        return camV2Router(block.chainid);
    }

}