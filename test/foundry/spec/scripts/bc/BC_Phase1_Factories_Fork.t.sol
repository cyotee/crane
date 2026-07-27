// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {Script_BC_Phase1_Factories} from "scripts/foundry/bc/Script_BC_Phase1_Factories.s.sol";

/// @notice Phase 1 greenfield fork smoke: deployForFullStack on BC createSelectFork.
/// @dev In-process only — no live battlechain-sepolia broadcast.
contract BC_Phase1_Factories_Fork_Test is Test {
    string internal constant BC_RPC = "https://testnet.battlechain.com";

    address internal deployer;

    function setUp() public {
        string memory rpc = BC_RPC;
        try vm.envString("BC_FORK_RPC") returns (string memory envRpc) {
            if (bytes(envRpc).length > 0) rpc = envRpc;
        } catch {}

        vm.createSelectFork(rpc);
        require(block.chainid == BC_TESTNET.CHAIN_ID, "fork chainId != 627");

        deployer = makeAddr("bcPhase1Deployer");
        vm.deal(deployer, 1000 ether);
    }

    function test_fork_phase1_deployForFullStack_greenfieldIdentity() public {
        // Preconditions: greenfield CREATE3 unset; BC binds live; abandoned is Wave A only.
        assertEq(BC_TESTNET.CREATE3_FACTORY, address(0), "CREATE3 must remain unset pre-live");
        assertTrue(BC_TESTNET.WETH.code.length > 0, "BC WETH");
        assertTrue(BC_TESTNET.DEPLOYER.code.length > 0, "BC Deployer");

        Script_BC_Phase1_Factories p1 = new Script_BC_Phase1_Factories();

        // In-process (no forge --broadcast): nested factory calls use msg.sender = script.
        // Factory owner must be the script address so onlyOwnerOrOperator passes.
        // Live forge script --broadcast rewrites nested external calls to come from --sender.
        address owner = address(p1);
        vm.deal(owner, 1000 ether);
        p1.deployForFullStack(owner);

        address create3 = address(p1.coreFactory());
        address diamond = address(p1.diamondFactory());

        assertTrue(create3 != address(0), "coreFactory set");
        assertTrue(create3 != BC_TESTNET.ABANDONED_CREATE3_FACTORY, "must not bind abandoned gen-1");
        assertTrue(create3.code.length > 0, "coreFactory has code");
        assertTrue(diamond != address(0), "diamondFactory set");
        assertTrue(diamond.code.length > 0, "diamondFactory has code");
        assertEq(p1.weth(), BC_TESTNET.WETH, "WETH is BC-provided");
        assertTrue(p1.permit2().code.length > 0, "Permit2 has code");
        assertTrue(p1.samplePermitToken().code.length > 0, "sample token has code");
        assertTrue(p1.uniV2Factory().code.length > 0, "UniV2 factory has code");
        assertTrue(p1.uniV4PoolManager().code.length > 0, "V4 PoolManager has code");

        // Identity: greenfield agreement salt (not Wave A promo).
        assertTrue(
            p1.agreement() != address(0) || block.chainid != BC_TESTNET.CHAIN_ID,
            "agreement expected on BC when Safe Harbor available"
        );

        // Manifest identity written by shipped script (generation greenfield).
        string memory runtime = vm.readFile("script/output/battlechain-sepolia/greenfield-phase1.latest.json");
        assertTrue(bytes(runtime).length > 0, "runtime manifest written");
        assertTrue(_contains(runtime, '"generation": "greenfield"'), "generation greenfield");
        assertTrue(_contains(runtime, "crane-indexedex-bc-greenfield-v1"), "greenfield agreement salt");
        assertTrue(!_contains(runtime, "crane-indexedex-bc-promo-v1"), "no promo salt");

        console2.log("Phase1 greenfield Create3Factory", create3);
        console2.log("Phase1 diamondFactory", diamond);
        console2.log("Phase1 permit2", p1.permit2());
        console2.log("Phase1 agreement", p1.agreement());
    }

    function _contains(string memory haystack, string memory needle) internal pure returns (bool) {
        return bytes(haystack).length >= bytes(needle).length
            && _indexOf(haystack, needle) != type(uint256).max;
    }

    function _indexOf(string memory haystack, string memory needle) internal pure returns (uint256) {
        bytes memory h = bytes(haystack);
        bytes memory n = bytes(needle);
        if (n.length == 0 || n.length > h.length) return type(uint256).max;
        for (uint256 i = 0; i <= h.length - n.length; i++) {
            bool match_ = true;
            for (uint256 j = 0; j < n.length; j++) {
                if (h[i + j] != n[j]) {
                    match_ = false;
                    break;
                }
            }
            if (match_) return i;
        }
        return type(uint256).max;
    }
}
