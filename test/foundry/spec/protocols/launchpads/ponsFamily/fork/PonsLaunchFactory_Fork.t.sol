// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    TestBase_PonsFamily_Fork
} from "@crane/contracts/protocols/launchpads/ponsFamily/test/bases/TestBase_PonsFamily_Fork.sol";
import {ROBINHOOD_MAIN} from "@crane/contracts/constants/networks/ROBINHOOD_MAIN.sol";
import {PonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/pons/PonsLaunchFactory.sol";

/// @notice Active factory/locker bind + view surface on Robinhood mainnet fork.
/// @dev Run: `FOUNDRY_PROFILE=pons_port forge test --match-path 'test/foundry/spec/protocols/launchpads/ponsFamily/fork/**' -vv`
contract PonsLaunchFactory_Fork_Test is TestBase_PonsFamily_Fork {
    function test_activeFactory_hasCode() public view {
        assertGt(ROBINHOOD_MAIN.PONS_LAUNCH_FACTORY_ACTIVE.code.length, 0);
        assertEq(address(ponsFactory), ROBINHOOD_MAIN.PONS_LAUNCH_FACTORY_ACTIVE);
    }

    function test_activeLocker_hasCode() public view {
        assertGt(ROBINHOOD_MAIN.PONS_LAUNCH_LOCKER_ACTIVE.code.length, 0);
        assertEq(address(ponsLocker), ROBINHOOD_MAIN.PONS_LAUNCH_LOCKER_ACTIVE);
    }

    function test_factory_viewSurface() public view {
        uint256 fee = ponsFactory.launchFee();
        uint256 launchConfigs = ponsFactory.launchConfigCount();
        uint256 dexConfigs = ponsFactory.dexConfigCount();

        // Live values verified 2026-07-28 on public RH RPC (see VENDOR.md).
        assertEq(fee, 0.0005 ether, "launchFee");
        assertGe(launchConfigs, 1, "at least one launch config");
        assertGe(dexConfigs, 1, "at least one dex config");

        PonsLaunchFactory.LaunchConfig memory cfg = ponsFactory.getLaunchConfig(0);
        assertEq(cfg.pairToken, ROBINHOOD_MAIN.WETH);
        assertEq(cfg.graduationThreshold, 4.2 ether);
        assertEq(cfg.supply, 1_000_000_000 ether);
        assertEq(cfg.maxWalletBps, 500);
        assertEq(cfg.maxTxBps, 550);
        assertEq(cfg.restrictionBlocks, 2);
        assertEq(cfg.initialTick, -204_200);
        assertTrue(cfg.enabled);

        assertEq(ROBINHOOD_MAIN.PONS_ACTIVE_START_BLOCK, 8_991_118);
    }
}
