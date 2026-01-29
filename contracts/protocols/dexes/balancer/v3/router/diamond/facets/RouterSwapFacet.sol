// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IRouter.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/RouterTypes.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                              RouterSwapFacet                               */
/* -------------------------------------------------------------------------- */

/**
 * @title RouterSwapFacet
 * @notice Handles single-token swap operations for the Balancer V3 Router Diamond.
 * @dev Implements swap functions from IRouter interface.
 */
contract RouterSwapFacet is BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(RouterSwapFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        // This facet implements part of IRouter (swap functions only)
        interfaces = new bytes4[](1);
        interfaces[0] = type(IRouter).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](6);
        // External swap functions
        funcs[0] = this.swapSingleTokenExactIn.selector;
        funcs[1] = this.swapSingleTokenExactOut.selector;
        funcs[2] = this.querySwapSingleTokenExactIn.selector;
        funcs[3] = this.querySwapSingleTokenExactOut.selector;
        // Hook functions (called by Vault)
        funcs[4] = this.swapSingleTokenHook.selector;
        funcs[5] = this.querySwapHook.selector;
    }

    /// @inheritdoc IFacet
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    function swapSingleTokenExactIn(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountIn,
        uint256 minAmountOut,
        uint256 deadline,
        bool wethIsEth,
        bytes calldata userData
    ) external payable saveSender(msg.sender) returns (uint256) {
        return _unlockSwap(
            msg.sender, SwapKind.EXACT_IN, pool, tokenIn, tokenOut,
            exactAmountIn, minAmountOut, deadline, wethIsEth, userData
        );
    }

    function querySwapSingleTokenExactIn(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountIn,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256) {
        return _quoteSwap(
            msg.sender, SwapKind.EXACT_IN, pool, tokenIn, tokenOut,
            exactAmountIn, 0, BalancerV3RouterStorageRepo.MAX_AMOUNT, userData
        );
    }

    function swapSingleTokenExactOut(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountOut,
        uint256 maxAmountIn,
        uint256 deadline,
        bool wethIsEth,
        bytes calldata userData
    ) external payable saveSender(msg.sender) returns (uint256) {
        return _unlockSwap(
            msg.sender, SwapKind.EXACT_OUT, pool, tokenIn, tokenOut,
            exactAmountOut, maxAmountIn, deadline, wethIsEth, userData
        );
    }

    function querySwapSingleTokenExactOut(
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 exactAmountOut,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256) {
        return _quoteSwap(
            msg.sender, SwapKind.EXACT_OUT, pool, tokenIn, tokenOut,
            exactAmountOut, BalancerV3RouterStorageRepo.MAX_AMOUNT, type(uint256).max, userData
        );
    }

    /* ========================================================================== */
    /*                              HOOK FUNCTIONS                                */
    /* ========================================================================== */

    function swapSingleTokenHook(
        SwapSingleTokenHookParams calldata params
    ) external nonReentrant onlyVault returns (uint256) {
        return _swapSingleTokenHook(params);
    }

    function querySwapHook(
        SwapSingleTokenHookParams calldata params
    ) external nonReentrant onlyVault returns (uint256) {
        return _querySwapHook(params);
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _unlockSwap(
        address sender,
        SwapKind kind,
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountGiven,
        uint256 limit,
        uint256 deadline,
        bool wethIsEth,
        bytes memory userData
    ) internal returns (uint256) {
        SwapSingleTokenHookParams memory params = SwapSingleTokenHookParams({
            sender: sender,
            kind: kind,
            pool: pool,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountGiven: amountGiven,
            limit: limit,
            deadline: deadline,
            wethIsEth: wethIsEth,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(this.swapSingleTokenHook, params)
        );
        return abi.decode(result, (uint256));
    }

    function _quoteSwap(
        address sender,
        SwapKind kind,
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountGiven,
        uint256 limit,
        uint256 deadline,
        bytes memory userData
    ) internal returns (uint256) {
        SwapSingleTokenHookParams memory params = SwapSingleTokenHookParams({
            sender: sender,
            kind: kind,
            pool: pool,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountGiven: amountGiven,
            limit: limit,
            deadline: deadline,
            wethIsEth: false,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.querySwapHook, params)
        );
        return abi.decode(result, (uint256));
    }

    function _swapSingleTokenHook(
        SwapSingleTokenHookParams calldata params
    ) internal returns (uint256) {
        (uint256 amountCalculated, uint256 amountIn, uint256 amountOut) = _swapHook(params);
        _handleSwapTokens(params, amountIn, amountOut);
        return amountCalculated;
    }

    function _handleSwapTokens(
        SwapSingleTokenHookParams calldata params,
        uint256 amountIn,
        uint256 amountOut
    ) internal {
        bool isPrepaid = BalancerV3RouterStorageRepo._isPrepaid();
        IWETH weth = BalancerV3RouterStorageRepo._weth();
        IVault vault = BalancerV3RouterStorageRepo._vault();

        if (!isPrepaid || (params.wethIsEth && params.tokenIn == weth)) {
            _takeTokenIn(params.sender, params.tokenIn, amountIn, params.wethIsEth);
        } else {
            _handlePrepaidTokenIn(params, vault, amountIn);
        }

        _sendTokenOut(params.sender, params.tokenOut, amountOut, params.wethIsEth);

        if (params.tokenIn == weth) {
            _returnEth(params.sender);
        }
    }

    function _handlePrepaidTokenIn(
        SwapSingleTokenHookParams calldata params,
        IVault vault,
        uint256 amountIn
    ) internal {
        uint256 amountInHint = params.kind == SwapKind.EXACT_IN ? params.amountGiven : params.limit;

        uint256 tokenInCredit = vault.settle(params.tokenIn, amountInHint);
        if (tokenInCredit < amountInHint) {
            revert InsufficientPayment(params.tokenIn);
        }

        if (params.kind == SwapKind.EXACT_OUT) {
            _sendTokenOut(params.sender, params.tokenIn, tokenInCredit - amountIn, false);
        }
    }

    function _querySwapHook(SwapSingleTokenHookParams calldata params) internal returns (uint256) {
        (uint256 amountCalculated, , ) = _swapHook(params);
        return amountCalculated;
    }

    function _swapHook(
        SwapSingleTokenHookParams calldata params
    ) internal returns (uint256 amountCalculated, uint256 amountIn, uint256 amountOut) {
        if (block.timestamp > params.deadline) {
            revert SwapDeadline();
        }

        VaultSwapParams memory swapParams = VaultSwapParams({
            kind: params.kind,
            pool: params.pool,
            tokenIn: params.tokenIn,
            tokenOut: params.tokenOut,
            amountGivenRaw: params.amountGiven,
            limitRaw: params.limit,
            userData: params.userData
        });

        return BalancerV3RouterStorageRepo._vault().swap(swapParams);
    }
}
