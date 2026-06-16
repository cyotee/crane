// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {LibraryReportStorage} from "@crane/contracts/protocols/lending/aave/v3.6/deployments/LibraryReportStorage.sol";
import {Create2Utils} from "@crane/contracts/protocols/lending/aave/v3.6/deployments/utilities/Create2Utils.sol";
import {
    LibrariesReport
} from "@crane/contracts/protocols/lending/aave/v3.6/deployments/interfaces/IMarketReportTypes.sol";
import {BorrowLogic} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/logic/BorrowLogic.sol";
import {
    ConfiguratorLogic
} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/logic/ConfiguratorLogic.sol";

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

contract AaveV3LibrariesBatch1 is LibraryReportStorage {
    using BetterEfficientHashLib for bytes;

    constructor() {
        _librariesReport = _deployAaveV3Libraries();
    }

    function _deployAaveV3Libraries() internal returns (LibrariesReport memory libReport) {
        // bytes32 salt = keccak256('AAVE_V3_LIBRARIES_BATCH');
        bytes32 salt = bytes("AAVE_V3_LIBRARIES_BATCH")._hash();

        libReport.borrowLogic = Create2Utils._create2Deploy(salt, type(BorrowLogic).creationCode);
        libReport.configuratorLogic = Create2Utils._create2Deploy(salt, type(ConfiguratorLogic).creationCode);
        return libReport;
    }
}
