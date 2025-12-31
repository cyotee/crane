// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {PowerCalculatorAwareLayout, PowerCalculatorAwareRepo} from "./PowerCalculatorAwareRepo.sol";
import {IPowerCalculatorAware} from "contracts/crane/interfaces/IPowerCalculatorAware.sol";
import {IPower} from "contracts/crane/interfaces/IPower.sol";

interface IPowerCalculatorAwareStorage {
    struct PowerCalculatorAwareInit {
        IPower powerCalculator;
    }
}

contract PowerCalculatorAwareStorage is IPowerCalculatorAwareStorage {
    using PowerCalculatorAwareRepo for bytes32;

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(PowerCalculatorAwareRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE = type(IPowerCalculatorAware).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    function _powerCalcAware() internal pure virtual returns (PowerCalculatorAwareLayout storage) {
        return STORAGE_SLOT._layout();
    }

    function _power() internal view returns (IPower) {
        return _powerCalcAware().powerCalculator;
    }

    function _initPowerAware(
        IPowerCalculatorAwareStorage.PowerCalculatorAwareInit memory powerCalculatorAwareTargetInit
    ) internal {
        _powerCalcAware().powerCalculator = powerCalculatorAwareTargetInit.powerCalculator;
    }

    function _initPowerAware(IPower powerCalculator) internal {
        _powerCalcAware().powerCalculator = powerCalculator;
    }
}
