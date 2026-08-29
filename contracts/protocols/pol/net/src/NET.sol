// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {IUniswapV2Factory} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {IUniswapV3Factory} from "@crane/contracts/external/uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {Wired} from "@crane/contracts/protocols/pol/net/src/abstract/Wired.sol";

/// @title NET — NetNet reserve token
/// @notice ERC-20, 9 decimals, immutable 500 bps fee-on-transfer keyed to the
///         taxed AMM-pair mapping (specs/tax.md). Transfers to a mapped pair
///         (sell) or from a mapped pair (buy) accrue tax in NET to the
///         TaxCollector; wallet-to-wallet transfers are free. Minting is
///         Treasury-only. The only mutable surface post-wiring is the
///         guardian's ADD-ONLY key (Q7): instant pair additions, delayed
///         permanent exemption additions. No removal path exists.
contract NET is INET, Wired {
    error NotTreasury();
    error NotGenesisBond();
    error NotGuardian();
    error TaxAlreadyEnabled();
    error PairAlreadyMapped();
    error NotANetPool();
    error AlreadyExempt();
    error NothingQueued();
    error DelayNotElapsed();
    error CannotExemptPair();
    error InsufficientBalance();
    error InsufficientAllowance();

    string public constant name = "NetNet";
    string public constant symbol = "NET";
    uint8 public constant decimals = 9;

    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /// @notice The add-only tax key (team multisig — Q7).
    address public immutable guardian;

    address public treasury;
    address public taxCollector;
    address public genesisBond;
    address public canonicalPair;
    /// @notice Canonical factories used to validate pair additions on-chain
    ///         (specs/tax.md §1 FINAL): the setter can only ever map a
    ///         genuine NET pool, never an arbitrary address.
    address public uniswapV2Factory;
    address public uniswapV3Factory;
    bool public taxEnabled;

    mapping(address => bool) public isTaxedPair;
    mapping(address => bool) public isTaxExempt;
    /// @notice queued exemption → timestamp at which it becomes executable.
    mapping(address => uint64) public exemptQueuedAt;

    constructor(address guardian_) {
        guardian = _nonZero(guardian_);
    }

    /// @notice One-time wiring (see Wired). `initialTaxedPairs` implements the
    ///         Q8 pre-mapping of predicted bypass-pool addresses (deploy-time
    ///         CREATE2 predictions — pools that do not exist yet cannot be
    ///         factory-validated, so pre-mapping is a wiring-only privilege).
    function wire(
        address treasury_,
        address taxCollector_,
        address genesisBond_,
        address uniswapV2Factory_,
        address uniswapV3Factory_,
        address[] calldata initialExempt,
        address[] calldata initialTaxedPairs
    ) external wiring {
        treasury = _nonZero(treasury_);
        taxCollector = _nonZero(taxCollector_);
        genesisBond = _nonZero(genesisBond_);
        uniswapV2Factory = _nonZero(uniswapV2Factory_);
        uniswapV3Factory = _nonZero(uniswapV3Factory_);
        for (uint256 i = 0; i < initialExempt.length; i++) {
            isTaxExempt[_nonZero(initialExempt[i])] = true;
            emit TaxExemptAdded(initialExempt[i]);
        }
        for (uint256 i = 0; i < initialTaxedPairs.length; i++) {
            isTaxedPair[_nonZero(initialTaxedPairs[i])] = true;
            emit TaxedPairAdded(initialTaxedPairs[i]);
        }
    }

    // ── ERC-20 ──

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
        _spendAllowance(from, msg.sender, value);
        _transfer(from, to, value);
        return true;
    }

    function _spendAllowance(address owner, address spender, uint256 value) internal {
        uint256 allowed = allowance[owner][spender];
        if (allowed != type(uint256).max) {
            if (allowed < value) revert InsufficientAllowance();
            unchecked {
                allowance[owner][spender] = allowed - value;
            }
        }
    }

    /// @dev The fee-on-transfer core. Exactly one 500 bps tax per taxed leg;
    ///      sum of received + taxed always equals sent (specs/tax.md §5).
    function _transfer(address from, address to, uint256 value) internal {
        if (to == address(0)) revert ZeroAddress();
        uint256 fromBal = balanceOf[from];
        if (fromBal < value) revert InsufficientBalance();
        unchecked {
            balanceOf[from] = fromBal - value;
        }

        uint256 tax = 0;
        if (
            taxEnabled && !isTaxExempt[from] && !isTaxExempt[to]
                && (isTaxedPair[from] || isTaxedPair[to])
        ) {
            tax = value * Constants.TAX_TOTAL_BPS / Constants.BPS;
            if (tax != 0) {
                balanceOf[taxCollector] += tax;
                emit Transfer(from, taxCollector, tax);
                emit TaxCollected(from, isTaxedPair[to] ? to : from, tax);
            }
        }
        uint256 received = value - tax;
        balanceOf[to] += received;
        emit Transfer(from, to, received);
    }

    // ── Mint / burn ──

    function mint(address to, uint256 amount) external {
        _checkWired();
        if (msg.sender != treasury) revert NotTreasury();
        if (to == address(0)) revert ZeroAddress();
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) external {
        _spendAllowance(from, msg.sender, amount);
        _burn(from, amount);
    }

    function _burn(address from, uint256 amount) internal {
        uint256 bal = balanceOf[from];
        if (bal < amount) revert InsufficientBalance();
        unchecked {
            balanceOf[from] = bal - amount;
            totalSupply -= amount;
        }
        emit Transfer(from, address(0), amount);
    }

    // ── Tax administration (add-only — Q7) ──

    function taxTotalBps() external pure returns (uint256) {
        return Constants.TAX_TOTAL_BPS;
    }

    /// @inheritdoc INET
    function enableTax(address canonicalPair_) external {
        _checkWired();
        if (msg.sender != genesisBond) revert NotGenesisBond();
        if (taxEnabled) revert TaxAlreadyEnabled();
        canonicalPair = _nonZero(canonicalPair_);
        isTaxedPair[canonicalPair_] = true;
        taxEnabled = true;
        emit TaxedPairAdded(canonicalPair_);
        emit TaxEnabled(canonicalPair_);
    }

    /// @inheritdoc INET
    /// @dev On-chain pool validation (specs/tax.md §1 FINAL): the submitted
    ///      address must be a live pool on a canonical factory with NET as
    ///      one of its tokens. Worst case of a compromised key is mapping a
    ///      legitimate NET venue — the setter's intended function.
    function addTaxedPair(address pair, PoolKind kind, uint24 v3Fee) external {
        if (msg.sender != guardian) revert NotGuardian();
        if (isTaxedPair[_nonZero(pair)]) revert PairAlreadyMapped();
        // A pair must never be exempt (and vice versa): exempting the pair
        // would permanently zero the tax on it (mechanism §6.7).
        if (isTaxExempt[pair] || exemptQueuedAt[pair] != 0) revert CannotExemptPair();
        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();
        if (token0 != address(this) && token1 != address(this)) revert NotANetPool();
        if (kind == PoolKind.UniswapV2) {
            if (IUniswapV2Factory(uniswapV2Factory).getPair(token0, token1) != pair) {
                revert NotANetPool();
            }
        } else {
            if (IUniswapV3Factory(uniswapV3Factory).getPool(token0, token1, v3Fee) != pair) {
                revert NotANetPool();
            }
        }
        isTaxedPair[pair] = true;
        emit TaxedPairAdded(pair);
    }

    /// @inheritdoc INET
    /// @dev Pairs can never be exempted (checked here AND at execute time) —
    ///      a compromised key must not be able to zero the tax on a venue
    ///      (mechanism §6.7). The queue is cancellable: cancelling an
    ///      exemption that never took effect does not violate add-only.
    function queueTaxExempt(address account) external {
        if (msg.sender != guardian) revert NotGuardian();
        if (isTaxExempt[_nonZero(account)]) revert AlreadyExempt();
        if (isTaxedPair[account]) revert CannotExemptPair();
        uint64 executableAt = uint64(block.timestamp + Constants.EXEMPT_DELAY);
        exemptQueuedAt[account] = executableAt;
        emit TaxExemptQueued(account, executableAt);
    }

    /// @inheritdoc INET
    function cancelTaxExempt(address account) external {
        if (msg.sender != guardian) revert NotGuardian();
        if (exemptQueuedAt[account] == 0) revert NothingQueued();
        delete exemptQueuedAt[account];
        emit TaxExemptCancelled(account);
    }

    /// @inheritdoc INET
    function executeTaxExempt(address account) external {
        uint64 executableAt = exemptQueuedAt[account];
        if (executableAt == 0) revert NothingQueued();
        if (block.timestamp < executableAt) revert DelayNotElapsed();
        if (isTaxedPair[account]) revert CannotExemptPair();
        delete exemptQueuedAt[account];
        isTaxExempt[account] = true;
        emit TaxExemptAdded(account);
    }
}
