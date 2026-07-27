// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {IPMarketFactoryV3} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPMarketFactoryV3.sol";
import {IPMarket} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IPMarket.sol";
import {IStandardizedYield} from
    "@crane/contracts/protocols/perps/pendle/interfaces/IStandardizedYield.sol";

import {BcPendlePhase13aDeploy} from "scripts/foundry/bc/BcPendlePhase13aDeploy.sol";

/// @notice Phase 13a BC fork smoke: deploy seed SY on BC WETH via createSelectFork.
/// @dev Skips if BC RPC unreachable (same pattern as Phase 9 fork). No live broadcast.
contract BC_Phase13a_Pendle_Fork_Test is Test {
    string internal constant BC_RPC = "https://testnet.battlechain.com";

    function test_fork_phase13a_seed_on_bc_weth() public {
        string memory rpc = BC_RPC;
        try vm.envString("BC_FORK_RPC") returns (string memory envRpc) {
            if (bytes(envRpc).length > 0) rpc = envRpc;
        } catch {}

        try vm.createSelectFork(rpc) {
            // ok
        } catch {
            console2.log("SKIP: BC RPC unavailable for Phase 13a fork");
            return;
        }

        if (block.chainid != BC_TESTNET.CHAIN_ID) {
            console2.log("SKIP: fork chainId != 627");
            return;
        }
        if (BC_TESTNET.WETH.code.length == 0) {
            console2.log("SKIP: BC WETH has no code on fork");
            return;
        }

        address treasury = makeAddr("pendleForkTreasury");
        BcPendlePhase13aDeploy helper = new BcPendlePhase13aDeploy();
        BcPendlePhase13aDeploy.DeployResult memory seed = helper.deploySeed(treasury, BC_TESTNET.WETH);

        assertTrue(seed.router.code.length > 0, "router");
        assertTrue(seed.sy.code.length > 0, "sy");
        assertTrue(seed.market.code.length > 0, "market");
        assertTrue(IPMarketFactoryV3(seed.marketFactory).isValidMarket(seed.market), "valid market");
        (IStandardizedYield syR,,) = IPMarket(seed.market).readTokens();
        assertEq(address(syR), seed.sy, "sy bind");
        assertEq(seed.underlying, BC_TESTNET.WETH, "underlying is BC WETH");

        console2.log("fork market", seed.market);
        console2.log("fork sy", seed.sy);
        console2.log("fork router", seed.router);
    }
}
