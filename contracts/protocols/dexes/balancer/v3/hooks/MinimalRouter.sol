// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";

import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    AddLiquidityParams,
    RemoveLiquidityKind,
    RemoveLiquidityParams
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {RouterWethLib} from "@balancer-labs/v3-vault/contracts/lib/RouterWethLib.sol";
import {RouterCommon} from "@balancer-labs/v3-vault/contracts/RouterCommon.sol";

/* -------------------------------------------------------------------------- */
/*                              MinimalRouter                                 */
/* -------------------------------------------------------------------------- */

/**
 * @title MinimalRouter
 * @notice A minimal router implementation for testing hooks with proportional liquidity operations.
 * @dev This router supports only proportional add/remove liquidity operations,
 * which are sufficient for testing most hook functionality.
 *
 * Features:
 * - Proportional add liquidity with WETH/ETH handling
 * - Proportional remove liquidity with WETH/ETH unwrapping
 * - Permit2 integration for token approvals
 *
 * @custom:security-contact security@example.com
 */
contract MinimalRouter is RouterCommon {
    using Address for address payable;
    using RouterWethLib for IWETH;
    using SafeCast for *;

    /* ========================================================================== */
    /*                                   STRUCTS                                  */
    /* ========================================================================== */

    /**
     * @notice Parameters for the add liquidity hook.
     * @param sender Account originating the operation.
     * @param receiver Account to receive BPT.
     * @param pool The liquidity pool address.
     * @param maxAmountsIn Maximum amounts of each token to add.
     * @param minBptAmountOut Minimum BPT to receive.
     * @param kind Type of add liquidity operation.
     * @param wethIsEth If true, wrap/unwrap ETH to/from WETH.
     * @param userData Additional data for the pool.
     */
    struct ExtendedAddLiquidityHookParams {
        address sender;
        address receiver;
        address pool;
        uint256[] maxAmountsIn;
        uint256 minBptAmountOut;
        AddLiquidityKind kind;
        bool wethIsEth;
        bytes userData;
    }

    /**
     * @notice Parameters for the remove liquidity hook.
     * @param sender Account originating the operation.
     * @param receiver Account to receive tokens.
     * @param pool The liquidity pool address.
     * @param minAmountsOut Minimum amounts of each token to receive.
     * @param maxBptAmountIn Maximum BPT to burn.
     * @param kind Type of remove liquidity operation.
     * @param wethIsEth If true, unwrap WETH to ETH.
     * @param userData Additional data for the pool.
     */
    struct ExtendedRemoveLiquidityHookParams {
        address sender;
        address receiver;
        address pool;
        uint256[] minAmountsOut;
        uint256 maxBptAmountIn;
        RemoveLiquidityKind kind;
        bool wethIsEth;
        bytes userData;
    }

    /* ========================================================================== */
    /*                                 CONSTRUCTOR                                */
    /* ========================================================================== */

    /**
     * @notice Creates a new MinimalRouter.
     * @param vault The Balancer V3 Vault.
     * @param weth The WETH token address.
     * @param permit2 The Permit2 contract address.
     * @param routerVersion Version string for this router.
     */
    constructor(
        IVault vault,
        IWETH weth,
        IPermit2 permit2,
        string memory routerVersion
    ) RouterCommon(vault, weth, permit2, routerVersion) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /* ========================================================================== */
    /*                            EXTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    /**
     * @notice Adds liquidity proportionally to a pool.
     * @param pool The pool to add liquidity to.
     * @param maxAmountsIn Maximum amounts of each token to add.
     * @param exactBptAmountOut Exact amount of BPT to receive.
     * @param wethIsEth If true, wrap ETH to WETH.
     * @param userData Additional data for the pool.
     * @return amountsIn Actual amounts of tokens added.
     */
    function addLiquidityProportional(
        address pool,
        uint256[] memory maxAmountsIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable returns (uint256[] memory amountsIn) {
        return _addLiquidityProportional(
            pool,
            msg.sender,
            msg.sender,
            maxAmountsIn,
            exactBptAmountOut,
            wethIsEth,
            userData
        );
    }

    /**
     * @notice Removes liquidity proportionally from a pool.
     * @param pool The pool to remove liquidity from.
     * @param exactBptAmountIn Exact amount of BPT to burn.
     * @param minAmountsOut Minimum amounts of each token to receive.
     * @param wethIsEth If true, unwrap WETH to ETH.
     * @param userData Additional data for the pool.
     * @return amountsOut Actual amounts of tokens received.
     */
    function removeLiquidityProportional(
        address pool,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut,
        bool wethIsEth,
        bytes memory userData
    ) external returns (uint256[] memory amountsOut) {
        return _removeLiquidityProportional(
            pool,
            msg.sender,
            msg.sender,
            exactBptAmountIn,
            minAmountsOut,
            wethIsEth,
            userData
        );
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _addLiquidityProportional(
        address pool,
        address sender,
        address receiver,
        uint256[] memory maxAmountsIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) internal returns (uint256[] memory amountsIn) {
        (amountsIn, , ) = abi.decode(
            _vault.unlock(
                abi.encodeCall(
                    MinimalRouter.addLiquidityHook,
                    ExtendedAddLiquidityHookParams({
                        sender: sender,
                        receiver: receiver,
                        pool: pool,
                        maxAmountsIn: maxAmountsIn,
                        minBptAmountOut: exactBptAmountOut,
                        kind: AddLiquidityKind.PROPORTIONAL,
                        wethIsEth: wethIsEth,
                        userData: userData
                    })
                )
            ),
            (uint256[], uint256, bytes)
        );
    }

    /**
     * @notice Hook called by Vault during add liquidity.
     * @dev Only callable by the Vault.
     */
    function addLiquidityHook(
        ExtendedAddLiquidityHookParams calldata params
    )
        external
        nonReentrant
        onlyVault
        returns (uint256[] memory amountsIn, uint256 bptAmountOut, bytes memory returnData)
    {
        (amountsIn, bptAmountOut, returnData) = _vault.addLiquidity(
            AddLiquidityParams({
                pool: params.pool,
                to: params.receiver,
                maxAmountsIn: params.maxAmountsIn,
                minBptAmountOut: params.minBptAmountOut,
                kind: params.kind,
                userData: params.userData
            })
        );

        IERC20[] memory tokens = _vault.getPoolTokens(params.pool);

        for (uint256 i = 0; i < tokens.length; ++i) {
            IERC20 token = tokens[i];
            uint256 amountIn = amountsIn[i];

            if (amountIn == 0) {
                continue;
            }

            if (params.wethIsEth && address(token) == address(_weth)) {
                _weth.wrapEthAndSettle(_vault, amountIn);
            } else {
                _permit2.transferFrom(params.sender, address(_vault), amountIn.toUint160(), address(token));
                _vault.settle(token, amountIn);
            }
        }

        _returnEth(params.sender);
    }

    function _removeLiquidityProportional(
        address pool,
        address sender,
        address receiver,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut,
        bool wethIsEth,
        bytes memory userData
    ) internal returns (uint256[] memory amountsOut) {
        (, amountsOut, ) = abi.decode(
            _vault.unlock(
                abi.encodeCall(
                    MinimalRouter.removeLiquidityHook,
                    ExtendedRemoveLiquidityHookParams({
                        sender: sender,
                        receiver: receiver,
                        pool: pool,
                        minAmountsOut: minAmountsOut,
                        maxBptAmountIn: exactBptAmountIn,
                        kind: RemoveLiquidityKind.PROPORTIONAL,
                        wethIsEth: wethIsEth,
                        userData: userData
                    })
                )
            ),
            (uint256, uint256[], bytes)
        );
    }

    /**
     * @notice Hook called by Vault during remove liquidity.
     * @dev Only callable by the Vault.
     */
    function removeLiquidityHook(
        ExtendedRemoveLiquidityHookParams calldata params
    )
        external
        nonReentrant
        onlyVault
        returns (uint256 bptAmountIn, uint256[] memory amountsOut, bytes memory returnData)
    {
        (bptAmountIn, amountsOut, returnData) = _vault.removeLiquidity(
            RemoveLiquidityParams({
                pool: params.pool,
                from: params.sender,
                maxBptAmountIn: params.maxBptAmountIn,
                minAmountsOut: params.minAmountsOut,
                kind: params.kind,
                userData: params.userData
            })
        );

        IERC20[] memory tokens = _vault.getPoolTokens(params.pool);

        for (uint256 i = 0; i < tokens.length; ++i) {
            uint256 amountOut = amountsOut[i];

            if (amountOut == 0) {
                continue;
            }

            IERC20 token = tokens[i];

            if (params.wethIsEth && address(token) == address(_weth)) {
                _weth.unwrapWethAndTransferToSender(_vault, params.receiver, amountOut);
            } else {
                _vault.sendTo(token, params.receiver, amountOut);
            }
        }
    }
}
