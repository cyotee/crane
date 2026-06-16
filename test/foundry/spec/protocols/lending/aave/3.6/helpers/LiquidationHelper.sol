// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IPool} from "@crane/contracts/protocols/lending/aave/v3.6/interfaces/IPool.sol";
import {IAaveOracle} from "@crane/contracts/protocols/lending/aave/v3.6/interfaces/IAaveOracle.sol";
import {
    LiquidationLogic
} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/logic/LiquidationLogic.sol";
import {
    ReserveConfiguration
} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/configuration/ReserveConfiguration.sol";
import {
    EModeConfiguration
} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/configuration/EModeConfiguration.sol";
import {DataTypes} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/types/DataTypes.sol";
import {PercentageMath} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/math/PercentageMath.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";

/**
 * @title LiquidationHelper
 * @author BGD Labs
 * @notice Utility library to be used inside tests, replicating internal contract logic via external calls.
 */
library LiquidationHelper {
    using PercentageMath for uint256;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    struct LocalVars {
        address user;
        uint256 liquidationBonus;
        uint256 userEMode;
        address oracle;
        address vToken;
    }

    /**
     * replicates LiquidationLogic._calculateAvailableCollateralToLiquidate without direct storage access
     */
    function _getLiquidationParams(
        IPool pool,
        address user,
        address collateralAsset,
        address debtAsset,
        uint256 liquidationAmount,
        uint256 maxLiquidatableDebt
    ) internal view returns (uint256, uint256, uint256, uint256) {
        LocalVars memory local;
        local.user = user;
        maxLiquidatableDebt = liquidationAmount > maxLiquidatableDebt ? maxLiquidatableDebt : liquidationAmount;
        DataTypes.ReserveDataLegacy memory collateralReserveData = pool.getReserveData(collateralAsset);
        local.liquidationBonus = collateralReserveData.configuration.getLiquidationBonus();
        local.userEMode = pool.getUserEMode(local.user);
        if (local.userEMode != 0) {
            uint128 collateralConfig = pool.getEModeCategoryCollateralBitmap(uint8(local.userEMode));
            if (EModeConfiguration.isReserveEnabledOnBitmap(collateralConfig, collateralReserveData.id)) {
                local.liquidationBonus = pool.getEModeCategoryCollateralConfig(uint8(local.userEMode)).liquidationBonus;
            }
        }
        local.oracle = pool.ADDRESSES_PROVIDER().getPriceOracle();
        local.vToken = pool.getReserveVariableDebtToken(debtAsset);
        return LiquidationLogic._calculateAvailableCollateralToLiquidate(
            collateralReserveData.configuration,
            IAaveOracle(local.oracle).getAssetPrice(collateralAsset),
            10 ** IERC20Metadata(collateralReserveData.aTokenAddress).decimals(),
            IAaveOracle(local.oracle).getAssetPrice(debtAsset),
            10 ** IERC20Metadata(local.vToken).decimals(),
            maxLiquidatableDebt,
            IERC20Metadata(collateralReserveData.aTokenAddress).balanceOf(local.user),
            local.liquidationBonus
        );
    }
}
