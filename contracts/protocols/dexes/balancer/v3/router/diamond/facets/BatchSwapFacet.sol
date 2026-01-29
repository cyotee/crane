// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IWETH} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IBatchRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBatchRouter.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/BatchRouterTypes.sol";

import {
    TransientEnumerableSet
} from "@balancer-labs/v3-solidity-utils/contracts/openzeppelin/TransientEnumerableSet.sol";
import {
    TransientStorageHelpers,
    AddressToUintMappingSlot
} from "@balancer-labs/v3-solidity-utils/contracts/helpers/TransientStorageHelpers.sol";
import {EVMCallModeHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/EVMCallModeHelpers.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3BatchRouterStorageRepo} from "../BalancerV3BatchRouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                             BatchSwapFacet                                 */
/* -------------------------------------------------------------------------- */

/**
 * @title BatchSwapFacet
 * @notice Handles batch swap operations for the Balancer V3 Router Diamond.
 * @dev Implements IBatchRouter interface for multi-path swaps.
 *
 * Key features:
 * - Multi-step swap paths (each step can be swap, add/remove liquidity, or buffer)
 * - Aggregated token settlements across all paths
 * - Transient storage for efficient tracking of token flows
 */
contract BatchSwapFacet is BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(BatchSwapFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IBatchRouter).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](6);
        funcs[0] = this.swapExactIn.selector;
        funcs[1] = this.swapExactOut.selector;
        funcs[2] = this.querySwapExactIn.selector;
        funcs[3] = this.querySwapExactOut.selector;
        funcs[4] = this.swapExactInHook.selector;
        funcs[5] = this.swapExactOutHook.selector;
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
    using SafeCast for uint256;

    /* ========================================================================== */
    /*                                 STRUCTS                                    */
    /* ========================================================================== */

    /// @dev Internal struct to reduce stack depth in step execution
    struct StepExecutionContext {
        IVault vault;
        address pool;
        IERC20 tokenIn;
        IERC20 tokenOut;
        uint256 amountGiven;
        uint256 limit;
        bool isLastStep;
        bool isBuffer;
        bytes userData;
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Execute batch swaps with exact input amounts per path.
     */
    function swapExactIn(
        SwapPathExactAmountIn[] memory paths,
        uint256 deadline,
        bool wethIsEth,
        bytes calldata userData
    )
        external
        payable
        saveSender(msg.sender)
        returns (uint256[] memory pathAmountsOut, address[] memory tokensOut, uint256[] memory amountsOut)
    {
        SwapExactInHookParams memory params = SwapExactInHookParams({
            sender: msg.sender,
            paths: paths,
            deadline: deadline,
            wethIsEth: wethIsEth,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(this.swapExactInHook, params)
        );
        return abi.decode(result, (uint256[], address[], uint256[]));
    }

    /**
     * @notice Execute batch swaps with exact output amounts per path.
     */
    function swapExactOut(
        SwapPathExactAmountOut[] memory paths,
        uint256 deadline,
        bool wethIsEth,
        bytes calldata userData
    )
        external
        payable
        saveSender(msg.sender)
        returns (uint256[] memory pathAmountsIn, address[] memory tokensIn, uint256[] memory amountsIn)
    {
        SwapExactOutHookParams memory params = SwapExactOutHookParams({
            sender: msg.sender,
            paths: paths,
            deadline: deadline,
            wethIsEth: wethIsEth,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().unlock(
            abi.encodeCall(this.swapExactOutHook, params)
        );
        return abi.decode(result, (uint256[], address[], uint256[]));
    }

    /**
     * @notice Query batch swaps with exact input amounts (no execution).
     */
    function querySwapExactIn(
        SwapPathExactAmountIn[] memory paths,
        address sender,
        bytes calldata userData
    )
        external
        saveSender(sender)
        returns (uint256[] memory pathAmountsOut, address[] memory tokensOut, uint256[] memory amountsOut)
    {
        // Zero out minAmountOut for queries
        for (uint256 i = 0; i < paths.length; ++i) {
            paths[i].minAmountOut = 0;
        }

        SwapExactInHookParams memory params = SwapExactInHookParams({
            sender: address(this),
            paths: paths,
            deadline: type(uint256).max,
            wethIsEth: false,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.querySwapExactInHook, params)
        );
        return abi.decode(result, (uint256[], address[], uint256[]));
    }

    /**
     * @notice Query batch swaps with exact output amounts (no execution).
     */
    function querySwapExactOut(
        SwapPathExactAmountOut[] memory paths,
        address sender,
        bytes calldata userData
    )
        external
        saveSender(sender)
        returns (uint256[] memory pathAmountsIn, address[] memory tokensIn, uint256[] memory amountsIn)
    {
        // Max out maxAmountIn for queries
        for (uint256 i = 0; i < paths.length; ++i) {
            paths[i].maxAmountIn = BalancerV3RouterStorageRepo.MAX_AMOUNT;
        }

        SwapExactOutHookParams memory params = SwapExactOutHookParams({
            sender: address(this),
            paths: paths,
            deadline: type(uint256).max,
            wethIsEth: false,
            userData: userData
        });

        bytes memory result = BalancerV3RouterStorageRepo._vault().quote(
            abi.encodeCall(this.querySwapExactOutHook, params)
        );
        return abi.decode(result, (uint256[], address[], uint256[]));
    }

    /* ========================================================================== */
    /*                              HOOK FUNCTIONS                                */
    /* ========================================================================== */

    function swapExactInHook(
        SwapExactInHookParams calldata params
    )
        external
        nonReentrant
        onlyVault
        returns (uint256[] memory pathAmountsOut, address[] memory tokensOut, uint256[] memory amountsOut)
    {
        (pathAmountsOut, tokensOut, amountsOut) = _swapExactInHook(params);
        _settlePaths(params.sender, params.wethIsEth);
    }

    function querySwapExactInHook(
        SwapExactInHookParams calldata params
    )
        external
        nonReentrant
        onlyVault
        returns (uint256[] memory pathAmountsOut, address[] memory tokensOut, uint256[] memory amountsOut)
    {
        return _swapExactInHook(params);
    }

    function swapExactOutHook(
        SwapExactOutHookParams calldata params
    )
        external
        nonReentrant
        onlyVault
        returns (uint256[] memory pathAmountsIn, address[] memory tokensIn, uint256[] memory amountsIn)
    {
        (pathAmountsIn, tokensIn, amountsIn) = _swapExactOutHook(params);
        _settlePaths(params.sender, params.wethIsEth);
    }

    function querySwapExactOutHook(
        SwapExactOutHookParams calldata params
    )
        external
        nonReentrant
        onlyVault
        returns (uint256[] memory pathAmountsIn, address[] memory tokensIn, uint256[] memory amountsIn)
    {
        return _swapExactOutHook(params);
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _swapExactInHook(
        SwapExactInHookParams calldata params
    )
        internal
        returns (uint256[] memory pathAmountsOut, address[] memory tokensOut, uint256[] memory amountsOut)
    {
        if (block.timestamp > params.deadline) {
            revert SwapDeadline();
        }

        pathAmountsOut = _computePathAmountsOut(params);

        // Copy transient storage values to memory for return
        tokensOut = BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().values();
        amountsOut = new uint256[](tokensOut.length);

        for (uint256 i = 0; i < tokensOut.length; ++i) {
            uint256 settledAmount = BalancerV3BatchRouterStorageRepo._settledTokenAmounts().tGet(tokensOut[i]);
            amountsOut[i] = BalancerV3BatchRouterStorageRepo._currentSwapTokenOutAmounts().tGet(tokensOut[i]) + settledAmount;

            if (settledAmount != 0) {
                BalancerV3BatchRouterStorageRepo._settledTokenAmounts().tSet(tokensOut[i], 0);
            }
        }
    }

    function _computePathAmountsOut(
        SwapExactInHookParams calldata params
    ) internal returns (uint256[] memory pathAmountsOut) {
        pathAmountsOut = new uint256[](params.paths.length);
        IVault vault = BalancerV3RouterStorageRepo._vault();
        bool isPrepaid = BalancerV3RouterStorageRepo._isPrepaid();

        for (uint256 i = 0; i < params.paths.length; ++i) {
            pathAmountsOut[i] = _processExactInPath(vault, params.paths[i], isPrepaid, params.userData);
        }
    }

    function _processExactInPath(
        IVault vault,
        SwapPathExactAmountIn memory path,
        bool isPrepaid,
        bytes calldata userData
    ) internal returns (uint256 pathAmountOut) {
        uint256 stepExactAmountIn = path.exactAmountIn;
        IERC20 stepTokenIn = path.tokenIn;

        if (!isPrepaid) {
            BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().add(address(stepTokenIn));
            BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tAdd(address(stepTokenIn), stepExactAmountIn);
        }

        for (uint256 j = 0; j < path.steps.length; ++j) {
            bool isLastStep = (j == path.steps.length - 1);
            SwapPathStep memory step = path.steps[j];

            StepExecutionContext memory ctx = StepExecutionContext({
                vault: vault,
                pool: step.pool,
                tokenIn: stepTokenIn,
                tokenOut: step.tokenOut,
                amountGiven: stepExactAmountIn,
                limit: isLastStep ? path.minAmountOut : 0,
                isLastStep: isLastStep,
                isBuffer: step.isBuffer,
                userData: userData
            });

            uint256 amountOut = _executeStepExactIn(ctx);

            if (isLastStep) {
                pathAmountOut = amountOut;
            } else {
                stepExactAmountIn = amountOut;
                stepTokenIn = step.tokenOut;
            }
        }
    }

    function _executeStepExactIn(StepExecutionContext memory ctx) internal returns (uint256 amountOut) {
        if (ctx.isBuffer) {
            amountOut = _executeBufferSwapExactIn(
                ctx.vault, ctx.pool, ctx.tokenIn, ctx.tokenOut, ctx.amountGiven, ctx.limit, ctx.isLastStep
            );
        } else {
            amountOut = _executeSwapExactIn(
                ctx.vault, ctx.pool, ctx.tokenIn, ctx.tokenOut, ctx.amountGiven, ctx.limit, ctx.isLastStep, ctx.userData
            );
        }
    }

    function _executeSwapExactIn(
        IVault vault,
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bool isLastStep,
        bytes memory userData
    ) internal returns (uint256 amountOut) {
        (, , amountOut) = vault.swap(
            VaultSwapParams({
                kind: SwapKind.EXACT_IN,
                pool: pool,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountGivenRaw: amountIn,
                limitRaw: minAmountOut,
                userData: userData
            })
        );

        if (isLastStep) {
            BalancerV3BatchRouterStorageRepo._updateSwapTokensOut(address(tokenOut), amountOut);
        }
    }

    function _executeBufferSwapExactIn(
        IVault vault,
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bool isLastStep
    ) internal returns (uint256 amountOut) {
        WrappingDirection direction = pool == address(tokenIn)
            ? WrappingDirection.UNWRAP
            : WrappingDirection.WRAP;

        (, , amountOut) = vault.erc4626BufferWrapOrUnwrap(
            BufferWrapOrUnwrapParams({
                kind: SwapKind.EXACT_IN,
                direction: direction,
                wrappedToken: IERC4626(pool),
                amountGivenRaw: amountIn,
                limitRaw: minAmountOut
            })
        );

        if (isLastStep) {
            BalancerV3BatchRouterStorageRepo._updateSwapTokensOut(address(tokenOut), amountOut);
        }
    }

    function _swapExactOutHook(
        SwapExactOutHookParams calldata params
    )
        internal
        returns (uint256[] memory pathAmountsIn, address[] memory tokensIn, uint256[] memory amountsIn)
    {
        if (block.timestamp > params.deadline) {
            revert SwapDeadline();
        }

        pathAmountsIn = _computePathAmountsIn(params);

        // Copy transient storage values to memory for return
        tokensIn = BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().values();
        amountsIn = new uint256[](tokensIn.length);
        bool isPrepaid = BalancerV3RouterStorageRepo._isPrepaid();

        for (uint256 i = 0; i < tokensIn.length; ++i) {
            address tokenIn = tokensIn[i];
            uint256 settledAmount = BalancerV3BatchRouterStorageRepo._settledTokenAmounts().tGet(tokenIn);
            amountsIn[i] = BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tGet(tokenIn) + settledAmount;

            if (settledAmount != 0) {
                BalancerV3BatchRouterStorageRepo._settledTokenAmounts().tSet(tokenIn, 0);
            }

            if (isPrepaid) {
                BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tSet(tokenIn, 0);
            }
        }
    }

    function _computePathAmountsIn(
        SwapExactOutHookParams calldata params
    ) internal returns (uint256[] memory pathAmountsIn) {
        pathAmountsIn = new uint256[](params.paths.length);
        IVault vault = BalancerV3RouterStorageRepo._vault();

        for (uint256 i = 0; i < params.paths.length; ++i) {
            pathAmountsIn[i] = _processExactOutPath(vault, params.paths[i], params.userData);
        }
    }

    function _processExactOutPath(
        IVault vault,
        SwapPathExactAmountOut memory path,
        bytes calldata userData
    ) internal returns (uint256 pathAmountIn) {
        uint256 stepExactAmountOut = path.exactAmountOut;
        uint256 lastStepIndex = path.steps.length - 1;
        IERC20 finalTokenOut = path.steps[lastStepIndex].tokenOut;
        IERC20 stepTokenOut = finalTokenOut;

        // Process steps in reverse for exact out
        for (uint256 j = path.steps.length; j > 0; --j) {
            bool isFirstStep = (j == 1);
            SwapPathStep memory step = path.steps[j - 1];
            IERC20 tokenIn = isFirstStep ? path.tokenIn : path.steps[j - 2].tokenOut;

            StepExecutionContext memory ctx = StepExecutionContext({
                vault: vault,
                pool: step.pool,
                tokenIn: tokenIn,
                tokenOut: stepTokenOut,
                amountGiven: stepExactAmountOut,
                limit: isFirstStep ? path.maxAmountIn : type(uint256).max,
                isLastStep: isFirstStep,  // In reverse, "first step" is the one we track
                isBuffer: step.isBuffer,
                userData: userData
            });

            uint256 amountIn = _executeStepExactOut(ctx);

            if (isFirstStep) {
                pathAmountIn = amountIn;
                BalancerV3BatchRouterStorageRepo._updateSwapTokensOut(address(finalTokenOut), path.exactAmountOut);
            } else {
                stepExactAmountOut = amountIn;
                stepTokenOut = step.tokenOut;
            }
        }
    }

    function _executeStepExactOut(StepExecutionContext memory ctx) internal returns (uint256 amountIn) {
        if (ctx.isBuffer) {
            amountIn = _executeBufferSwapExactOut(
                ctx.vault, ctx.pool, ctx.tokenIn, ctx.tokenOut, ctx.amountGiven, ctx.limit, ctx.isLastStep
            );
        } else {
            amountIn = _executeSwapExactOut(
                ctx.vault, ctx.pool, ctx.tokenIn, ctx.tokenOut, ctx.amountGiven, ctx.limit, ctx.isLastStep, ctx.userData
            );
        }
    }

    function _executeSwapExactOut(
        IVault vault,
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        bool isFirstStep,
        bytes memory userData
    ) internal returns (uint256 amountIn) {
        (, amountIn, ) = vault.swap(
            VaultSwapParams({
                kind: SwapKind.EXACT_OUT,
                pool: pool,
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                amountGivenRaw: amountOut,
                limitRaw: maxAmountIn,
                userData: userData
            })
        );

        if (isFirstStep) {
            BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().add(address(tokenIn));
            BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tAdd(address(tokenIn), amountIn);
        }
    }

    function _executeBufferSwapExactOut(
        IVault vault,
        address pool,
        IERC20 tokenIn,
        IERC20 tokenOut,
        uint256 amountOut,
        uint256 maxAmountIn,
        bool isFirstStep
    ) internal returns (uint256 amountIn) {
        WrappingDirection direction = pool == address(tokenIn)
            ? WrappingDirection.UNWRAP
            : WrappingDirection.WRAP;

        (, amountIn, ) = vault.erc4626BufferWrapOrUnwrap(
            BufferWrapOrUnwrapParams({
                kind: SwapKind.EXACT_OUT,
                direction: direction,
                wrappedToken: IERC4626(pool),
                amountGivenRaw: amountOut,
                limitRaw: maxAmountIn
            })
        );

        if (isFirstStep) {
            BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().add(address(tokenIn));
            BalancerV3BatchRouterStorageRepo._currentSwapTokenInAmounts().tAdd(address(tokenIn), amountIn);
        }
    }

    /**
     * @notice Settle all token flows after batch operations.
     */
    function _settlePaths(address sender, bool wethIsEth) internal {
        int256 numTokensIn = int256(BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().length());
        int256 numTokensOut = int256(BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().length());
        IVault vault = BalancerV3RouterStorageRepo._vault();
        bool isPrepaid = BalancerV3RouterStorageRepo._isPrepaid();
        IWETH weth = BalancerV3RouterStorageRepo._weth();

        // Settle inputs
        for (int256 i = numTokensIn - 1; i >= 0; --i) {
            address tokenIn = BalancerV3BatchRouterStorageRepo._currentSwapTokensIn().unchecked_at(uint256(i));
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
        for (int256 i = numTokensOut - 1; i >= 0; --i) {
            address tokenOut = BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().unchecked_at(uint256(i));
            uint256 amount = BalancerV3BatchRouterStorageRepo._currentSwapTokenOutAmounts().tGet(tokenOut);

            _sendTokenOut(sender, IERC20(tokenOut), amount, wethIsEth);

            BalancerV3BatchRouterStorageRepo._currentSwapTokenOutAmounts().tSet(tokenOut, 0);
            BalancerV3BatchRouterStorageRepo._currentSwapTokensOut().remove(tokenOut);
        }

        _returnEth(sender);
    }
}
