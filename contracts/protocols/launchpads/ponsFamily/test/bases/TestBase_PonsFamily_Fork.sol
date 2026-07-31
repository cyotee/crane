// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {ROBINHOOD_MAIN} from "@crane/contracts/constants/networks/ROBINHOOD_MAIN.sol";
import {PonsLaunchFactory} from
    "@crane/contracts/protocols/launchpads/ponsFamily/pons/PonsLaunchFactory.sol";
import {IPonsLaunchLocker} from
    "@crane/contracts/protocols/launchpads/ponsFamily/pons/interfaces/ILaunchpad.sol";

/// @title TestBase_PonsFamily_Fork
/// @notice Profile-gated Robinhood mainnet fork bind for active pons factory + locker.
abstract contract TestBase_PonsFamily_Fork is Test {
    PonsLaunchFactory internal ponsFactory;
    IPonsLaunchLocker internal ponsLocker;

    function setUp() public virtual {
        // Public RH RPC is often non-archive; pin near active era when available, else latest.
        // Prefer a block after PONS_ACTIVE_START_BLOCK so active factory/locker exist.
        _selectRobinhoodFork();

        ponsFactory = PonsLaunchFactory(ROBINHOOD_MAIN.PONS_LAUNCH_FACTORY_ACTIVE);
        ponsLocker = IPonsLaunchLocker(ROBINHOOD_MAIN.PONS_LAUNCH_LOCKER_ACTIVE);

        assertGt(address(ponsFactory).code.length, 0, "active factory has code");
        assertGt(address(ponsLocker).code.length, 0, "active locker has code");

        vm.label(address(ponsFactory), "PONS_LAUNCH_FACTORY_ACTIVE");
        vm.label(address(ponsLocker), "PONS_LAUNCH_LOCKER_ACTIVE");
    }

    function _selectRobinhoodFork() internal {
        // Public RH RPC often returns "metadata is not found" for historical pins
        // (Orbit/Nitro). Prefer tip; Alchemy archive can pin when key is present.
        string memory url = vm.rpcUrl("robinhood_mainnet");
        try vm.createSelectFork(url) {
            return;
        } catch {}
        try vm.createSelectFork(vm.rpcUrl("robinhood_mainnet_public")) {
            return;
        } catch {}
        // Optional Alchemy archive pin (fails closed if key/template unavailable).
        try vm.createSelectFork(vm.rpcUrl("robinhood_mainnet_alchemy"), ROBINHOOD_MAIN.DEFAULT_FORK_BLOCK)
        {
            return;
        } catch {}
        revert("PonsFamily_Fork: no Robinhood RPC fork available");
    }
}
