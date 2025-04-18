// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../../../../../fixtures/Fixture.sol";

import "../interfaces/ICamelotFactory.sol";
import "../interfaces/ICamelotPair.sol";
import "../interfaces/ICamelotV2Router.sol";

import "../../../../../networks/arbitrum/apechain/constants/APE_CHAIN_MAIN.sol";
import "../../../../../networks/arbitrum/apechain/constants/APE_CHAIN_CURTIS.sol";

/**
 * @title Camelot V2 Fixture
 * @notice Fixture for the Camelot V2 protocol.
 * @notice Determines which address to use for a discovered chain.
 */
// TODO Port Camelot V2 pools intto this repo, add deployment to this fixture when no address is declared for a chain.
contract CamelotV2Fixture
is
Fixture
{

    function builderKey_CamV2() public pure returns (string memory) {
        return "camelotV2";
    }

    function initialize()
    public virtual
    override(
        Fixture
    ) {
        // _log("CamelotV2Fixture:setUp():: Entering function.");
        // _log("Declaring addresses of Camelot V2 Factory and Router in json of all.");
        // _log("Declaring Camelot V2 Factory.");
        declare(vm.getLabel(address(camV2Factory())), address(camV2Factory()));
        // _log("Camelot V2 Factory declared.");
        // _log("Declaring Camelot V2 Router.");
        declare(vm.getLabel(address(camV2Router())), address(camV2Router()));
        // _log("Camelot V2 Router declared.");
        // _log("CamelotV2Fixture:setUp():: Exiting function.");
    }

    /* ---------------------------------------------------------------------- */
    /*                                External                                */
    /* ---------------------------------------------------------------------- */

    /* ----------------------------- Camelot V2 ----------------------------- */

    ICamelotFactory internal _camV2Factory;

    /**
     * @notice camV2Factory_ Returns the Camelot V2 factory for the current chain.
     */
    // TODO Add deployment if no address is declared for a chain.
    function camV2Factory() public returns (ICamelotFactory camV2Factory_) {
        // _log("CamelotV2Fixture:camV2Factory():: Entering function.");
        // _log("Checking if address is declared for this chain.");
        if(address(_camV2Factory) == address(0)) {
            // _log("Camelot V2 Factory not set on this chain, setting");
            // _log("Checking if this is ApeChain Mainnet or Curtis Testnet.");
            if(block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                // _log("ApeChain Mainnet detected, setting Camelot V2 Factory to APE_CHAIN_MAIN.CAMELOT_FACTORY_V2");
                _camV2Factory = ICamelotFactory(APE_CHAIN_MAIN.CAMELOT_FACTORY_V2);
            } else if(block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                // _log("ApeChain Curtis detected, setting Camelot V2 Factory to APE_CHAIN_CURTIS.CAMELOT_FACTORY_V2");
                _camV2Factory = ICamelotFactory(APE_CHAIN_CURTIS.CAMELOT_FACTORY_V2);
            } else {
                revert("Camelot V2 Factory not declares on this chain");
            }
            // _log("ICamelotFactory set to ", address(_camV2Factory));
            // _log("Declaring address of Camelot V2 Factory.");
            declare(builderKey_CamV2(), "camV2Factory", address(_camV2Factory));
            // _log("Camelot V2 Factory declared.");
        }
        // _log("CamelotV2Fixture:camV2Factory():: Exiting function.");
        return _camV2Factory;
    }

    ICamelotV2Router internal _camV2Router;

    /**
     * @notice camV2Router_ Returns the Camelot V2 router for the current chain.
     */
    // TODO Add deployment if no address is declared for a chain.
    function camV2Router() public returns (ICamelotV2Router camV2Router_) {
        // _log("CamelotV2Fixture:camV2Router():: Entering function.");
        // _log("Checking if address is declared for this chain.");
        if(address(_camV2Router) == address(0)) {
            // _log("Camelot V2 Router not set on this chain, setting");
            // _log("Checking if this is ApeChain Mainnet or Curtis Testnet.");
            if(block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                // _log("ApeChain Mainnet detected, setting Camelot V2 Router to APE_CHAIN_MAIN.CAMELOT_ROUTER_V2");
                _camV2Router = ICamelotV2Router(APE_CHAIN_MAIN.CAMELOT_ROUTER_V2);
            } else if(block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                // _log("ApeChain Curtis detected, setting Camelot V2 Router to APE_CHAIN_CURTIS.CAMELOT_ROUTER_V2");
                _camV2Router = ICamelotV2Router(APE_CHAIN_CURTIS.CAMELOT_ROUTER_V2);
            } else {
                revert("Camelot V2 Router not deployed on this chain");
            }
            // _log("Declaring address of Camelot V2 Router.");
            declare(builderKey_CamV2(), "camV2Router", address(_camV2Router));
            // _log("Camelot V2 Router declared.");
        }
        // _log("CamelotV2Fixture:camV2Router():: Exiting function.");
        return _camV2Router;
    }

}