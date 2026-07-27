// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";

import {CamelotFactory} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotFactory.sol";
import {CamelotRouter} from "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotRouter.sol";
import {WETH9} from "@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol";
import {MockERC20} from "@crane/contracts/test/mocks/MockERC20.sol";

/// @notice Phase 8 Camelot V2 factory + router (+ optional createPair smoke).
contract BcCamelotPhase8Deploy is Script {
    struct DeployResult {
        address camelotFactory;
        address camelotRouter;
        address weth;
        address samplePair;
        address token0;
        address token1;
    }

    function deploy(address feeToSetter, address weth_) external returns (DeployResult memory r) {
        require(feeToSetter != address(0), "p8: feeToSetter zero");
        require(weth_ != address(0), "p8: weth zero");
        r.weth = weth_;
        r.camelotFactory = address(new CamelotFactory(feeToSetter));
        r.camelotRouter = address(new CamelotRouter(r.camelotFactory, weth_));
        console2.log("p8 camelotFactory", r.camelotFactory);
        console2.log("p8 camelotRouter", r.camelotRouter);
        return r;
    }

    /// @notice Hermetic factory+router+createPair.
    function deployHermetic(address feeToSetter) external returns (DeployResult memory r) {
        WETH9 weth_ = new WETH9();
        r = this.deploy(feeToSetter, address(weth_));

        MockERC20 t0 = new MockERC20("TokenA", "TKA", 18);
        MockERC20 t1 = new MockERC20("TokenB", "TKB", 18);
        r.token0 = address(t0);
        r.token1 = address(t1);
        t0.mint(feeToSetter, 1_000_000e18);
        t1.mint(feeToSetter, 1_000_000e18);

        r.samplePair = CamelotFactory(r.camelotFactory).createPair(address(t0), address(t1));
        require(r.samplePair != address(0) && r.samplePair.code.length > 0, "p8: pair");
        return r;
    }
}
