// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {FraxswapPair} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";

import {BcFraxPhase13bDeploy} from "scripts/foundry/bc/BcFraxPhase13bDeploy.sol";

/// @notice Phase 13b BC fork smoke: factory + WETH/USDC pair + BAMM graph on createSelectFork.
/// @dev Skips if BC RPC down. Pair may be unseeded (no token balances); still requires pair code.
contract BC_Phase13b_Frax_Fork_Test is Test {
    string internal constant BC_RPC = "https://testnet.battlechain.com";

    function test_fork_phase13b_factory_pair_bamm_on_bc_tokens() public {
        string memory rpc = BC_RPC;
        try vm.envString("BC_FORK_RPC") returns (string memory envRpc) {
            if (bytes(envRpc).length > 0) rpc = envRpc;
        } catch {}

        try vm.createSelectFork(rpc) {}
        catch {
            console2.log("SKIP: BC RPC unavailable for Phase 13b fork");
            return;
        }

        if (block.chainid != BC_TESTNET.CHAIN_ID) {
            console2.log("SKIP: fork chainId != 627");
            return;
        }
        if (BC_TESTNET.WETH.code.length == 0 || BC_TESTNET.USDC.code.length == 0) {
            console2.log("SKIP: BC WETH/USDC missing");
            return;
        }

        address owner = makeAddr("fraxForkOwner");
        BcFraxPhase13bDeploy helper = new BcFraxPhase13bDeploy();
        BcFraxPhase13bDeploy.DeployResult memory g =
            helper.deployWithTokens(owner, BC_TESTNET.WETH, BC_TESTNET.USDC, 0);

        assertTrue(g.fraxswapFactory.code.length > 0, "factory");
        assertTrue(g.pair.code.length > 0, "pair");
        assertTrue(g.bamm.code.length > 0, "bamm");
        assertTrue(g.bammHelper.code.length > 0, "helper");
        assertTrue(g.fraxswapOracle.code.length > 0, "oracle");
        assertTrue(g.fraxswapDummyRouter.code.length > 0, "dummyRouter");

        FraxswapPair pair = FraxswapPair(g.pair);
        address t0 = pair.token0();
        address t1 = pair.token1();
        assertTrue(
            (t0 == BC_TESTNET.WETH && t1 == BC_TESTNET.USDC)
                || (t0 == BC_TESTNET.USDC && t1 == BC_TESTNET.WETH),
            "pair is WETH/USDC"
        );

        console2.log("fork fraxswapFactory", g.fraxswapFactory);
        console2.log("fork pair", g.pair);
        console2.log("fork bamm", g.bamm);
    }
}
