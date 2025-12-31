// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {PoolSwapParams, Rounding, SwapKind} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
// import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
// import { BetterBalancerV3PoolTokenStorage } from "contracts/crane/protocols/dexes/balancer/v3/vault/utils/BetterBalancerV3PoolTokenStorage.sol";
import {ERC4626AwareStorage} from "contracts/crane/token/ERC20/extensions/utils/ERC4626AwareStorage.sol";
import {BalancerV3PoolFacet} from "contracts/crane/protocols/dexes/balancer/v3/vault/BalancerV3PoolFacet.sol";
import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";

contract BalancerV3ERC4626AdaptorPoolFacet is ERC4626AwareStorage, BalancerV3PoolFacet {
    constructor(CREATE3InitData memory create3InitData_) Create3AwareContract(create3InitData_) {}

    function computeInvariant(
        uint256[] memory balancesLiveScaled18,
        Rounding // rounding
    )
        public
        view
        virtual
        override
        returns (uint256 invariant)
    {
        return balancesLiveScaled18[_balV3IndexOfToken(address(_wrapper()))];
    }

    function computeBalance(
        uint256[] memory balancesLiveScaled18,
        uint256 tokenInIndex,
        uint256 // invariantRatio
    )
        public
        view
        virtual
        override
        returns (uint256 newBalance)
    {
        if (tokenInIndex == _balV3IndexOfToken(address(_wrapper()))) {
            // return balancesLiveScaled18[tokenInIndex].mulDown(invariantRatio);
            return balancesLiveScaled18[tokenInIndex];
        } else {
            return 0;
        }
    }

    function onSwap(PoolSwapParams calldata params) public virtual override returns (uint256 amountCalculatedScaled18) {
        IERC4626 wrapper = _wrapper();
        IERC20 underlying = _underlying();
        address tokenIn = address(_tokenOfBalV3Index(params.indexIn));
        address tokenOut = address(_tokenOfBalV3Index(params.indexOut));

        // Check swap orientation.
        if (params.kind == SwapKind.EXACT_IN) {
            // Underlying as token in indicates a deposit.
            if (tokenIn == address(underlying)) {
                // params.amountGivenScaled18 is amount of underlying token to deposit.
                // Quote a deposit of params.amountGivenScaled18 underlying tokens.
                return wrapper.previewDeposit(params.amountGivenScaled18);
            }
            // Wrapper as token in indicates a redemption.
            else if (tokenIn == address(wrapper)) {
                // params.amountGivenScaled18 is amount of wrapper shares to redeem.
                // Quote a redemption of params.amountGivenScaled18 wrapper shares.
                return wrapper.previewRedeem(params.amountGivenScaled18);
            }
        } else if (params.kind == SwapKind.EXACT_OUT) {
            // Underlying as token out indicates a withdrawal.
            if (tokenOut == address(underlying)) {
                // params.amountGivenScaled18 is amount of underlying token to withdraw.
                // Quote wrapper shares needed to withdraw params.amountGivenScaled18 underlying tokens.
                return wrapper.previewWithdraw(params.amountGivenScaled18);
            }
            // Wrapper as token out indicates a mint.
            else if (tokenOut == address(wrapper)) {
                // params.amountGivenScaled18 is amount of underlying token to mint.
                // Quote underlying token needed to mint params.amountGivenScaled18 wrapper shares.
                return wrapper.previewMint(params.amountGivenScaled18);
            }
        }
    }
}
