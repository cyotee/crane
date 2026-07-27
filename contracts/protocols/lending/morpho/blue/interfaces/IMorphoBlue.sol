// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

// tag::IMorphoBlue[]
/**
 * @title IMorphoBlue
 * @author Crane
 * @notice Crane-facing re-export of Morpho Blue consumer interfaces and types.
 * @dev Prefer this path in Crane wrappers/tests; domain lives under `contracts/external/morpho/blue/`.
 */
import {
    Id,
    MarketParams,
    Position,
    Market,
    Authorization,
    Signature,
    IMorphoBase,
    IMorphoStaticTyping,
    IMorpho
} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";

import {IIrm} from "@crane/contracts/external/morpho/blue/interfaces/IIrm.sol";
import {IOracle} from "@crane/contracts/external/morpho/blue/interfaces/IOracle.sol";
import {IMorphoLiquidateCallback, IMorphoRepayCallback, IMorphoSupplyCallback, IMorphoSupplyCollateralCallback, IMorphoFlashLoanCallback} from "@crane/contracts/external/morpho/blue/interfaces/IMorphoCallbacks.sol";
// end::IMorphoBlue[]
