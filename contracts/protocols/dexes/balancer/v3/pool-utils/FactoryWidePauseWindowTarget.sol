// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3BasePoolFactoryRepo
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-utils/BalancerV3BasePoolFactoryRepo.sol";
import {IFactoryWidePauseWindow} from "@crane/contracts/interfaces/IFactoryWidePauseWindow.sol";

contract FactoryWidePauseWindowTarget is IFactoryWidePauseWindow {
    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getPauseWindowDuration() external view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._pauseWindowDuration();
    }

    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getOriginalPauseWindowEndTime() external view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._pauseWindowEndTime();
    }

    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getNewPoolPauseWindowEndTime() public view returns (uint32) {
        return BalancerV3BasePoolFactoryRepo._getNewPoolPauseWindowEndTime();
    }
}
