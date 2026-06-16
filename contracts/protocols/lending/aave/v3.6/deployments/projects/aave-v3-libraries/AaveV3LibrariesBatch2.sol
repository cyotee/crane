// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {LibraryReportStorage} from "@crane/contracts/protocols/lending/aave/v3.6/deployments/LibraryReportStorage.sol";
import {Create2Utils} from "@crane/contracts/protocols/lending/aave/v3.6/deployments/utilities/Create2Utils.sol";
import {
    LibrariesReport
} from "@crane/contracts/protocols/lending/aave/v3.6/deployments/interfaces/IMarketReportTypes.sol";

import {FlashLoanLogic} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/logic/FlashLoanLogic.sol";
import {
    LiquidationLogic
} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/logic/LiquidationLogic.sol";
import {PoolLogic} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/logic/PoolLogic.sol";
import {SupplyLogic} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/logic/SupplyLogic.sol";

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

contract AaveV3LibrariesBatch2 is LibraryReportStorage {
    using BetterEfficientHashLib for bytes;

    constructor() {
        _librariesReport = _deployAaveV3Libraries();
    }

    function _deployAaveV3Libraries() internal returns (LibrariesReport memory libReport) {
        bytes32 salt = bytes("AAVE_V3_LIBRARIES_BATCH")._hash();

        libReport.flashLoanLogic = Create2Utils._create2Deploy(salt, type(FlashLoanLogic).creationCode);
        libReport.liquidationLogic = Create2Utils._create2Deploy(salt, type(LiquidationLogic).creationCode);
        libReport.poolLogic = Create2Utils._create2Deploy(salt, type(PoolLogic).creationCode);
        libReport.supplyLogic = Create2Utils._create2Deploy(salt, type(SupplyLogic).creationCode);
        return libReport;
    }
}
