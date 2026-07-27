// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_MorphoBlue} from
    "@crane/contracts/protocols/lending/morpho/blue/test/bases/TestBase_MorphoBlue.sol";
import {VaultV2Factory} from "@crane/contracts/external/morpho/vault-v2/VaultV2Factory.sol";
import {IVaultV2} from "@crane/contracts/external/morpho/vault-v2/interfaces/IVaultV2.sol";
import {Bundler3} from "@crane/contracts/external/morpho/bundler3/Bundler3.sol";
import {Call} from "@crane/contracts/external/morpho/bundler3/interfaces/IBundler3.sol";

/// @title MorphoBlueVaultBundlerSmoke
/// @notice Hermetic smoke: deploy Vault V2 factory + Bundler3 (Phase 6).
contract MorphoBlueVaultBundlerSmoke_Test is TestBase_MorphoBlue {
    function test_vaultV2_factory_create() public {
        VaultV2Factory factory = new VaultV2Factory();
        address owner = makeAddr("vaultOwner");
        IVaultV2 vault = IVaultV2(factory.createVaultV2(owner, address(loanToken), bytes32(uint256(42))));
        assertEq(vault.owner(), owner);
        assertEq(vault.asset(), address(loanToken));
        assertGt(address(vault).code.length, 0);
    }

    function test_bundler3_deploy_and_nonempty_multicall() public {
        Bundler3 bundler = new Bundler3();
        assertGt(address(bundler).code.length, 0);

        // Empty bundle reverts EmptyBundle(); use a single no-op self-call.
        Call[] memory calls = new Call[](1);
        calls[0] = Call({
            to: address(0xdead),
            data: "",
            value: 0,
            skipRevert: true,
            callbackHash: bytes32(0)
        });
        bundler.multicall(calls);
    }
}
