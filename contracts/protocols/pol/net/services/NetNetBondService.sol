// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IBondDepository} from "@crane/contracts/protocols/pol/net/src/interfaces/IBondDepository.sol";
import {IInverseBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IInverseBond.sol";
import {IPremiumSeller} from "@crane/contracts/protocols/pol/net/src/interfaces/IPremiumSeller.sol";
import {IPTEAM} from "@crane/contracts/protocols/pol/net/src/interfaces/IPTEAM.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";

// tag::NetNetBondService[]
/**
 * @title NetNetBondService - BondDepository, InverseBond, PremiumSeller, and pTEAM helpers.
 * @author Crane
 * @dev Caller context is the token holder. P0 tests use `marketId == 0`.
 */
library NetNetBondService {
    // tag::DepositParams[]
    struct DepositParams {
        IBondDepository bondDepository;
        IERC20 quote;
        uint256 marketId;
        uint256 amount;
        uint256 maxPriceWad;
        address to;
    }
    // end::DepositParams[]

    // tag::RedeemParams[]
    struct RedeemParams {
        IBondDepository bondDepository;
        address to;
    }
    // end::RedeemParams[]

    // tag::InverseSwapParams[]
    struct InverseSwapParams {
        IInverseBond inverseBond;
        INET net;
        uint256 netAmount;
        uint256 minUsdgOutRaw;
    }
    // end::InverseSwapParams[]

    // tag::PremiumExecuteParams[]
    struct PremiumExecuteParams {
        IPremiumSeller premiumSeller;
        uint256 minUsdgOutRaw;
    }
    // end::PremiumExecuteParams[]

    // tag::PTeamExerciseParams[]
    struct PTeamExerciseParams {
        IPTEAM pteam;
        IERC20 usdg;
        address treasury;
        uint256 netAmount;
        uint256 usdgPayRaw;
    }
    // end::PTeamExerciseParams[]

    // tag::_deposit(DepositParams)[]
    /**
     * @notice Deposit quote into BondDepository (P0: market 0 USDG).
     * @custom:signature _deposit((address,address,uint256,uint256,uint256,address))
     */
    function _deposit(DepositParams memory p) internal returns (uint256 noteId, uint256 payout) {
        p.quote.approve(address(p.bondDepository), p.amount);
        return p.bondDepository.deposit(p.marketId, p.amount, p.maxPriceWad, p.to);
    }
    // end::_deposit(DepositParams)[]

    // tag::_redeem(RedeemParams)[]
    /**
     * @notice Redeem vested NET from BondDepository notes.
     * @custom:signature _redeem((address,address))
     */
    function _redeem(RedeemParams memory p) internal returns (uint256) {
        return p.bondDepository.redeem(p.to);
    }
    // end::_redeem(RedeemParams)[]

    // tag::_inverseSwap(InverseSwapParams)[]
    /**
     * @notice Sell NET to InverseBond at the backing-minus-spread bid.
     * @custom:signature _inverseSwap((address,address,uint256,uint256))
     */
    function _inverseSwap(InverseSwapParams memory p) internal returns (uint256) {
        p.net.approve(address(p.inverseBond), p.netAmount);
        return p.inverseBond.swap(p.netAmount, p.minUsdgOutRaw);
    }
    // end::_inverseSwap(InverseSwapParams)[]

    // tag::_premiumExecute(PremiumExecuteParams)[]
    /**
     * @notice Permissionless PremiumSeller clip sale.
     * @custom:signature _premiumExecute((address,uint256))
     */
    function _premiumExecute(PremiumExecuteParams memory p) internal returns (uint256 netSold, uint256 usdgOutRaw) {
        return p.premiumSeller.execute(p.minUsdgOutRaw);
    }
    // end::_premiumExecute(PremiumExecuteParams)[]

    // tag::_exercisePTeam(PTeamExerciseParams)[]
    /**
     * @notice Exercise pTEAM at 1 USDG per NET, paid into Treasury.
     * @custom:signature _exercisePTeam((address,address,address,uint256,uint256))
     */
    function _exercisePTeam(PTeamExerciseParams memory p) internal {
        p.usdg.approve(address(p.pteam), p.usdgPayRaw);
        p.pteam.exercise(p.netAmount);
    }
    // end::_exercisePTeam(PTeamExerciseParams)[]
}
// end::NetNetBondService[]
