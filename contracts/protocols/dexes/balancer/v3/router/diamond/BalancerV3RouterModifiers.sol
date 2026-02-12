// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {SafeCast} from "@crane/contracts/utils/SafeCast.sol";
import {Address} from "@crane/contracts/utils/Address.sol";
import { IPermit2 } from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";

import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRouterCommon} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouterCommon.sol";
import {ISenderGuard} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISenderGuard.sol";

import {BalancerV3RouterStorageRepo} from "./BalancerV3RouterStorageRepo.sol";

/* -------------------------------------------------------------------------- */
/*                          BalancerV3RouterModifiers                         */
/* -------------------------------------------------------------------------- */

/**
 * @title BalancerV3RouterModifiers
 * @notice Base contract providing shared modifiers and utilities for Router facets.
 * @dev Implements functionality from RouterCommon, SenderGuard, VaultGuard, and
 * ReentrancyGuardTransient in a Diamond-compatible way.
 *
 * Key modifiers:
 * - saveSender: Preserves msg.sender through vault callback chain
 * - saveSenderAndManageEth: Combines sender saving with ETH management
 * - onlyVault: Restricts calls to vault-only
 * - nonReentrant: Reentrancy protection using transient storage
 */
abstract contract BalancerV3RouterModifiers is ISenderGuard {
    using Address for address payable;
    using SafeCast for uint256;

    /* ------ Errors ------ */

    /// @dev Caller is not the Vault.
    error SenderIsNotVault(address sender);

    /// @dev Reentrancy detected.
    error ReentrancyGuardReentrantCall();

    /// @dev Insufficient ETH provided for WETH wrapping.
    error InsufficientEth();

    /// @dev Insufficient tokens provided to vault.
    error InsufficientPayment(IERC20 token);

    /* ------ View Functions ------ */

    /// @inheritdoc ISenderGuard
    function getSender() external view virtual returns (address) {
        return BalancerV3RouterStorageRepo._getSender();
    }

    /* ------ Transient Storage Slots ------ */

    /// @dev Transient slot for reentrancy guard state.
    /// Using a distinct slot from Balancer's to avoid conflicts.
    bytes32 private constant REENTRANCY_GUARD_SLOT =
        keccak256("protocols.dexes.balancer.v3.router.diamond.reentrancy");

    /* ------ Modifiers ------ */

    /**
     * @notice Saves the user or contract that initiated the current operation.
     * @dev Preserves the original caller through nested router calls.
     * Only the outermost caller is saved; nested calls see the same sender.
     */
    modifier saveSender(address sender) {
        bool isExternalSender = BalancerV3RouterStorageRepo._saveSender(sender);
        _;
        BalancerV3RouterStorageRepo._discardSenderIfRequired(isExternalSender);
    }

    /**
     * @notice Combines sender saving with ETH management and reentrancy protection.
     * @dev Locks ETH return during execution to prevent premature returns,
     * then returns excess ETH at the end.
     */
    modifier saveSenderAndManageEth() {
        bool isExternalSender = BalancerV3RouterStorageRepo._saveSender(msg.sender);

        // Revert if a function with this modifier is called recursively
        if (BalancerV3RouterStorageRepo._tloadIsReturnEthLocked()) {
            revert ReentrancyGuardReentrantCall();
        }

        // Lock the return of ETH during execution
        BalancerV3RouterStorageRepo._tstoreIsReturnEthLocked(true);
        _;
        BalancerV3RouterStorageRepo._tstoreIsReturnEthLocked(false);

        address sender = BalancerV3RouterStorageRepo._getSender();
        BalancerV3RouterStorageRepo._discardSenderIfRequired(isExternalSender);

        _returnEth(sender);
    }

    /**
     * @notice Restricts function access to the Vault only.
     */
    modifier onlyVault() {
        _ensureSenderIsVault();
        _;
    }

    /**
     * @notice Transient-storage based reentrancy guard.
     * @dev Uses EIP-1153 transient storage for gas-efficient reentrancy protection.
     */
    modifier nonReentrant() {
        _ensureNotReentrant();
        _setReentrantFlag(true);
        _;
        _setReentrantFlag(false);
    }

    /* ------ Internal Functions ------ */

    /**
     * @dev Ensure the caller is the vault.
     */
    function _ensureSenderIsVault() internal view {
        if (msg.sender != address(BalancerV3RouterStorageRepo._vault())) {
            revert SenderIsNotVault(msg.sender);
        }
    }

    /**
     * @dev Check reentrancy flag and revert if already entered.
     */
    function _ensureNotReentrant() internal view {
        bool entered;
        bytes32 slot = REENTRANCY_GUARD_SLOT;
        assembly {
            entered := tload(slot)
        }
        if (entered) {
            revert ReentrancyGuardReentrantCall();
        }
    }

    /**
     * @dev Set or clear the reentrancy flag.
     */
    function _setReentrantFlag(bool entered) internal {
        bytes32 slot = REENTRANCY_GUARD_SLOT;
        assembly {
            tstore(slot, entered)
        }
    }

    /**
     * @dev Returns excess ETH back to the sender.
     * @param sender The address to return ETH to.
     */
    function _returnEth(address sender) internal {
        // Most operations will not have ETH to return
        uint256 excess = address(this).balance;
        if (excess == 0) {
            return;
        }

        // If ETH return is locked (nested call), don't return yet
        if (BalancerV3RouterStorageRepo._tloadIsReturnEthLocked()) {
            return;
        }

        payable(sender).sendValue(excess);
    }

    /**
     * @dev Build an array with a single token amount at the specified index.
     * @param pool The pool to get token count from.
     * @param token The token to find.
     * @param amountGiven The amount to place at the token's index.
     * @return amountsGiven Array with amountGiven at tokenIndex, 0 elsewhere.
     * @return tokenIndex The index of the token in the pool.
     */
    function _getSingleInputArrayAndTokenIndex(
        address pool,
        IERC20 token,
        uint256 amountGiven
    ) internal view returns (uint256[] memory amountsGiven, uint256 tokenIndex) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        uint256 numTokens;
        (numTokens, tokenIndex) = vault.getPoolTokenCountAndIndexOfToken(pool, token);
        amountsGiven = new uint256[](numTokens);
        amountsGiven[tokenIndex] = amountGiven;
    }

    /**
     * @dev Returns an array of max limits for each token in the pool.
     * @param pool The pool to get token count from.
     * @return maxLimits Array of MAX_AMOUNT for each token.
     */
    function _maxTokenLimits(address pool) internal view returns (uint256[] memory maxLimits) {
        IVault vault = BalancerV3RouterStorageRepo._vault();
        uint256 numTokens = vault.getPoolTokens(pool).length;
        maxLimits = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; ++i) {
            maxLimits[i] = BalancerV3RouterStorageRepo.MAX_AMOUNT;
        }
    }

    /**
     * @dev Transfer tokens from sender to vault, handling WETH wrapping if needed.
     * @param sender The sender providing tokens.
     * @param tokenIn The token to transfer.
     * @param amountIn The amount to transfer.
     * @param wethIsEth Whether to treat WETH as ETH.
     */
    function _takeTokenIn(address sender, IERC20 tokenIn, uint256 amountIn, bool wethIsEth) internal {
        IWETH weth = BalancerV3RouterStorageRepo._weth();
        IVault vault = BalancerV3RouterStorageRepo._vault();

        if (wethIsEth && address(tokenIn) == address(weth)) {
            // Wrap ETH and settle with vault
            if (address(this).balance < amountIn) {
                revert InsufficientEth();
            }
            weth.deposit{value: amountIn}();
            weth.transfer(address(vault), amountIn);
            vault.settle(tokenIn, amountIn);
        } else {
            if (amountIn > 0) {
                if (BalancerV3RouterStorageRepo._isPrepaid()) {
                    // Prepaid mode: tokens already in vault, just settle
                    vault.settle(tokenIn, amountIn);
                } else {
                    // Retail mode: transfer via Permit2 and settle
                    IPermit2 permit2 = BalancerV3RouterStorageRepo._permit2();
                    permit2.transferFrom(sender, address(vault), amountIn.toUint160(), address(tokenIn));
                    vault.settle(tokenIn, amountIn);
                }
            }
        }
    }

    /**
     * @dev Transfer tokens from vault to sender, handling WETH unwrapping if needed.
     * @param sender The recipient of tokens.
     * @param tokenOut The token to send.
     * @param amountOut The amount to send.
     * @param wethIsEth Whether to treat WETH as ETH.
     */
    function _sendTokenOut(address sender, IERC20 tokenOut, uint256 amountOut, bool wethIsEth) internal {
        if (amountOut == 0) {
            return;
        }

        IWETH weth = BalancerV3RouterStorageRepo._weth();
        IVault vault = BalancerV3RouterStorageRepo._vault();

        if (wethIsEth && address(tokenOut) == address(weth)) {
            // Receive WETH from vault, unwrap, and send ETH
            vault.sendTo(tokenOut, address(this), amountOut);
            weth.withdraw(amountOut);
            payable(sender).sendValue(amountOut);
        } else {
            // Send tokens directly to sender
            vault.sendTo(tokenOut, sender, amountOut);
        }
    }

    /**
     * @dev Enables the Router to receive ETH for WETH unwrapping.
     * Only accepts ETH from the WETH contract.
     */
    receive() external payable virtual {
        if (msg.sender != address(BalancerV3RouterStorageRepo._weth())) {
            revert EthTransfer();
        }
    }
}
