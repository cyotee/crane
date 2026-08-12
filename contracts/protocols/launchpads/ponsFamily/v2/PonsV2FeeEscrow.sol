// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ReentrancyGuard} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/ReentrancyGuard.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/IERC20.sol";
import {SafeERC20} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/utils/SafeERC20.sol";

import {IPonsV2FeeEscrow} from "./interfaces/ILaunchpadV2.sol";

/**
 * @title PonsV2FeeEscrow
 * @notice Shared pull-based claim ledger for pons v2 creator and protocol fees.
 * Bonding curves, the meme hook, and the buyback vault credit balances here;
 * recipients claim ETH or ERC-20 at their leisure.
 *
 * @dev Upstream Solidity for the live Robinhood deployment was not published
 * (Sourcify match null; not on GitHub). This implementation is reconstructed
 * from `IPonsV2FeeEscrow`, integration docs (Credited/Claimed* events), and
 * call-site requirements:
 * - `credit` is permissionless payable — callers attach the ETH they credit
 * - `creditToken` pulls via `transferFrom` (caller must approve)
 * - Meme hook measures escrow ERC-20 balance delta and requires exact receipt
 * - No owner, no pause, no free `receive` path that mints untracked balances
 *
 * Live address (Robinhood 4663): `ROBINHOOD_MAIN.PONS_V2_FEE_ESCROW`.
 */
contract PonsV2FeeEscrow is IPonsV2FeeEscrow, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */

    error ZeroAddress();
    error ZeroAmount();
    error InsufficientBalance(uint256 requested, uint256 available);
    error TransferFailed();
    error NativeTokenNotAllowed();

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    /// @notice Native ETH was credited to a claimable balance.
    event Credited(address indexed recipient, uint256 amount);

    /// @notice Native ETH was claimed from a claimable balance.
    event Claimed(address indexed recipient, uint256 amount);

    /// @notice ERC-20 was credited to a claimable balance.
    event CreditedToken(address indexed recipient, address indexed token, uint256 amount);

    /// @notice ERC-20 was claimed from a claimable balance.
    event ClaimedToken(address indexed recipient, address indexed token, uint256 amount);

    /* -------------------------------------------------------------------------- */
    /*                                   Storage                                  */
    /* -------------------------------------------------------------------------- */

    /// @dev Native ETH claimable balances.
    mapping(address recipient => uint256 amount) private _ethBalances;

    /// @dev ERC-20 claimable balances (quote assets and vest release tokens).
    mapping(address recipient => mapping(address token => uint256 amount)) private _tokenBalances;

    /* -------------------------------------------------------------------------- */
    /*                                   Credit                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Credit `msg.value` of native ETH to `recipient`'s claimable balance.
     * @dev Permissionless: any caller that attaches ETH may credit any recipient.
     * Zero-value credits are no-ops (no event) so fee-split callers can pass
     * zero amounts without special-casing.
     */
    function credit(address recipient) external payable override nonReentrant {
        if (recipient == address(0)) revert ZeroAddress();
        uint256 amount = msg.value;
        if (amount == 0) return;

        _ethBalances[recipient] += amount;
        emit Credited(recipient, amount);
    }

    /**
     * @notice Pull `amount` of `token` from the caller and credit `recipient`.
     * @dev Permissionless. Caller must `approve` this contract (or use
     * `forceApprove` from OZ v5). Exact transfer is required for fee-on-transfer
     * safety at the call site (meme hook checks escrow balance delta).
     */
    function creditToken(address recipient, address token, uint256 amount) external override nonReentrant {
        if (recipient == address(0) || token == address(0)) revert ZeroAddress();
        if (amount == 0) return;

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _tokenBalances[recipient][token] += amount;
        emit CreditedToken(recipient, token, amount);
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Claim                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Claim the caller's full native ETH balance.
     * @return amount Withdrawn amount (0 if nothing to claim).
     */
    function claim() external override nonReentrant returns (uint256 amount) {
        amount = _ethBalances[msg.sender];
        if (amount == 0) return 0;
        _ethBalances[msg.sender] = 0;
        _sendEth(msg.sender, amount);
        emit Claimed(msg.sender, amount);
    }

    /**
     * @notice Claim a specific amount of native ETH for the caller.
     * @return claimed The amount withdrawn (always equals `amount` on success).
     */
    function claim(uint256 amount) external override nonReentrant returns (uint256 claimed) {
        if (amount == 0) revert ZeroAmount();
        uint256 available = _ethBalances[msg.sender];
        if (amount > available) revert InsufficientBalance(amount, available);

        _ethBalances[msg.sender] = available - amount;
        _sendEth(msg.sender, amount);
        emit Claimed(msg.sender, amount);
        return amount;
    }

    /**
     * @notice Claim the caller's full balance of `token`.
     * @return amount Withdrawn amount (0 if nothing to claim).
     */
    function claimToken(address token) external override nonReentrant returns (uint256 amount) {
        if (token == address(0)) revert ZeroAddress();
        amount = _tokenBalances[msg.sender][token];
        if (amount == 0) return 0;
        _tokenBalances[msg.sender][token] = 0;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit ClaimedToken(msg.sender, token, amount);
    }

    /**
     * @notice Claim a specific amount of `token` for the caller.
     * @return claimed The amount withdrawn (always equals `amount` on success).
     */
    function claimToken(address token, uint256 amount) external override nonReentrant returns (uint256 claimed) {
        if (token == address(0)) revert ZeroAddress();
        if (amount == 0) revert ZeroAmount();
        uint256 available = _tokenBalances[msg.sender][token];
        if (amount > available) revert InsufficientBalance(amount, available);

        _tokenBalances[msg.sender][token] = available - amount;
        IERC20(token).safeTransfer(msg.sender, amount);
        emit ClaimedToken(msg.sender, token, amount);
        return amount;
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Views                                   */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc IPonsV2FeeEscrow
    function balanceOf(address recipient) external view override returns (uint256) {
        return _ethBalances[recipient];
    }

    /// @inheritdoc IPonsV2FeeEscrow
    function balanceOfToken(address recipient, address token) external view override returns (uint256) {
        return _tokenBalances[recipient][token];
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Internals                                */
    /* -------------------------------------------------------------------------- */

    function _sendEth(address to, uint256 amount) private {
        (bool sent,) = payable(to).call{value: amount}("");
        if (!sent) revert TransferFailed();
    }

    /// @dev Reject unsolicited ETH that would leave the contract over-funded
    /// relative to tracked ledgers.
    receive() external payable {
        revert NativeTokenNotAllowed();
    }
}
