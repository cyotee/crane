// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IVaultErrors} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import {ICompositeLiquidityRouter} from "@balancer-labs/v3-interfaces/contracts/vault/ICompositeLiquidityRouter.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/RouterTypes.sol";

import {EVMCallModeHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/EVMCallModeHelpers.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                       CompositeLiquidityERC4626Facet                       */
/* -------------------------------------------------------------------------- */

/**
 * @title CompositeLiquidityERC4626Facet
 * @notice Handles ERC4626 pool liquidity operations for the Balancer V3 Router Diamond.
 * @dev Implements add/remove liquidity for pools with ERC4626 wrapped tokens.
 *
 * Key features:
 * - Add liquidity with automatic wrapping of underlying tokens
 * - Remove liquidity with automatic unwrapping to underlying tokens
 * - Support for proportional and unbalanced operations
 */
contract CompositeLiquidityERC4626Facet is BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(CompositeLiquidityERC4626Facet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ICompositeLiquidityRouter).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](9);
        // ERC4626 add liquidity
        funcs[0] = this.addLiquidityUnbalancedToERC4626Pool.selector;
        funcs[1] = this.queryAddLiquidityUnbalancedToERC4626Pool.selector;
        funcs[2] = this.addLiquidityProportionalToERC4626Pool.selector;
        funcs[3] = this.queryAddLiquidityProportionalToERC4626Pool.selector;
        // ERC4626 remove liquidity
        funcs[4] = this.removeLiquidityProportionalFromERC4626Pool.selector;
        funcs[5] = this.queryRemoveLiquidityProportionalFromERC4626Pool.selector;
        // Hook functions
        funcs[6] = this.addLiquidityERC4626PoolUnbalancedHook.selector;
        funcs[7] = this.addLiquidityERC4626PoolProportionalHook.selector;
        funcs[8] = this.removeLiquidityERC4626PoolProportionalHook.selector;
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
    /*                                 STRUCTS                                    */
    /* ========================================================================== */

    /// @dev Context for processing tokens in ERC4626 operations
    struct ERC4626ProcessingContext {
        IVault vault;
        address sender;
        bool wethIsEth;
        bool isStaticCall;
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Add liquidity to an ERC4626 pool with unbalanced amounts.
     * @param pool The pool address
     * @param wrapUnderlying Array indicating which tokens to wrap
     * @param exactAmountsIn Exact amounts of underlying tokens to add
     * @param minBptAmountOut Minimum BPT to receive
     * @param wethIsEth Whether to treat WETH as ETH
     * @param userData Additional user data
     * @return bptAmountOut BPT received
     */
    function addLiquidityUnbalancedToERC4626Pool(
        address pool,
        bool[] memory wrapUnderlying,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256 bptAmountOut) {
        AddLiquidityHookParams memory params = AddLiquidityHookParams({
            sender: msg.sender,
            pool: pool,
            maxAmountsIn: exactAmountsIn,
            minBptAmountOut: minBptAmountOut,
            kind: AddLiquidityKind.UNBALANCED,
            wethIsEth: wethIsEth,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(this.addLiquidityERC4626PoolUnbalancedHook, (params, wrapUnderlying))
        );
        return abi.decode(result, (uint256));
    }

    /**
     * @notice Query add liquidity to an ERC4626 pool with unbalanced amounts.
     */
    function queryAddLiquidityUnbalancedToERC4626Pool(
        address pool,
        bool[] memory wrapUnderlying,
        uint256[] memory exactAmountsIn,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256 bptAmountOut) {
        AddLiquidityHookParams memory params = _buildQueryAddLiquidityParams(
            pool, exactAmountsIn, 0, AddLiquidityKind.UNBALANCED, userData
        );

        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.addLiquidityERC4626PoolUnbalancedHook, (params, wrapUnderlying))
        );
        return abi.decode(result, (uint256));
    }

    /**
     * @notice Add liquidity to an ERC4626 pool proportionally.
     */
    function addLiquidityProportionalToERC4626Pool(
        address pool,
        bool[] memory wrapUnderlying,
        uint256[] memory maxAmountsIn,
        uint256 exactBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256[] memory) {
        AddLiquidityHookParams memory params = AddLiquidityHookParams({
            sender: msg.sender,
            pool: pool,
            maxAmountsIn: maxAmountsIn,
            minBptAmountOut: exactBptAmountOut,
            kind: AddLiquidityKind.PROPORTIONAL,
            wethIsEth: wethIsEth,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(this.addLiquidityERC4626PoolProportionalHook, (params, wrapUnderlying))
        );
        return abi.decode(result, (uint256[]));
    }

    /**
     * @notice Query add liquidity to an ERC4626 pool proportionally.
     */
    function queryAddLiquidityProportionalToERC4626Pool(
        address pool,
        bool[] memory wrapUnderlying,
        uint256 exactBptAmountOut,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256[] memory) {
        AddLiquidityHookParams memory params = _buildQueryAddLiquidityParams(
            pool, new uint256[](0), exactBptAmountOut, AddLiquidityKind.PROPORTIONAL, userData
        );

        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.addLiquidityERC4626PoolProportionalHook, (params, wrapUnderlying))
        );
        return abi.decode(result, (uint256[]));
    }

    /**
     * @notice Remove liquidity from an ERC4626 pool proportionally.
     */
    function removeLiquidityProportionalFromERC4626Pool(
        address pool,
        bool[] memory unwrapWrapped,
        uint256 exactBptAmountIn,
        uint256[] memory minAmountsOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256[] memory) {
        RemoveLiquidityHookParams memory params = RemoveLiquidityHookParams({
            sender: msg.sender,
            pool: pool,
            minAmountsOut: minAmountsOut,
            maxBptAmountIn: exactBptAmountIn,
            kind: RemoveLiquidityKind.PROPORTIONAL,
            wethIsEth: wethIsEth,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(this.removeLiquidityERC4626PoolProportionalHook, (params, unwrapWrapped))
        );
        return abi.decode(result, (uint256[]));
    }

    /**
     * @notice Query remove liquidity from an ERC4626 pool proportionally.
     */
    function queryRemoveLiquidityProportionalFromERC4626Pool(
        address pool,
        bool[] memory unwrapWrapped,
        uint256 exactBptAmountIn,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256[] memory) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        IERC20[] memory erc4626PoolTokens = vault.getPoolTokens(pool);

        RemoveLiquidityHookParams memory params = RemoveLiquidityHookParams({
            sender: address(this),
            pool: pool,
            minAmountsOut: new uint256[](erc4626PoolTokens.length),
            maxBptAmountIn: exactBptAmountIn,
            kind: RemoveLiquidityKind.PROPORTIONAL,
            wethIsEth: false,
            userData: userData
        });

        bytes memory result = vault.quote(
            abi.encodeCall(this.removeLiquidityERC4626PoolProportionalHook, (params, unwrapWrapped))
        );
        return abi.decode(result, (uint256[]));
    }

    /* ========================================================================== */
    /*                              HOOK FUNCTIONS                                */
    /* ========================================================================== */

    /**
     * @notice Hook for unbalanced add liquidity to ERC4626 pools.
     */
    function addLiquidityERC4626PoolUnbalancedHook(
        AddLiquidityHookParams calldata params,
        bool[] calldata wrapUnderlying
    ) external nonReentrant onlyVault returns (uint256 bptAmountOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        (IERC20[] memory poolTokens, ) = _validateERC4626HookParams(
            vault, params.pool, params.maxAmountsIn.length, wrapUnderlying.length
        );

        ERC4626ProcessingContext memory ctx = ERC4626ProcessingContext({
            vault: vault,
            sender: params.sender,
            wethIsEth: params.wethIsEth,
            isStaticCall: EVMCallModeHelpers.isStaticCall()
        });

        uint256[] memory amountsIn = _processUnbalancedTokensIn(ctx, poolTokens, params.maxAmountsIn, wrapUnderlying);

        (, bptAmountOut, ) = vault.addLiquidity(_buildAddLiquidityParams(params, amountsIn, params.sender));
        _returnEth(params.sender);
    }

    /**
     * @notice Hook for proportional add liquidity to ERC4626 pools.
     */
    function addLiquidityERC4626PoolProportionalHook(
        AddLiquidityHookParams calldata params,
        bool[] calldata wrapUnderlying
    ) external nonReentrant onlyVault returns (uint256[] memory amountsIn) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        (IERC20[] memory poolTokens, ) = _validateERC4626HookParams(
            vault, params.pool, params.maxAmountsIn.length, wrapUnderlying.length
        );

        uint256[] memory maxAmounts = _maxTokenLimits(vault, params.pool);
        (uint256[] memory actualAmountsIn, , ) = vault.addLiquidity(
            _buildAddLiquidityParams(params, maxAmounts, params.sender)
        );

        ERC4626ProcessingContext memory ctx = ERC4626ProcessingContext({
            vault: vault,
            sender: params.sender,
            wethIsEth: params.wethIsEth,
            isStaticCall: EVMCallModeHelpers.isStaticCall()
        });

        amountsIn = _processProportionalTokensIn(ctx, poolTokens, actualAmountsIn, wrapUnderlying, params.maxAmountsIn);
        _returnEth(params.sender);
    }

    /**
     * @notice Hook for proportional remove liquidity from ERC4626 pools.
     */
    function removeLiquidityERC4626PoolProportionalHook(
        RemoveLiquidityHookParams calldata params,
        bool[] calldata unwrapWrapped
    ) external nonReentrant onlyVault returns (uint256[] memory amountsOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        (IERC20[] memory poolTokens, uint256 numTokens) = _validateERC4626HookParams(
            vault, params.pool, params.minAmountsOut.length, unwrapWrapped.length
        );

        uint256[] memory actualAmountsOut = _removeLiquidityFromPool(vault, params, numTokens);

        ERC4626ProcessingContext memory ctx = ERC4626ProcessingContext({
            vault: vault,
            sender: params.sender,
            wethIsEth: params.wethIsEth,
            isStaticCall: EVMCallModeHelpers.isStaticCall()
        });

        amountsOut = _processTokensOut(ctx, poolTokens, actualAmountsOut, unwrapWrapped, params.minAmountsOut);
    }

    function _removeLiquidityFromPool(
        IVault vault,
        RemoveLiquidityHookParams calldata params,
        uint256 numTokens
    ) internal returns (uint256[] memory actualAmountsOut) {
        if (vault.isPoolInRecoveryMode(params.pool)) {
            actualAmountsOut = vault.removeLiquidityRecovery(
                params.pool, params.sender, params.maxBptAmountIn, params.minAmountsOut
            );
        } else {
            (, actualAmountsOut, ) = vault.removeLiquidity(_buildRemoveLiquidityParams(params, numTokens));
        }
    }

    function _processUnbalancedTokensIn(
        ERC4626ProcessingContext memory ctx,
        IERC20[] memory poolTokens,
        uint256[] calldata maxAmountsIn,
        bool[] calldata wrapUnderlying
    ) internal returns (uint256[] memory amountsIn) {
        amountsIn = new uint256[](poolTokens.length);
        for (uint256 i = 0; i < poolTokens.length; ++i) {
            amountsIn[i] = _processTokenInExactIn(ctx, address(poolTokens[i]), maxAmountsIn[i], wrapUnderlying[i]);
        }
    }

    function _processProportionalTokensIn(
        ERC4626ProcessingContext memory ctx,
        IERC20[] memory poolTokens,
        uint256[] memory actualAmountsIn,
        bool[] calldata wrapUnderlying,
        uint256[] calldata maxAmountsIn
    ) internal returns (uint256[] memory amountsIn) {
        amountsIn = new uint256[](poolTokens.length);
        for (uint256 i = 0; i < poolTokens.length; ++i) {
            amountsIn[i] = _processTokenInExactOut(
                ctx, address(poolTokens[i]), actualAmountsIn[i], wrapUnderlying[i], maxAmountsIn[i]
            );
        }
    }

    function _processTokensOut(
        ERC4626ProcessingContext memory ctx,
        IERC20[] memory poolTokens,
        uint256[] memory actualAmountsOut,
        bool[] calldata unwrapWrapped,
        uint256[] calldata minAmountsOut
    ) internal returns (uint256[] memory amountsOut) {
        amountsOut = new uint256[](poolTokens.length);
        for (uint256 i = 0; i < poolTokens.length; ++i) {
            amountsOut[i] = _processTokenOutExactIn(
                ctx, address(poolTokens[i]), actualAmountsOut[i], unwrapWrapped[i], minAmountsOut[i]
            );
        }
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _validateERC4626HookParams(
        IVault vault,
        address pool,
        uint256 amountsLength,
        uint256 wrapLength
    ) internal view returns (IERC20[] memory poolTokens, uint256 numTokens) {
        poolTokens = vault.getPoolTokens(pool);
        numTokens = poolTokens.length;
        InputHelpers.ensureInputLengthMatch(numTokens, amountsLength, wrapLength);
    }

    function _buildAddLiquidityParams(
        AddLiquidityHookParams calldata hookParams,
        uint256[] memory maxAmountsIn,
        address sender
    ) internal pure returns (AddLiquidityParams memory) {
        return AddLiquidityParams({
            pool: hookParams.pool,
            to: sender,
            maxAmountsIn: maxAmountsIn,
            minBptAmountOut: hookParams.minBptAmountOut,
            kind: hookParams.kind,
            userData: hookParams.userData
        });
    }

    function _buildRemoveLiquidityParams(
        RemoveLiquidityHookParams calldata hookParams,
        uint256 numTokens
    ) internal pure returns (RemoveLiquidityParams memory) {
        return RemoveLiquidityParams({
            pool: hookParams.pool,
            from: hookParams.sender,
            maxBptAmountIn: hookParams.maxBptAmountIn,
            minAmountsOut: new uint256[](numTokens),
            kind: hookParams.kind,
            userData: hookParams.userData
        });
    }

    function _buildQueryAddLiquidityParams(
        address pool,
        uint256[] memory maxOrExactAmountsIn,
        uint256 minOrExactBpt,
        AddLiquidityKind kind,
        bytes memory userData
    ) internal view returns (AddLiquidityHookParams memory) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        uint256[] memory resolvedMaxAmounts;
        uint256 resolvedBptAmount;

        if (kind == AddLiquidityKind.PROPORTIONAL) {
            resolvedMaxAmounts = _maxTokenLimits(vault, pool);
            resolvedBptAmount = minOrExactBpt;
        } else if (kind == AddLiquidityKind.UNBALANCED) {
            resolvedMaxAmounts = maxOrExactAmountsIn;
        } else {
            revert IVaultErrors.InvalidAddLiquidityKind();
        }

        return AddLiquidityHookParams({
            sender: address(this),
            pool: pool,
            maxAmountsIn: resolvedMaxAmounts,
            minBptAmountOut: resolvedBptAmount,
            kind: kind,
            wethIsEth: false,
            userData: userData
        });
    }

    function _maxTokenLimits(IVault vault, address pool) internal view returns (uint256[] memory) {
        IERC20[] memory tokens = vault.getPoolTokens(pool);
        uint256[] memory limits = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; ++i) {
            limits[i] = BalancerV3RouterStorageRepo.MAX_AMOUNT;
        }
        return limits;
    }

    function _processTokenInExactIn(
        ERC4626ProcessingContext memory ctx,
        address token,
        uint256 amountIn,
        bool needToWrap
    ) internal returns (uint256 actualAmountIn) {
        address settlementToken = needToWrap ? ctx.vault.getERC4626BufferAsset(IERC4626(token)) : token;
        if (needToWrap && settlementToken == address(0)) {
            revert IVaultErrors.BufferNotInitialized(IERC4626(token));
        }

        if (!ctx.isStaticCall) {
            _takeTokenIn(ctx.sender, IERC20(settlementToken), amountIn, ctx.wethIsEth);
        }

        if (needToWrap && amountIn > 0) {
            (, , actualAmountIn) = ctx.vault.erc4626BufferWrapOrUnwrap(
                BufferWrapOrUnwrapParams({
                    kind: SwapKind.EXACT_IN,
                    direction: WrappingDirection.WRAP,
                    wrappedToken: IERC4626(token),
                    amountGivenRaw: amountIn,
                    limitRaw: 0
                })
            );
        } else {
            actualAmountIn = amountIn;
        }
    }

    function _processTokenInExactOut(
        ERC4626ProcessingContext memory ctx,
        address token,
        uint256 amountIn,
        bool needToWrap,
        uint256 maxAmountIn
    ) internal returns (uint256 actualAmountIn) {
        IERC20 settlementToken = needToWrap
            ? IERC20(ctx.vault.getERC4626BufferAsset(IERC4626(token)))
            : IERC20(token);

        if (needToWrap && address(settlementToken) == address(0)) {
            revert IVaultErrors.BufferNotInitialized(IERC4626(token));
        }

        if (!ctx.isStaticCall) {
            _takeTokenIn(ctx.sender, settlementToken, maxAmountIn, ctx.wethIsEth);
        }

        if (amountIn > 0) {
            if (needToWrap) {
                (, actualAmountIn, ) = ctx.vault.erc4626BufferWrapOrUnwrap(
                    BufferWrapOrUnwrapParams({
                        kind: SwapKind.EXACT_OUT,
                        direction: WrappingDirection.WRAP,
                        wrappedToken: IERC4626(token),
                        amountGivenRaw: amountIn,
                        limitRaw: maxAmountIn
                    })
                );
            } else {
                actualAmountIn = amountIn;
            }
        }

        if (actualAmountIn > maxAmountIn) {
            revert IVaultErrors.AmountInAboveMax(settlementToken, actualAmountIn, maxAmountIn);
        }

        if (!ctx.isStaticCall) {
            _sendTokenOut(ctx.sender, settlementToken, maxAmountIn - actualAmountIn, ctx.wethIsEth);
        }
    }

    function _processTokenOutExactIn(
        ERC4626ProcessingContext memory ctx,
        address token,
        uint256 amountOut,
        bool needToUnwrap,
        uint256 minAmountOut
    ) internal returns (uint256 actualAmountOut) {
        IERC20 tokenOut;

        if (needToUnwrap) {
            IERC4626 wrappedToken = IERC4626(token);
            IERC20 underlyingToken = IERC20(ctx.vault.getERC4626BufferAsset(wrappedToken));
            tokenOut = underlyingToken;

            if (address(underlyingToken) == address(0)) {
                revert IVaultErrors.BufferNotInitialized(wrappedToken);
            }

            if (amountOut > 0) {
                (, , actualAmountOut) = ctx.vault.erc4626BufferWrapOrUnwrap(
                    BufferWrapOrUnwrapParams({
                        kind: SwapKind.EXACT_IN,
                        direction: WrappingDirection.UNWRAP,
                        wrappedToken: wrappedToken,
                        amountGivenRaw: amountOut,
                        limitRaw: minAmountOut
                    })
                );

                if (!ctx.isStaticCall) {
                    _sendTokenOut(ctx.sender, underlyingToken, actualAmountOut, ctx.wethIsEth);
                }
            }
        } else {
            actualAmountOut = amountOut;
            tokenOut = IERC20(token);

            if (!ctx.isStaticCall) {
                _sendTokenOut(ctx.sender, tokenOut, actualAmountOut, ctx.wethIsEth);
            }
        }

        if (actualAmountOut < minAmountOut) {
            revert IVaultErrors.AmountOutBelowMin(tokenOut, actualAmountOut, minAmountOut);
        }
    }
}
