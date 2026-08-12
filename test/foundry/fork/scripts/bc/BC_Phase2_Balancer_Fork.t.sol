// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {IOperable} from "@crane/contracts/access/operable/IOperable.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {Script_BC_Phase1_Factories} from "scripts/foundry/bc/Script_BC_Phase1_Factories.s.sol";
import {Script_BC_Phase2_BalancerV3} from "scripts/foundry/bc/Script_BC_Phase2_BalancerV3.s.sol";

/// @notice Phase 1→2 greenfield fork: handoff deploy + hard Timelock authorizer.
/// @dev In-process only — no live battlechain-sepolia broadcast.
contract BC_Phase2_Balancer_Fork_Test is Test {
    string internal constant BC_RPC = "https://testnet.battlechain.com";

    address internal deployer;

    function setUp() public {
        string memory rpc = BC_RPC;
        try vm.envString("BC_FORK_RPC") returns (string memory envRpc) {
            if (bytes(envRpc).length > 0) rpc = envRpc;
        } catch {}

        vm.createSelectFork(rpc);
        require(block.chainid == BC_TESTNET.CHAIN_ID, "fork chainId != 627");

        deployer = makeAddr("bcPhase2Deployer");
        vm.deal(deployer, 1000 ether);
    }

    function test_fork_phase1_then_phase2_timelockAuthorizer() public {
        Script_BC_Phase1_Factories p1 = new Script_BC_Phase1_Factories();
        Script_BC_Phase2_BalancerV3 p2 = new Script_BC_Phase2_BalancerV3();

        // In-process: factory owner must be the Phase1 script (nested msg.sender).
        // Phase2 CREATE3 ops also come from p2 — bind uses Phase1 factories where
        // p1 is owner; Phase2 needs to be operator on those factories OR use same owner path.
        // Grant: Phase1 factory owner is p1; for Phase2 deployForFullStack CREATE3, caller is p2.
        // So after Phase1, p1 (owner) must set p2 as operator — or we deploy Phase2 via p1's factory
        // with owner that can authorize. Simplest fork path: make p2 an operator via p1 factory.
        address ownerP1 = address(p1);
        vm.deal(ownerP1, 1000 ether);
        p1.deployForFullStack(ownerP1);

        address create3 = address(p1.coreFactory());
        assertTrue(create3 != BC_TESTNET.ABANDONED_CREATE3_FACTORY, "Phase1 != abandoned");
        assertTrue(create3.code.length > 0, "Phase1 create3 code");

        // Phase2 script calls create3 on Phase1 factory → must be operator/owner.
        // Owner is p1; set p2 as operator on factory (IOperable).
        address ownerP2 = address(p2);
        vm.deal(ownerP2, 1000 ether);
        vm.prank(ownerP1);
        IOperable(create3).setOperator(ownerP2, true);

        p2.deployForFullStack(
            ownerP2,
            create3,
            address(p1.diamondFactory()),
            p1.weth(),
            p1.permit2()
        );

        address vault = p2.vault();
        address authorizer = p2.authorizer();
        address router = p2.router();
        address pfc = p2.protocolFeeController();

        assertTrue(vault.code.length > 0, "vault has code");
        assertTrue(authorizer.code.length > 0, "authorizer has code");
        assertTrue(router.code.length > 0, "router has code");
        assertTrue(pfc != address(0), "script PFC non-zero");
        assertTrue(pfc.code.length > 0, "PFC has code");

        // Hard Timelock: vault must not remain on Null bootstrap.
        address onVault = address(IVault(vault).getAuthorizer());
        assertEq(onVault, authorizer, "script authorizer matches vault getAuthorizer");
        assertTrue(authorizer != address(0), "authorizer non-zero");

        // PFC set under Null before Timelock — must not be silent zero.
        address vaultPfc = address(IVault(vault).getProtocolFeeController());
        assertEq(vaultPfc, pfc, "vault PFC matches script-recorded controller");
        assertTrue(vaultPfc != address(0), "vault PFC non-zero");

        // Manifest generation greenfield from shipped Phase2 writer.
        string memory runtime = vm.readFile("script/output/battlechain-sepolia/greenfield-phase2-balancer-v3.latest.json");
        assertTrue(_contains(runtime, '"generation": "greenfield"'), "phase2 generation");

        console2.log("Phase2 vault", vault);
        console2.log("Phase2 TimelockAuthorizer", authorizer);
        console2.log("Phase2 PFC", pfc);
        console2.log("Phase2 router", router);
        console2.log("getAuthorizer", onVault);
        console2.log("getProtocolFeeController", vaultPfc);
    }

    function _contains(string memory haystack, string memory needle) internal pure returns (bool) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length == 0 || n.length > h.length) return false;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool match_ = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    match_ = false;
                    break;
                }
            }
            if (match_) return true;
        }
        return false;
    }
}
