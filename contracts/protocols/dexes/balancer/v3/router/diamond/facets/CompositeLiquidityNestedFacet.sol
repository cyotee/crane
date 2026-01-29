// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVaultErrors} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultErrors.sol";
import {
    ICompositeLiquidityRouterErrors
} from "@balancer-labs/v3-interfaces/contracts/vault/ICompositeLiquidityRouterErrors.sol";
import {ICompositeLiquidityRouter} from "@balancer-labs/v3-interfaces/contracts/vault/ICompositeLiquidityRouter.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/RouterTypes.sol";

import {EVMCallModeHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/EVMCallModeHelpers.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";
import {
    TransientEnumerableSet
} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/TransientEnumerableSet.sol";
import {
    TransientStorageHelpers,
    AddressToUintMappingSlot
} from "@balancer-labs/v3-solidity-utils/contracts/helpers/TransientStorageHelpers.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3BatchRouterStorageRepo} from "../BalancerV3BatchRouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                      CompositeLiquidityNestedFacet                         */
/* -------------------------------------------------------------------------- */

/**
 * @title CompositeLiquidityNestedFacet
 * @notice Handles nested pool liquidity operations for the Balancer V3 Router Diamond.
 * @dev Implements add/remove liquidity for pools containing other pool tokens (BPT).
 *
 * Key features:
 * - Add liquidity to nested pool structures
 * - Remove liquidity with recursive unwrapping of child pools
 * - Token type detection (ERC20, BPT, ERC4626)
 */
contract CompositeLiquidityNestedFacet is BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(CompositeLiquidityNestedFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ICompositeLiquidityRouter).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](6);
        // Nested pool add liquidity
        funcs[0] = this.addLiquidityUnbalancedNestedPool.selector;
        funcs[1] = this.queryAddLiquidityUnbalancedNestedPool.selector;
        // Nested pool remove liquidity
        funcs[2] = this.removeLiquidityProportionalNestedPool.selector;
        funcs[3] = this.queryRemoveLiquidityProportionalNestedPool.selector;
        // Hook functions
        funcs[4] = this.addLiquidityUnbalancedNestedPoolHook.selector;
        funcs[5] = this.removeLiquidityProportionalNestedPoolHook.selector;
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
    using TransientEnumerableSet for TransientEnumerableSet.AddressSet;
    using TransientStorageHelpers for *;

    /* ========================================================================== */
    /*                                 CONSTANTS                                  */
    /* ========================================================================== */

    /// @dev Token types for nested pool handling
    enum CompositeTokenType {
        ERC20,
        BPT,
        ERC4626
    }

    /// @dev Transient storage slot for tracking processed tokens during nested operations
    bytes32 private constant PROCESSED_TOKENS_IN_SLOT =
        0xa4e2f1f3d8b16c89b88d35f5a8f7b5f6a7b8c9d0e1f2a3b4c5d6e7f8091a3000;

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Add liquidity to a nested pool structure.
     * @dev Traverses child pools and adds liquidity bottom-up.
     */
    function addLiquidityUnbalancedNestedPool(
        address parentPool,
        address[] memory tokensIn,
        uint256[] memory exactAmountsIn,
        address[] memory tokensToWrap,
        uint256 minBptAmountOut,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256) {
        AddLiquidityHookParams memory params = AddLiquidityHookParams({
            pool: parentPool,
            sender: msg.sender,
            maxAmountsIn: exactAmountsIn,
            minBptAmountOut: minBptAmountOut,
            kind: AddLiquidityKind.UNBALANCED,
            wethIsEth: wethIsEth,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(this.addLiquidityUnbalancedNestedPoolHook, (params, tokensIn, tokensToWrap))
        );
        return abi.decode(result, (uint256));
    }

    /**
     * @notice Query add liquidity to a nested pool structure.
     */
    function queryAddLiquidityUnbalancedNestedPool(
        address parentPool,
        address[] memory tokensIn,
        uint256[] memory exactAmountsIn,
        address[] memory tokensToWrap,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256) {
        AddLiquidityHookParams memory params = AddLiquidityHookParams({
            pool: parentPool,
            sender: address(this),
            maxAmountsIn: exactAmountsIn,
            minBptAmountOut: 0,
            kind: AddLiquidityKind.UNBALANCED,
            wethIsEth: false,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.addLiquidityUnbalancedNestedPoolHook, (params, tokensIn, tokensToWrap))
        );
        return abi.decode(result, (uint256));
    }

    /**
     * @notice Remove liquidity from a nested pool structure proportionally.
     */
    function removeLiquidityProportionalNestedPool(
        address parentPool,
        uint256 exactBptAmountIn,
        address[] memory tokensOut,
        uint256[] memory minAmountsOut,
        address[] memory tokensToUnwrap,
        bool wethIsEth,
        bytes memory userData
    ) external payable saveSender(msg.sender) returns (uint256[] memory amountsOut) {
        RemoveLiquidityHookParams memory params = RemoveLiquidityHookParams({
            sender: msg.sender,
            pool: parentPool,
            minAmountsOut: minAmountsOut,
            maxBptAmountIn: exactBptAmountIn,
            kind: RemoveLiquidityKind.PROPORTIONAL,
            wethIsEth: wethIsEth,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(this.removeLiquidityProportionalNestedPoolHook, (params, tokensOut, tokensToUnwrap))
        );
        return abi.decode(result, (uint256[]));
    }

    /**
     * @notice Query remove liquidity from a nested pool structure.
     */
    function queryRemoveLiquidityProportionalNestedPool(
        address parentPool,
        uint256 exactBptAmountIn,
        address[] memory tokensOut,
        address[] memory tokensToUnwrap,
        address sender,
        bytes memory userData
    ) external saveSender(sender) returns (uint256[] memory amountsOut) {
        RemoveLiquidityHookParams memory params = RemoveLiquidityHookParams({
            sender: address(this),
            pool: parentPool,
            minAmountsOut: new uint256[](tokensOut.length),
            maxBptAmountIn: exactBptAmountIn,
            kind: RemoveLiquidityKind.PROPORTIONAL,
            wethIsEth: false,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.removeLiquidityProportionalNestedPoolHook, (params, tokensOut, tokensToUnwrap))
        );
        return abi.decode(result, (uint256[]));
    }

    /* ========================================================================== */
    /*                              HOOK FUNCTIONS                                */
    /* ========================================================================== */

    /**
     * @notice Hook for adding liquidity to nested pools.
     * @dev Can only be called by the Vault.
     */
    function addLiquidityUnbalancedNestedPoolHook(
        AddLiquidityHookParams calldata params,
        address[] memory tokensIn,
        address[] memory tokensToWrap
    ) external nonReentrant onlyVault returns (uint256 exactBptAmountOut) {
        InputHelpers.ensureInputLengthMatch(params.maxAmountsIn.length, tokensIn.length);

        // Clear stale processed tokens
        _clearProcessedTokens();

        // Load token amounts into transient storage
        _loadTokenAmounts(tokensIn, params.maxAmountsIn);

        bool isStaticCall = EVMCallModeHelpers.isStaticCall();
        IVault vault = BalancerV3RouterStorageRepo._vault();

        // Process nested pools bottom-up
        (uint256[] memory amountsIn, bool parentPoolNeedsLiquidity) = _addLiquidityToParentPool(
            vault, params, isStaticCall, tokensToWrap
        );

        if (parentPoolNeedsLiquidity) {
            (, exactBptAmountOut, ) = vault.addLiquidity(
                _buildAddLiquidityParams(params, amountsIn, isStaticCall ? address(this) : params.sender)
            );
        }

        if (!isStaticCall) {
            _settlePaths(params.sender, params.wethIsEth);
        }
    }

    /**
     * @notice Hook for removing liquidity from nested pools.
     * @dev Can only be called by the Vault.
     */
    function removeLiquidityProportionalNestedPoolHook(
        RemoveLiquidityHookParams calldata params,
        address[] memory tokensOut,
        address[] memory tokensToUnwrap
    ) external nonReentrant onlyVault returns (uint256[] memory amountsOut) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        IERC20[] memory parentPoolTokens = vault.getPoolTokens(params.pool);

        InputHelpers.ensureInputLengthMatch(params.minAmountsOut.length, tokensOut.length);

        // Remove liquidity from parent pool
        uint256[] memory parentPoolAmountsOut = _removeFromParentPool(vault, params, parentPoolTokens.length);

        // Process each parent pool token
        _processParentPoolTokens(vault, params, parentPoolTokens, parentPoolAmountsOut, tokensToUnwrap);

        // Build and validate output amounts
        amountsOut = _buildOutputAmounts(tokensOut, params.minAmountsOut);

        // Settle if not a static call
        if (!EVMCallModeHelpers.isStaticCall()) {
            _settlePaths(params.sender, params.wethIsEth);
        }
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _processedTokensIn() internal pure returns (TransientEnumerableSet.AddressSet storage enumerableSet) {
        bytes32 slot = PROCESSED_TOKENS_IN_SLOT;
        assembly ("memory-safe") {
            enumerableSet.slot := slot
        }
    }

    function _clearProcessedTokens() internal {
        address[] memory processedTokens = _processedTokensIn().values();
        for (uint256 i = processedTokens.length; i > 0; --i) {
            _processedTokensIn().remove(processedTokens[i - 1]);
        }
    }

    function _loadTokenAmounts(address[] memory tokensIn, uint256[] memory amountsIn) internal {
        for (uint256 i = 0; i < tokensIn.length; ++i) {
            if (amountsIn[i] > 0) {
                BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tSet(tokensIn[i], amountsIn[i]);
                if (!BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().add(tokensIn[i])) {
                    revert ICompositeLiquidityRouterErrors.DuplicateTokenIn(tokensIn[i]);
                }
            }
        }
    }

    function _addLiquidityToParentPool(
        IVault vault,
        AddLiquidityHookParams calldata params,
        bool isStaticCall,
        address[] memory tokensToWrap
    ) internal returns (uint256[] memory amountsIn, bool parentPoolNeedsLiquidity) {
        IERC20[] memory parentPoolTokens = vault.getPoolTokens(params.pool);
        uint256 numTokens = parentPoolTokens.length;
        amountsIn = new uint256[](numTokens);
        parentPoolNeedsLiquidity = false;

        for (uint256 i = 0; i < numTokens; ++i) {
            address parentPoolToken = address(parentPoolTokens[i]);
            CompositeTokenType tokenType = _computeEffectiveCompositeTokenType(vault, parentPoolToken, tokensToWrap);

            uint256 amountIn = BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tGet(parentPoolToken);

            if (tokenType == CompositeTokenType.BPT) {
                // Token is a child pool BPT - add liquidity to child first
                amountsIn[i] = _addLiquidityToChildPool(vault, parentPoolToken, isStaticCall, tokensToWrap, params.userData);
            } else if (tokenType == CompositeTokenType.ERC4626) {
                // Token needs wrapping
                amountsIn[i] = _wrapToken(vault, parentPoolToken, amountIn, isStaticCall);
            } else {
                // Regular ERC20
                amountsIn[i] = amountIn;
            }

            if (amountsIn[i] > 0) {
                parentPoolNeedsLiquidity = true;
            }
        }
    }

    function _addLiquidityToChildPool(
        IVault vault,
        address childPool,
        bool isStaticCall,
        address[] memory tokensToWrap,
        bytes calldata userData
    ) internal returns (uint256 bptAmountOut) {
        IERC20[] memory childPoolTokens = vault.getPoolTokens(childPool);
        uint256 numTokens = childPoolTokens.length;
        uint256[] memory childAmountsIn = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; ++i) {
            address childToken = address(childPoolTokens[i]);

            if (_processedTokensIn().contains(childToken)) {
                continue; // Already processed
            }

            CompositeTokenType tokenType = _computeEffectiveCompositeTokenType(vault, childToken, tokensToWrap);
            uint256 amountIn = BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tGet(childToken);

            if (tokenType == CompositeTokenType.ERC4626 && amountIn > 0) {
                childAmountsIn[i] = _wrapToken(vault, childToken, amountIn, isStaticCall);
            } else {
                childAmountsIn[i] = amountIn;
            }

            _processedTokensIn().add(childToken);
        }

        // Check if we need to add liquidity
        bool needsLiquidity = false;
        for (uint256 i = 0; i < numTokens; ++i) {
            if (childAmountsIn[i] > 0) {
                needsLiquidity = true;
                break;
            }
        }

        if (needsLiquidity) {
            (, bptAmountOut, ) = vault.addLiquidity(
                AddLiquidityParams({
                    pool: childPool,
                    to: address(this),
                    maxAmountsIn: childAmountsIn,
                    minBptAmountOut: 0,
                    kind: AddLiquidityKind.UNBALANCED,
                    userData: userData
                })
            );
        }
    }

    function _wrapToken(
        IVault vault,
        address wrappedToken,
        uint256 underlyingAmount,
        bool isStaticCall
    ) internal returns (uint256 wrappedAmount) {
        if (underlyingAmount == 0) return 0;

        address underlying = vault.getERC4626BufferAsset(IERC4626(wrappedToken));
        if (underlying == address(0)) {
            revert IVaultErrors.BufferNotInitialized(IERC4626(wrappedToken));
        }

        if (!isStaticCall) {
            // Settle underlying from sender
            BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().add(underlying);
            BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tAdd(underlying, underlyingAmount);
        }

        (, , wrappedAmount) = vault.erc4626BufferWrapOrUnwrap(
            BufferWrapOrUnwrapParams({
                kind: SwapKind.EXACT_IN,
                direction: WrappingDirection.WRAP,
                wrappedToken: IERC4626(wrappedToken),
                amountGivenRaw: underlyingAmount,
                limitRaw: 0
            })
        );
    }

    function _removeFromParentPool(
        IVault vault,
        RemoveLiquidityHookParams calldata params,
        uint256 numTokens
    ) internal returns (uint256[] memory amountsOut) {
        if (vault.isPoolInRecoveryMode(params.pool)) {
            amountsOut = vault.removeLiquidityRecovery(
                params.pool,
                params.sender,
                params.maxBptAmountIn,
                new uint256[](numTokens)
            );
        } else {
            (, amountsOut, ) = vault.removeLiquidity(
                RemoveLiquidityParams({
                    pool: params.pool,
                    from: params.sender,
                    maxBptAmountIn: params.maxBptAmountIn,
                    minAmountsOut: new uint256[](numTokens),
                    kind: params.kind,
                    userData: params.userData
                })
            );
        }
    }

    function _processParentPoolTokens(
        IVault vault,
        RemoveLiquidityHookParams calldata params,
        IERC20[] memory parentPoolTokens,
        uint256[] memory parentPoolAmountsOut,
        address[] memory tokensToUnwrap
    ) internal {
        for (uint256 i = 0; i < parentPoolTokens.length; i++) {
            address parentPoolToken = address(parentPoolTokens[i]);
            uint256 amountOut = parentPoolAmountsOut[i];

            CompositeTokenType tokenType = _computeEffectiveCompositeTokenType(vault, parentPoolToken, tokensToUnwrap);

            if (tokenType == CompositeTokenType.BPT) {
                _processChildPoolRemoval(vault, parentPoolToken, amountOut, tokensToUnwrap, params);
            } else if (tokenType == CompositeTokenType.ERC4626) {
                _unwrapAndTrack(vault, IERC4626(parentPoolToken), amountOut);
            } else {
                BalancerV3BatchRouterStorageRepo._updateSwapTokensOut(parentPoolToken, amountOut);
            }
        }
    }

    function _processChildPoolRemoval(
        IVault vault,
        address childPool,
        uint256 bptAmountIn,
        address[] memory tokensToUnwrap,
        RemoveLiquidityHookParams calldata params
    ) internal {
        vault.sendTo(IERC20(childPool), address(this), bptAmountIn);

        IERC20[] memory childPoolTokens = vault.getPoolTokens(childPool);
        uint256[] memory childAmountsOut;

        if (vault.isPoolInRecoveryMode(childPool)) {
            childAmountsOut = vault.removeLiquidityRecovery(
                childPool,
                address(this),
                bptAmountIn,
                new uint256[](childPoolTokens.length)
            );
        } else {
            (, childAmountsOut, ) = vault.removeLiquidity(
                RemoveLiquidityParams({
                    pool: childPool,
                    from: address(this),
                    maxBptAmountIn: bptAmountIn,
                    minAmountsOut: new uint256[](childPoolTokens.length),
                    kind: params.kind,
                    userData: params.userData
                })
            );
        }

        for (uint256 j = 0; j < childPoolTokens.length; j++) {
            address childToken = address(childPoolTokens[j]);
            uint256 childAmountOut = childAmountsOut[j];

            CompositeTokenType childTokenType = _computeEffectiveCompositeTokenType(vault, childToken, tokensToUnwrap);

            if (childTokenType == CompositeTokenType.ERC4626) {
                _unwrapAndTrack(vault, IERC4626(childToken), childAmountOut);
            } else {
                BalancerV3BatchRouterStorageRepo._updateSwapTokensOut(childToken, childAmountOut);
            }
        }
    }

    function _unwrapAndTrack(IVault vault, IERC4626 wrappedToken, uint256 wrappedAmount) internal {
        if (wrappedAmount == 0) return;

        (, , uint256 underlyingAmount) = vault.erc4626BufferWrapOrUnwrap(
            BufferWrapOrUnwrapParams({
                kind: SwapKind.EXACT_IN,
                direction: WrappingDirection.UNWRAP,
                wrappedToken: wrappedToken,
                amountGivenRaw: wrappedAmount,
                limitRaw: 0
            })
        );

        BalancerV3BatchRouterStorageRepo._updateSwapTokensOut(
            vault.getERC4626BufferAsset(wrappedToken),
            underlyingAmount
        );
    }

    function _buildOutputAmounts(
        address[] memory tokensOut,
        uint256[] memory minAmountsOut
    ) internal returns (uint256[] memory amountsOut) {
        uint256 numTokensOut = tokensOut.length;

        if (BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().length() != numTokensOut) {
            revert ICompositeLiquidityRouterErrors.WrongTokensOut(
                BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().values(),
                tokensOut
            );
        }

        amountsOut = new uint256[](numTokensOut);
        bool[] memory checkedTokenIndexes = new bool[](numTokensOut);

        for (uint256 i = 0; i < numTokensOut; ++i) {
            address tokenOut = tokensOut[i];
            uint256 tokenIndex = BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().indexOf(tokenOut);

            if (checkedTokenIndexes[tokenIndex]) {
                revert ICompositeLiquidityRouterErrors.WrongTokensOut(
                    BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().values(),
                    tokensOut
                );
            }

            checkedTokenIndexes[tokenIndex] = true;
            amountsOut[i] = BalancerV3BatchRouterStorageRepo._currentSwapTokenOutAmounts().tGet(tokenOut);

            if (amountsOut[i] < minAmountsOut[i]) {
                revert IVaultErrors.AmountOutBelowMin(IERC20(tokenOut), amountsOut[i], minAmountsOut[i]);
            }
        }
    }

    function _computeEffectiveCompositeTokenType(
        IVault vault,
        address token,
        address[] memory tokensToWrapOrUnwrap
    ) internal view returns (CompositeTokenType) {
        // Check if it's a registered pool (BPT)
        if (vault.isPoolRegistered(token)) {
            return CompositeTokenType.BPT;
        }

        // Check if it's an ERC4626 that should be wrapped/unwrapped
        for (uint256 i = 0; i < tokensToWrapOrUnwrap.length; ++i) {
            if (tokensToWrapOrUnwrap[i] == token) {
                return CompositeTokenType.ERC4626;
            }
        }

        return CompositeTokenType.ERC20;
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

    /**
     * @notice Settle all token flows after nested pool operations.
     */
    function _settlePaths(address sender, bool wethIsEth) internal {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        bool isPrepaid = BalancerV3RouterStorageRepo._isPrepaid();
        IWETH weth = BalancerV3RouterStorageRepo._weth();

        // Settle inputs
        address[] memory tokensIn = BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().values();
        for (uint256 i = tokensIn.length; i > 0; --i) {
            address tokenIn = tokensIn[i - 1];
            uint256 amount = BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tGet(tokenIn);

            if (!isPrepaid || (wethIsEth && tokenIn == address(weth))) {
                _takeTokenIn(sender, IERC20(tokenIn), amount, wethIsEth);
            } else {
                vault.settle(IERC20(tokenIn), amount);
            }

            BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tSet(tokenIn, 0);
            BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().remove(tokenIn);
        }

        // Settle outputs
        address[] memory tokensOut = BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().values();
        for (uint256 i = tokensOut.length; i > 0; --i) {
            address tokenOut = tokensOut[i - 1];
            uint256 amount = BalancerV3BatchRouterStorageRepo._currentSwapTokenOutAmounts().tGet(tokenOut);

            _sendTokenOut(sender, IERC20(tokenOut), amount, wethIsEth);

            BalancerV3BatchRouterStorageRepo._currentSwapTokenOutAmounts().tSet(tokenOut, 0);
            BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().remove(tokenOut);
        }

        _returnEth(sender);
    }
}
