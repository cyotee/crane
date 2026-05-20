// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                BattleChain                                 */
/* -------------------------------------------------------------------------- */

import {IAgreement} from "battlechain-lib/interfaces/IAgreement.sol";
import {IBCSafeHarborRegistry} from "battlechain-lib/interfaces/IBCSafeHarborRegistry.sol";
import {AgreementDetails, ChildContractScope} from "battlechain-lib/types/AgreementTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Script_Pilot_BC_ERC20Permit} from "../../../../scripts/foundry/Script_Pilot_BC_ERC20Permit.s.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC2612} from "@crane/contracts/interfaces/IERC2612.sol";

/// @notice Fork test against BattleChain testnet (chain 627). Skips cleanly when the
///         RPC is unreachable or chain id is wrong. Uses only the v0.1.2
///         `battlechain-lib` interfaces — the lineage-query methods on AttackRegistry
///         (getAgreementForContract / isTopLevelContractUnderAttack) are not in the
///         lib's interface so we verify coverage via IAgreement.isContractInScope
///         and IAgreement.getBattleChainScopeAddresses instead.
contract Pilot_BC_ERC20Permit_Fork_Test is Script_Pilot_BC_ERC20Permit, Test {
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal ownerPk;
    address internal ownerAddr;
    address internal spender;
    bool internal forkReady;

    function setUp() public {
        string memory rpc;
        try vm.envString("BC_TESTNET_RPC") returns (string memory r) {
            rpc = r;
        } catch {
            rpc = "https://testnet.battlechain.com";
        }

        try vm.createSelectFork(rpc) returns (uint256) {}
        catch {
            forkReady = false;
            return;
        }

        if (block.chainid != 627) {
            forkReady = false;
            return;
        }

        forkReady = true;

        ownerPk = 0xA11CE;
        ownerAddr = vm.addr(ownerPk);
        spender = address(0xBEEF);

        vm.deal(address(this), 100 ether);
    }

    function test_fork_endToEnd_deployAndScopeIsCorrect() public {
        if (!forkReady) {
            vm.skip(true);
            return;
        }
        _runDeploy(address(this), ownerAddr);

        // Adoption registered through real BattleChain Safe Harbor registry.
        assertEq(
            IBCSafeHarborRegistry(_bcRegistry()).getAgreement(address(this)),
            agreement,
            "adoption registered with real registry"
        );

        // Commitment window honored on the real agreement contract.
        assertGt(IAgreement(agreement).getCantChangeUntil(), block.timestamp, "commitment window set");

        // The agreement lists exactly one BattleChain-scope account — the core factory.
        address[] memory scope = IAgreement(agreement).getBattleChainScopeAddresses();
        assertEq(scope.length, 1, "exactly one scope account");
        assertEq(scope[0], address(coreFactory), "scope account is the core factory");

        // The on-chain agreement reports the core factory as in scope. (Whether the lineage
        // children — diamond factory, package, proxy — resolve as "covered" depends on the
        // BattleChain explorer indexer walking deployer lineage off-chain; that is a manual
        // block-explorer verification, not an on-chain assertion.)
        assertTrue(IAgreement(agreement).isContractInScope(address(coreFactory)), "core factory in scope");

        // Protocol name and bounty terms match what defaultAgreementDetails produced.
        assertEq(IAgreement(agreement).getProtocolName(), _protocolName(), "protocol name");
    }

    function test_fork_permitSignature_works() public {
        if (!forkReady) {
            vm.skip(true);
            return;
        }
        _runDeploy(address(this), ownerAddr);

        uint256 value = 25 ether;
        uint256 deadline = block.timestamp + 1 hours;
        uint256 nonce = IERC2612(permitProxy).nonces(ownerAddr);

        bytes32 ds = IERC2612(permitProxy).DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, ownerAddr, spender, value, nonce, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", ds, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        IERC2612(permitProxy).permit(ownerAddr, spender, value, deadline, v, r, s);

        assertEq(IERC20(permitProxy).allowance(ownerAddr, spender), value, "allowance updated");
        assertEq(IERC2612(permitProxy).nonces(ownerAddr), nonce + 1, "nonce incremented");
    }
}
