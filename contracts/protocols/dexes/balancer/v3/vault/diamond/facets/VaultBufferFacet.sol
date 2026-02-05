// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {SafeCast} from "@crane/contracts/utils/SafeCast.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {SafeERC20} from "@crane/contracts/utils/SafeERC20.sol";

import {IVaultMain} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultMain.sol";
import "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {PackedTokenBalance} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/PackedTokenBalance.sol";
import {BufferHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/BufferHelpers.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

import {BalancerV3VaultStorageRepo} from "../BalancerV3VaultStorageRepo.sol";
import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                             VaultBufferFacet                               */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultBufferFacet
 * @notice Handles ERC4626 buffer wrap/unwrap operations.
 * @dev Implements the erc4626BufferWrapOrUnwrap function from IVaultMain.
 *
 * ERC4626 buffers allow efficient wrap/unwrap operations by maintaining
 * internal liquidity. When buffer has sufficient liquidity, operations
 * complete without external calls. Otherwise, rebalances via the wrapper.
 *
 * Key features:
 * - Gas-efficient when buffer has liquidity
 * - Automatic rebalancing when buffer is imbalanced
 * - Query mode support for simulations
 */
contract VaultBufferFacet is BalancerV3VaultModifiers, IFacet {
    using PackedTokenBalance for bytes32;
    using BufferHelpers for bytes32;
    using SafeCast for *;
    using SafeERC20 for IERC20;

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(VaultBufferFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IVaultMain).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = this.erc4626BufferWrapOrUnwrap.selector;
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

    /**
     * @notice Wraps or unwraps tokens using the ERC4626 buffer.
     * @param params Wrap/unwrap parameters
     * @return amountCalculatedRaw The calculated amount (varies by kind)
     * @return amountInRaw Amount of input token
     * @return amountOutRaw Amount of output token
     */
    function erc4626BufferWrapOrUnwrap(
        BufferWrapOrUnwrapParams memory params
    )
        external
        onlyWhenUnlocked
        whenVaultBuffersAreNotPaused
        withInitializedBuffer(params.wrappedToken)
        nonReentrant
        returns (uint256 amountCalculatedRaw, uint256 amountInRaw, uint256 amountOutRaw)
    {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        IERC20 underlyingToken = IERC20(params.wrappedToken.asset());
        _ensureCorrectBufferAsset(params.wrappedToken, address(underlyingToken));
        _ensureValidWrapAmount(params.wrappedToken, params.amountGivenRaw);

        if (params.direction == WrappingDirection.UNWRAP) {
            bytes32 bufferBalances;
            (amountInRaw, amountOutRaw, bufferBalances) = _unwrapWithBuffer(
                layout,
                params.kind,
                underlyingToken,
                params.wrappedToken,
                params.amountGivenRaw
            );
            emit Unwrap(params.wrappedToken, amountInRaw, amountOutRaw, bufferBalances);
        } else {
            bytes32 bufferBalances;
            (amountInRaw, amountOutRaw, bufferBalances) = _wrapWithBuffer(
                layout,
                params.kind,
                underlyingToken,
                params.wrappedToken,
                params.amountGivenRaw
            );
            emit Wrap(params.wrappedToken, amountInRaw, amountOutRaw, bufferBalances);
        }

        if (params.kind == SwapKind.EXACT_IN) {
            if (amountOutRaw < params.limitRaw) {
                revert SwapLimit(amountOutRaw, params.limitRaw);
            }
            amountCalculatedRaw = amountOutRaw;
        } else {
            if (amountInRaw > params.limitRaw) {
                revert SwapLimit(amountInRaw, params.limitRaw);
            }
            amountCalculatedRaw = amountInRaw;
        }

        _ensureValidWrapAmount(params.wrappedToken, amountCalculatedRaw);
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _ensureValidWrapAmount(IERC4626 wrappedToken, uint256 amount) private view {
        if (amount < BalancerV3VaultStorageRepo._minimumWrapAmount()) {
            revert WrapAmountTooSmall(wrappedToken);
        }
    }

    /**
     * @dev Wraps underlying tokens to wrapped tokens using the buffer.
     */
    function _wrapWithBuffer(
        BalancerV3VaultStorageRepo.Storage storage layout,
        SwapKind kind,
        IERC20 underlyingToken,
        IERC4626 wrappedToken,
        uint256 amountGiven
    ) internal returns (uint256 amountInUnderlying, uint256 amountOutWrapped, bytes32 bufferBalances) {
        if (kind == SwapKind.EXACT_IN) {
            (amountInUnderlying, amountOutWrapped) = (amountGiven, wrappedToken.previewDeposit(amountGiven - 1) - 1);
        } else {
            (amountInUnderlying, amountOutWrapped) = (wrappedToken.previewMint(amountGiven + 1) + 1, amountGiven);
        }

        bufferBalances = layout.bufferTokenBalances[wrappedToken];

        if (_isQueryContext()) {
            return (amountInUnderlying, amountOutWrapped, bufferBalances);
        }

        if (bufferBalances.getBalanceDerived() >= amountOutWrapped) {
            // Buffer has enough liquidity
            uint256 newDerivedBalance;
            unchecked {
                newDerivedBalance = bufferBalances.getBalanceDerived() - amountOutWrapped;
            }

            bufferBalances = PackedTokenBalance.toPackedBalance(
                bufferBalances.getBalanceRaw() + amountInUnderlying,
                newDerivedBalance
            );
            layout.bufferTokenBalances[wrappedToken] = bufferBalances;
        } else {
            // Need to rebalance via external call
            uint256 vaultUnderlyingDeltaHint;
            uint256 vaultWrappedDeltaHint;

            if (kind == SwapKind.EXACT_IN) {
                int256 bufferUnderlyingImbalance = bufferBalances.getBufferUnderlyingImbalance(wrappedToken);
                vaultUnderlyingDeltaHint = (amountInUnderlying.toInt256() + bufferUnderlyingImbalance).toUint256();
                underlyingToken.forceApprove(address(wrappedToken), vaultUnderlyingDeltaHint);
                vaultWrappedDeltaHint = wrappedToken.deposit(vaultUnderlyingDeltaHint, address(this));
            } else {
                int256 bufferWrappedImbalance = bufferBalances.getBufferWrappedImbalance(wrappedToken);
                vaultWrappedDeltaHint = (amountOutWrapped.toInt256() - bufferWrappedImbalance).toUint256();
                vaultUnderlyingDeltaHint = wrappedToken.previewMint(vaultWrappedDeltaHint);
                underlyingToken.forceApprove(address(wrappedToken), vaultUnderlyingDeltaHint);
                vaultUnderlyingDeltaHint = wrappedToken.mint(vaultWrappedDeltaHint, address(this));
            }

            underlyingToken.forceApprove(address(wrappedToken), 0);

            _settleWrap(layout, underlyingToken, IERC20(address(wrappedToken)), vaultUnderlyingDeltaHint, vaultWrappedDeltaHint);

            bufferBalances = PackedTokenBalance.toPackedBalance(
                bufferBalances.getBalanceRaw() + amountInUnderlying - vaultUnderlyingDeltaHint,
                bufferBalances.getBalanceDerived() + vaultWrappedDeltaHint - amountOutWrapped
            );
            layout.bufferTokenBalances[wrappedToken] = bufferBalances;
        }

        _takeDebt(underlyingToken, amountInUnderlying);
        _supplyCredit(IERC20(address(wrappedToken)), amountOutWrapped);
    }

    /**
     * @dev Unwraps wrapped tokens to underlying tokens using the buffer.
     */
    function _unwrapWithBuffer(
        BalancerV3VaultStorageRepo.Storage storage layout,
        SwapKind kind,
        IERC20 underlyingToken,
        IERC4626 wrappedToken,
        uint256 amountGiven
    ) internal returns (uint256 amountInWrapped, uint256 amountOutUnderlying, bytes32 bufferBalances) {
        if (kind == SwapKind.EXACT_IN) {
            (amountInWrapped, amountOutUnderlying) = (amountGiven, wrappedToken.previewRedeem(amountGiven - 1) - 1);
        } else {
            (amountInWrapped, amountOutUnderlying) = (wrappedToken.previewWithdraw(amountGiven + 1) + 1, amountGiven);
        }

        bufferBalances = layout.bufferTokenBalances[wrappedToken];

        if (_isQueryContext()) {
            return (amountInWrapped, amountOutUnderlying, bufferBalances);
        }

        if (bufferBalances.getBalanceRaw() >= amountOutUnderlying) {
            // Buffer has enough liquidity
            uint256 newRawBalance;
            unchecked {
                newRawBalance = bufferBalances.getBalanceRaw() - amountOutUnderlying;
            }

            bufferBalances = PackedTokenBalance.toPackedBalance(
                newRawBalance,
                bufferBalances.getBalanceDerived() + amountInWrapped
            );
            layout.bufferTokenBalances[wrappedToken] = bufferBalances;
        } else {
            // Need to rebalance via external call
            uint256 vaultUnderlyingDeltaHint;
            uint256 vaultWrappedDeltaHint;

            if (kind == SwapKind.EXACT_IN) {
                int256 bufferWrappedImbalance = bufferBalances.getBufferWrappedImbalance(wrappedToken);
                vaultWrappedDeltaHint = (amountInWrapped.toInt256() + bufferWrappedImbalance).toUint256();
                vaultUnderlyingDeltaHint = wrappedToken.redeem(vaultWrappedDeltaHint, address(this), address(this));
            } else {
                int256 bufferUnderlyingImbalance = bufferBalances.getBufferUnderlyingImbalance(wrappedToken);
                vaultUnderlyingDeltaHint = (amountOutUnderlying.toInt256() - bufferUnderlyingImbalance).toUint256();
                vaultWrappedDeltaHint = wrappedToken.withdraw(vaultUnderlyingDeltaHint, address(this), address(this));
            }

            _settleUnwrap(layout, underlyingToken, IERC20(address(wrappedToken)), vaultUnderlyingDeltaHint, vaultWrappedDeltaHint);

            bufferBalances = PackedTokenBalance.toPackedBalance(
                bufferBalances.getBalanceRaw() + vaultUnderlyingDeltaHint - amountOutUnderlying,
                bufferBalances.getBalanceDerived() + amountInWrapped - vaultWrappedDeltaHint
            );
            layout.bufferTokenBalances[wrappedToken] = bufferBalances;
        }

        _takeDebt(IERC20(address(wrappedToken)), amountInWrapped);
        _supplyCredit(underlyingToken, amountOutUnderlying);
    }

    function _settleWrap(
        BalancerV3VaultStorageRepo.Storage storage layout,
        IERC20 underlyingToken,
        IERC20 wrappedToken,
        uint256 underlyingDeltaHint,
        uint256 wrappedDeltaHint
    ) internal {
        uint256 expectedUnderlyingReservesAfter = layout.reservesOf[underlyingToken] - underlyingDeltaHint;
        uint256 expectedWrappedReservesAfter = layout.reservesOf[wrappedToken] + wrappedDeltaHint;
        _settleWrapUnwrap(layout, underlyingToken, wrappedToken, expectedUnderlyingReservesAfter, expectedWrappedReservesAfter);
    }

    function _settleUnwrap(
        BalancerV3VaultStorageRepo.Storage storage layout,
        IERC20 underlyingToken,
        IERC20 wrappedToken,
        uint256 underlyingDeltaHint,
        uint256 wrappedDeltaHint
    ) internal {
        uint256 expectedUnderlyingReservesAfter = layout.reservesOf[underlyingToken] + underlyingDeltaHint;
        uint256 expectedWrappedReservesAfter = layout.reservesOf[wrappedToken] - wrappedDeltaHint;
        _settleWrapUnwrap(layout, underlyingToken, wrappedToken, expectedUnderlyingReservesAfter, expectedWrappedReservesAfter);
    }

    function _settleWrapUnwrap(
        BalancerV3VaultStorageRepo.Storage storage layout,
        IERC20 underlyingToken,
        IERC20 wrappedToken,
        uint256 expectedUnderlyingReservesAfter,
        uint256 expectedWrappedReservesAfter
    ) internal {
        uint256 underlyingBalancesAfter = underlyingToken.balanceOf(address(this));
        if (underlyingBalancesAfter < expectedUnderlyingReservesAfter) {
            revert NotEnoughUnderlying(
                IERC4626(address(wrappedToken)),
                expectedUnderlyingReservesAfter,
                underlyingBalancesAfter
            );
        }
        layout.reservesOf[underlyingToken] = underlyingBalancesAfter;

        uint256 wrappedBalancesAfter = wrappedToken.balanceOf(address(this));
        if (wrappedBalancesAfter < expectedWrappedReservesAfter) {
            revert NotEnoughWrapped(
                IERC4626(address(wrappedToken)),
                expectedWrappedReservesAfter,
                wrappedBalancesAfter
            );
        }
        layout.reservesOf[wrappedToken] = wrappedBalancesAfter;
    }
}
