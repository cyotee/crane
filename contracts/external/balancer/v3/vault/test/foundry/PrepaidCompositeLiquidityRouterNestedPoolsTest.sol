// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";

import { ICompositeLiquidityRouter } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ICompositeLiquidityRouter.sol";
import { IVersion } from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IVersion.sol";

import { CompositeLiquidityRouterNestedPoolsTest } from "./CompositeLiquidityRouterNestedPools.t.sol";

contract PrepaidCompositeLiquidityRouterNestedPoolsTest is CompositeLiquidityRouterNestedPoolsTest {
    // Virtual function
    function _addLiquidityUnbalancedNestedPool(
        address pool,
        address[] memory tokensIn,
        uint256[] memory exactAmountsIn,
        address[] memory tokensToWrap,
        uint256 minBptAmountOut,
        uint256 ethValue,
        bool wethIsEth,
        bytes memory userData,
        bytes memory expectedError
    ) internal override returns (uint256) {
        for (uint256 i = 0; i < tokensIn.length; i++) {
            if (exactAmountsIn[i] == 0) {
                continue;
            }

            if (wethIsEth && tokensIn[i] == address(weth)) {
                continue;
            }

            IERC20(tokensIn[i]).transfer(address(vault), exactAmountsIn[i]);
        }

        if (expectedError.length > 0) {
            vm.expectRevert(expectedError);
        }

        return
            prepaidCompositeLiquidityRouter.addLiquidityUnbalancedNestedPool{ value: ethValue }(
                pool,
                tokensIn,
                exactAmountsIn,
                tokensToWrap,
                minBptAmountOut,
                wethIsEth,
                userData
            );
    }

    function _removeLiquidityProportionalNestedPool(
        address pool,
        uint256 exactBptAmountIn,
        address[] memory tokensOut,
        uint256[] memory minAmountsOut,
        address[] memory tokensToUnwrap,
        bool wethIsEth,
        bytes memory userData,
        bytes memory expectedError
    ) internal override returns (uint256[] memory amountsOut) {
        IERC20(pool).approve(address(prepaidCompositeLiquidityRouter), exactBptAmountIn);

        if (expectedError.length > 0) {
            vm.expectRevert(expectedError);
        }

        return
            prepaidCompositeLiquidityRouter.removeLiquidityProportionalNestedPool(
                pool,
                exactBptAmountIn,
                tokensOut,
                minAmountsOut,
                tokensToUnwrap,
                wethIsEth,
                userData
            );
    }
}
