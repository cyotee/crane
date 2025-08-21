// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {FactoryWidePauseWindowStorage} from "contracts/protocols/dexes/balancer/v3/solidity-utils/helpers/utils/FactoryWidePauseWindowStorage.sol";
import {IFactoryWidePauseWindow} from "contracts/interfaces/IFactoryWidePauseWindow.sol";

contract FactoryWidePauseWindowTarget is FactoryWidePauseWindowStorage, IFactoryWidePauseWindow {

    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getPauseWindowDuration() external view returns (uint32) {
        return _getPauseWindowDuration();
    }

    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getOriginalPauseWindowEndTime() external view returns (uint32) {
        return _getOriginalPauseWindowEndTime();
    }

    /**
     * @inheritdoc IFactoryWidePauseWindow
     */
    function getNewPoolPauseWindowEndTime() public view returns (uint32) {
        return _getNewPoolPauseWindowEndTime();
    }

}