// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IsNET} from "@crane/contracts/protocols/pol/net/src/interfaces/IsNET.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {Wired} from "@crane/contracts/protocols/pol/net/src/abstract/Wired.sol";

/// @title StakedNET (sNET) — rebasing staked token
/// @notice OHM v1 gons model (specs/mechanism.md §3): TOTAL_GONS is fixed and
///         rebases scale gonsPerFragment. The Staking contract holds the
///         non-circulating inventory; user-held ("circulating") fragments
///         grow by exactly the rebase profit in aggregate, keeping the
///         NET ⇄ sNET peg (invariant §6.5).
contract StakedNET is IsNET, Wired {
    error NotStaking();
    error InsufficientBalance();
    error InsufficientAllowance();

    string public constant name = "Staked NET";
    string public constant symbol = "sNET";
    uint8 public constant decimals = 9;

    /// @dev Inventory ceiling: 5B whole NET of fragments. The RFV hard cap
    ///      binds supply far below this in any realistic path.
    uint256 private constant INITIAL_FRAGMENTS = 5_000_000_000e9;
    uint256 private constant TOTAL_GONS =
        type(uint256).max - (type(uint256).max % INITIAL_FRAGMENTS);
    uint256 private constant MAX_SUPPLY = type(uint128).max;

    address public staking;

    uint256 private _totalSupply;
    uint256 public gonsPerFragment;
    uint256 private _indexGons;
    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        _totalSupply = INITIAL_FRAGMENTS;
        gonsPerFragment = TOTAL_GONS / INITIAL_FRAGMENTS;
    }

    /// @notice One-time wiring: assigns the full inventory to Staking and
    ///         pins the index base at 1.0 (1e9).
    function wire(address staking_) external wiring {
        staking = _nonZero(staking_);
        _gonBalances[staking_] = TOTAL_GONS;
        _indexGons = Constants.NET_UNIT * gonsPerFragment;
        emit Transfer(address(0), staking_, INITIAL_FRAGMENTS);
    }

    // ── Views ──

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _gonBalances[account] / gonsPerFragment;
    }

    /// @notice User-held fragments (everything outside the Staking inventory).
    function circulatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(staking);
    }

    /// @inheritdoc IsNET
    function index() external view returns (uint256) {
        return _indexGons / gonsPerFragment;
    }

    function gonsForBalance(uint256 amount) external view returns (uint256) {
        return amount * gonsPerFragment;
    }

    function balanceForGons(uint256 gons) external view returns (uint256) {
        return gons / gonsPerFragment;
    }

    // ── Rebase ──

    /// @inheritdoc IsNET
    function rebase(uint256 profit, uint256 epoch) external returns (uint256) {
        _checkWired();
        if (msg.sender != staking) revert NotStaking();
        uint256 circulating = circulatingSupply();
        if (profit == 0 || circulating == 0) {
            emit LogRebase(epoch, 0, _indexGons / gonsPerFragment);
            return _totalSupply;
        }
        // Scale total supply so circulating fragments grow by exactly
        // `profit` in aggregate (inventory scales proportionally).
        uint256 rebaseAmount = profit * _totalSupply / circulating;
        uint256 newSupply = _totalSupply + rebaseAmount;
        if (newSupply > MAX_SUPPLY) newSupply = MAX_SUPPLY;
        _totalSupply = newSupply;
        gonsPerFragment = TOTAL_GONS / newSupply;
        emit LogRebase(epoch, rebaseAmount, _indexGons / gonsPerFragment);
        return newSupply;
    }

    // ── ERC-20 (gon-based) ──

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        if (allowed != type(uint256).max) {
            if (allowed < value) revert InsufficientAllowance();
            unchecked {
                allowance[from][msg.sender] = allowed - value;
            }
        }
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address from, address to, uint256 value) internal {
        if (to == address(0)) revert ZeroAddress();
        uint256 gons = value * gonsPerFragment;
        uint256 fromGons = _gonBalances[from];
        if (fromGons < gons) revert InsufficientBalance();
        unchecked {
            _gonBalances[from] = fromGons - gons;
        }
        _gonBalances[to] += gons;
        emit Transfer(from, to, value);
    }
}
