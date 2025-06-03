// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {LOCAL} from "../../constants/networks/LOCAL.sol";
import {APE_CHAIN_MAIN} from "../../constants/networks/APE_CHAIN_MAIN.sol";
import {APE_CHAIN_CURTIS} from "../../constants/networks/APE_CHAIN_CURTIS.sol";
import {Fixture} from "../Fixture.sol";
import {ArbOSVM} from "../../utils/vm/arbOS/ArbOSVM.sol";
import {ArbOSFixture} from "./ArbOSFixture.sol";
// import {IWETH} from "../../../../protocols/tokens/wrappers/weth/IWETH.sol";
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {WAPE} from "../../protocols/tokens/wrappers/wape/WAPE.sol";

contract ApeChainFixture
is
// Fixture,
ArbOSFixture
{

    function builderKey_ApeChain() public pure returns (string memory) {
        return "apeChain";
    }

    function initialize()
    public virtual
    override(
        // Fixture,
        ArbOSFixture
    ) {

    }

    // IWETH internal _wape;

    function wape(
        uint256 chainid,
        IWETH wape_
    ) public returns(bool) {
        registerInstance(chainid, keccak256(type(WAPE).creationCode), address(wape_));
        declare(builderKey_ApeChain(), "wape", address(wape_));
        return true;
    }

    function wape(IWETH wape_) public returns(bool) {
        // _log("ApeChainFixture::wape(IWETH wape_):: Entering function");
        // _log("ApeChainFixture::wape(IWETH wape_):: Setting provided wape of %s", address(wape_));
        wape(block.chainid, wape_);
        // _log("ApeChainFixture::wape(IWETH wape_):: Declaring address of wape");
        declare(builderKey_ApeChain(), "wape", address(wape_));
        // _log("ApeChainFixture::wape(IWETH wape_):: Declared address of wape");
        // _log("ApeChainFixture::wape(IWETH wape_):: Exiting function");
        return true;
    }

    function wape(uint256 chainid)
    public virtual view returns(IWETH wape_) {
        wape_ = IWETH(chainInstance(chainid, keccak256(abi.encode(wape_))));
    }

    function wape()
    public virtual
    returns(IWETH wape_) {
        // _log("ApeChainFixture::wape():: Entering function");
        // _log("ApeChainFixture::wape():: Checking if wape is declared");
        if(address(wape(block.chainid)) == address(0)) {
            // _log("ApeChainFixture::wape():: WAPE is not declared, deploying...");
            // _log("ApeChainFixture::wape():: Checking if this is a test");
            if(isAnyTest()) {
                // _log("ApeChainFixture::wape():: This is a test, initializing precompiles");
                arbOwnerPublic();
                // _log("ApeChainFixture::wape():: Precompiles initialized");
            }
            // _log("ApeChainFixture::wape():: Deploying wape");
            if(block.chainid == APE_CHAIN_MAIN.CHAIN_ID) {
                wape_ = IWETH(APE_CHAIN_MAIN.WAPE);
            } else if(block.chainid == APE_CHAIN_CURTIS.CHAIN_ID) {
                wape_ = IWETH(APE_CHAIN_CURTIS.WAPE);
            } else if(block.chainid == LOCAL.CHAIN_ID) {
                wape_ = new WAPE();
            }
            // _log("ApeChainFixture::wape():: Deployed wape");
            wape(wape_);
        }
        // _log("ApeChainFixture::wape():: Returning value from storage presuming it would have been set based on chain state.");
        // _log("ApeChainFixture::wape():: Exiting function");
        return wape(block.chainid);
    }

}