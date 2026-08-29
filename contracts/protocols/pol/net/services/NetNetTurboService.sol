// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IMorpho} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {TurboRouter} from "@crane/contracts/protocols/pol/net/src/lending/TurboRouter.sol";

// tag::NetNetTurboService[]
/**
 * @title NetNetTurboService - Morpho authorization plus TurboRouter loop/unwind.
 * @author Crane
 * @dev Caller context is the token holder. One-time Morpho authorization of the router is required.
 */
library NetNetTurboService {
    // tag::AuthParams[]
    struct AuthParams {
        IMorpho morpho;
        address router;
        bool authorized;
    }
    // end::AuthParams[]

    // tag::TurboParams[]
    struct TurboParams {
        TurboRouter turboRouter;
        IERC20 wsNet;
        uint256 wsIn;
        uint256 borrowAssets;
        uint256 minWsFromLoop;
    }
    // end::TurboParams[]

    // tag::UnwindParams[]
    struct UnwindParams {
        TurboRouter turboRouter;
        uint256 repayShares;
        uint256 wsCollateralOut;
        uint256 minUsdgFromSale;
    }
    // end::UnwindParams[]

    // tag::_setMorphoAuthorization(AuthParams)[]
    /**
     * @notice Authorize `router` to manage the caller's Morpho positions.
     * @custom:signature _setMorphoAuthorization((address,address,bool))
     */
    function _setMorphoAuthorization(AuthParams memory p) internal {
        p.morpho.setAuthorization(p.router, p.authorized);
    }
    // end::_setMorphoAuthorization(AuthParams)[]

    // tag::_turbo(TurboParams)[]
    /**
     * @notice Loop: supply wsNET collateral and borrow USDG to buy more NET.
     * @custom:signature _turbo((address,uint256,uint256,uint256))
     */
    function _turbo(TurboParams memory p) internal {
        if (p.wsIn != 0) {
            p.wsNet.approve(address(p.turboRouter), p.wsIn);
        }
        p.turboRouter.turbo(p.wsIn, p.borrowAssets, p.minWsFromLoop);
    }
    // end::_turbo(TurboParams)[]

    // tag::_unwind(UnwindParams)[]
    /**
     * @notice Unwind: repay Morpho debt from a taxed sale of freed wsNET.
     * @custom:signature _unwind((address,uint256,uint256,uint256))
     */
    function _unwind(UnwindParams memory p) internal {
        p.turboRouter.unwind(p.repayShares, p.wsCollateralOut, p.minUsdgFromSale);
    }
    // end::_unwind(UnwindParams)[]
}
// end::NetNetTurboService[]
