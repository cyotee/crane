// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";

/// @title WrappedStakedNET (wsNET) — non-rebasing wrapper over sNET
/// @notice The production margin token for the Managed Futures Desk
///         (specs/perp.md §2). gOHM-shaped: a fixed wsNET balance whose sNET
///         value grows with the dividend index — `sNET value = balance ×
///         index / 1e18`. Raw rebasing sNET is never custodied by the venue;
///         this wrapper is what makes "margin that earns dividends" safe to
///         hold inside a contract. Permissionless wrap/unwrap, no owner.
/// @dev    wsNET has 18 decimals (sNET's 9 + 9 bits of index precision),
///         matching the wsOHM convention: `ws = sNet × 1e18 / index`.
contract WrappedStakedNET {
    error InsufficientBalance();
    error InsufficientAllowance();
    error ZeroAmount();
    error TransferFailed();

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Wrap(address indexed account, uint256 sNetIn, uint256 wsOut);
    event Unwrap(address indexed account, uint256 wsIn, uint256 sNetOut);

    string public constant name = "Wrapped Staked NET";
    string public constant symbol = "wsNET";
    uint8 public constant decimals = 18;

    /// @notice The live sNET token (rebasing; supplies the dividend index).
    IERC20 public immutable sNet;
    IsNET public immutable sNetIndex;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(address sNet_) {
        sNet = IERC20(sNet_);
        sNetIndex = IsNET(sNet_);
    }

    // ── Wrap / unwrap ──

    /// @notice Wraps `sNetAmount` (9-dec) into wsNET (18-dec) at the current
    ///         dividend index.
    function wrap(uint256 sNetAmount) external returns (uint256 wsOut) {
        if (sNetAmount == 0) revert ZeroAmount();
        wsOut = sNetToWs(sNetAmount);
        if (!sNet.transferFrom(msg.sender, address(this), sNetAmount)) revert TransferFailed();
        totalSupply += wsOut;
        unchecked {
            balanceOf[msg.sender] += wsOut;
        }
        emit Wrap(msg.sender, sNetAmount, wsOut);
        emit Transfer(address(0), msg.sender, wsOut);
    }

    /// @notice Unwraps `wsAmount` back to sNET at the current index (which has
    ///         grown since wrap — that growth is the accrued dividend).
    function unwrap(uint256 wsAmount) external returns (uint256 sNetOut) {
        if (wsAmount == 0) revert ZeroAmount();
        uint256 bal = balanceOf[msg.sender];
        if (bal < wsAmount) revert InsufficientBalance();
        sNetOut = wsToSNet(wsAmount);
        unchecked {
            balanceOf[msg.sender] = bal - wsAmount;
        }
        totalSupply -= wsAmount;
        emit Unwrap(msg.sender, wsAmount, sNetOut);
        emit Transfer(msg.sender, address(0), wsAmount);
        if (!sNet.transfer(msg.sender, sNetOut)) revert TransferFailed();
    }

    // ── Conversion views ──

    /// @notice sNET (9-dec) → wsNET (18-dec) at the current index.
    function sNetToWs(uint256 sNetAmount) public view returns (uint256) {
        return sNetAmount * 1e18 / sNetIndex.index();
    }

    /// @notice wsNET (18-dec) → sNET (9-dec) at the current index.
    function wsToSNet(uint256 wsAmount) public view returns (uint256) {
        return wsAmount * sNetIndex.index() / 1e18;
    }

    // ── ERC-20 ──

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            if (allowed < amount) revert InsufficientAllowance();
            unchecked {
                allowance[from][msg.sender] = allowed - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        uint256 bal = balanceOf[from];
        if (bal < amount) revert InsufficientBalance();
        unchecked {
            balanceOf[from] = bal - amount;
            balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
    }
}
