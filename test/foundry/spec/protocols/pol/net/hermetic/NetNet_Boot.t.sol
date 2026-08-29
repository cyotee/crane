// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {TestBase_NetNet} from
    "@crane/contracts/protocols/pol/net/test/bases/TestBase_NetNet.sol";
import {ShareCertificate} from "@crane/contracts/protocols/pol/net/src/ShareCertificate.sol";

/**
 * @title NetNet_Boot
 * @notice Hermetic genesis boot checks after real `wire()` + `GenesisBond.finalize()`.
 */
contract NetNet_Boot_Test is TestBase_NetNet {
    function test_boot_finalized_and_enabled() public view {
        assertTrue(genesisBond.finalized(), "genesis finalized");
        assertTrue(staking.enabled(), "staking enabled");
        assertTrue(bondDepository.enabled(), "bonds enabled");
        assertTrue(net.taxEnabled(), "tax enabled");
    }

    function test_boot_canonical_pair_taxed() public view {
        assertEq(treasury.canonicalPair(), address(pair), "treasury pair");
        assertEq(net.canonicalPair(), address(pair), "net pair");
        assertTrue(net.isTaxedPair(address(pair)), "pair taxed");
    }

    function test_boot_founder_soulbound_certificate() public {
        uint256 tokenId = shareCertificate.certificateOf(founders[0]);
        assertTrue(tokenId != 0, "certificate minted");
        vm.expectRevert(ShareCertificate.Soulbound.selector);
        shareCertificate.transferFrom(founders[0], address(this), tokenId);
    }

    function test_boot_rebalanceToMorpho_increases_morphoAssets() public {
        assertEq(address(treasury.morphoVault()), address(vault), "vault is morphoVault");
        uint256 beforeAssets = treasury.morphoAssets();
        uint256 depositRaw = 1_000e6;
        treasury.rebalanceToMorpho(depositRaw);
        uint256 afterAssets = treasury.morphoAssets();
        assertGt(afterAssets, beforeAssets, "morphoAssets increased");
    }
}
