// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Vm} from "forge-std/Vm.sol";
import {console} from "forge-std/console.sol";

import {
    IMorpho,
    Id,
    MarketParams,
    Market,
    Position
} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {MarketParamsLib} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";

// tag::Behavior_IMorpho[]
/**
 * @title Behavior_IMorpho
 * @notice Validation helpers for consumer-facing Morpho Blue reads.
 * @dev isValid_* pattern for declaration tests; exact market/position equality.
 */
library Behavior_IMorpho {
    using MarketParamsLib for MarketParams;

    address constant VM_ADDRESS = address(uint160(uint256(keccak256("hevm cheat code"))));
    Vm constant vm = Vm(VM_ADDRESS);

    function _Behavior_IMorphoName() internal pure returns (string memory) {
        return type(Behavior_IMorpho).name;
    }

    // tag::isValid_IMorpho_market[]
    function isValid_IMorpho_market(IMorpho subject, Id id, Market memory expected, Market memory actual)
        internal
        pure
        returns (bool valid)
    {
        valid = expected.totalSupplyAssets == actual.totalSupplyAssets
            && expected.totalSupplyShares == actual.totalSupplyShares
            && expected.totalBorrowAssets == actual.totalBorrowAssets
            && expected.totalBorrowShares == actual.totalBorrowShares
            && expected.fee == actual.fee;
        // lastUpdate may advance independently; callers pass post-op snapshots for equality.
        valid = valid && expected.lastUpdate == actual.lastUpdate;
        if (!valid) {
            // Silence unused when pure path fails — caller should assertEq for details.
            subject;
            id;
        }
    }
    // end::isValid_IMorpho_market[]

    // tag::isValid_IMorpho_position[]
    function isValid_IMorpho_position(
        IMorpho subject,
        Id id,
        address user,
        Position memory expected,
        Position memory actual
    ) internal pure returns (bool valid) {
        valid = expected.supplyShares == actual.supplyShares && expected.borrowShares == actual.borrowShares
            && expected.collateral == actual.collateral;
        if (!valid) {
            subject;
            id;
            user;
        }
    }
    // end::isValid_IMorpho_position[]

    // tag::isValid_IMorpho_idToMarketParams[]
    function isValid_IMorpho_idToMarketParams(
        IMorpho subject,
        Id id,
        MarketParams memory expected,
        MarketParams memory actual
    ) internal pure returns (bool valid) {
        valid = expected.loanToken == actual.loanToken && expected.collateralToken == actual.collateralToken
            && expected.oracle == actual.oracle && expected.irm == actual.irm && expected.lltv == actual.lltv;
        if (!valid) {
            subject;
            id;
        }
    }
    // end::isValid_IMorpho_idToMarketParams[]

    // tag::areEqual_markets[]
    /// @notice Exact equality of two market structs (for live vs local parity).
    function areEqual_markets(Market memory a, Market memory b) internal pure returns (bool) {
        return a.totalSupplyAssets == b.totalSupplyAssets && a.totalSupplyShares == b.totalSupplyShares
            && a.totalBorrowAssets == b.totalBorrowAssets && a.totalBorrowShares == b.totalBorrowShares
            && a.fee == b.fee;
    }
    // end::areEqual_markets[]

    // tag::areEqual_positions[]
    function areEqual_positions(Position memory a, Position memory b) internal pure returns (bool) {
        return a.supplyShares == b.supplyShares && a.borrowShares == b.borrowShares && a.collateral == b.collateral;
    }
    // end::areEqual_positions[]
}
// end::Behavior_IMorpho[]
