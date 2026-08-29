// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {IGenesisBond} from "@crane/contracts/protocols/pol/net/src/interfaces/IGenesisBond.sol";
import {INET} from "@crane/contracts/protocols/pol/net/src/interfaces/INET.sol";
import {ITreasury} from "@crane/contracts/protocols/pol/net/src/interfaces/ITreasury.sol";
import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";
import {IBondDepository} from "@crane/contracts/protocols/pol/net/src/interfaces/IBondDepository.sol";
import {IPairOracle} from "@crane/contracts/protocols/pol/net/src/interfaces/IPairOracle.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IUniswapV2Pair} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Pair.sol";
import {ShareCertificate} from "@crane/contracts/protocols/pol/net/src/ShareCertificate.sol";
import {Constants} from "@crane/contracts/protocols/pol/net/src/Constants.sol";
import {FixedPointMath} from "@crane/contracts/protocols/pol/net/src/libraries/FixedPointMath.sol";
import {Wired} from "@crane/contracts/protocols/pol/net/src/abstract/Wired.sol";

/// @title GenesisBond — founding shareholder subscription (specs/genesis.md)
/// @notice Fixed-price offering (3 USDG/NET); hard cap, wallet cap, sale
///         window, and min-raise floor are the R1-revised values in
///         Constants.sol (50k / 2k / 7d / 15k as of 2026-07-12), with
///         pull-based refunds below the floor and a soulbound receipt.
///         `finalize()` is the single atomic
///         switch that turns the protocol on: 70/30 treasury/POL split, seeds
///         the canonical v2 pool (direct pair.mint — immune to donation
///         griefing), enables staking + bonds + trading tax, and starts the
///         pTEAM vest / tax-decay clock.
contract GenesisBond is IGenesisBond, Wired {
    error SaleClosed();
    error SaleNotFailed();
    error HardCapExceeded();
    error WalletCapExceeded();
    error AlreadyFinalized();
    error CannotFinalize();
    error NotFinalized();
    error ZeroAmount();
    error TransferFailed();

    INET public immutable net;
    IERC20 public immutable usdg;
    ITreasury public immutable treasury;
    IStaking public immutable staking;
    IUniswapV2Pair public immutable pairContract;
    IPairOracle public immutable oracle;
    uint64 public immutable saleStart;
    uint64 public immutable saleDeadline;
    uint256 private immutable _usdgWadFactor;

    IBondDepository public bondDepository;
    ShareCertificate public certificate;

    bool public finalized;
    uint64 public finalizeTime;
    uint256 public raisedRaw;
    mapping(address => uint256) public purchasedRaw;
    mapping(address => uint256) public claimedNet;
    PurchaseRecord[] private _registry;

    constructor(
        address net_,
        address usdg_,
        address treasury_,
        address staking_,
        address pair_,
        address oracle_
    ) {
        net = INET(_nonZero(net_));
        usdg = IERC20(_nonZero(usdg_));
        treasury = ITreasury(_nonZero(treasury_));
        staking = IStaking(_nonZero(staking_));
        pairContract = IUniswapV2Pair(_nonZero(pair_));
        oracle = IPairOracle(_nonZero(oracle_));
        saleStart = uint64(block.timestamp);
        saleDeadline = uint64(block.timestamp + Constants.GENESIS_DEADLINE);
        _usdgWadFactor = 10 ** (18 - IERC20Metadata(usdg_).decimals());
    }

    /// @notice One-time wiring (BondDepository ↔ GenesisBond deploy cycle;
    ///         the certificate needs this contract's address at construction).
    function wire(address bondDepository_, address certificate_) external wiring {
        bondDepository = IBondDepository(_nonZero(bondDepository_));
        certificate = ShareCertificate(_nonZero(certificate_));
    }

    // ── Sale ──

    /// @inheritdoc IGenesisBond
    function purchase(uint256 usdgAmountRaw) external {
        _checkWired();
        if (usdgAmountRaw == 0) revert ZeroAmount();
        if (finalized || block.timestamp > saleDeadline) revert SaleClosed();

        uint256 amountWad = usdgAmountRaw * _usdgWadFactor;
        uint256 raisedWad = raisedRaw * _usdgWadFactor;
        if (raisedWad + amountWad > Constants.GENESIS_HARD_CAP_WAD) revert HardCapExceeded();
        uint256 walletWad = (purchasedRaw[msg.sender] + usdgAmountRaw) * _usdgWadFactor;
        if (walletWad > Constants.GENESIS_WALLET_CAP_WAD) revert WalletCapExceeded();

        if (!usdg.transferFrom(msg.sender, address(this), usdgAmountRaw)) revert TransferFailed();
        // Best-effort certificate (specs/genesis.md §1 FINAL): a certificate
        // failure must never revert a purchase; the registry always lands.
        // The code-length guard matters: with no return value bound, solc's
        // extcodesize existence check reverts in the CALLER's context and is
        // not caught by try/catch — a codeless certificate would brick the
        // sale without it.
        if (address(certificate).code.length != 0) {
            try certificate.recordPurchase(msg.sender, amountWad) {} catch {}
        }
        purchasedRaw[msg.sender] += usdgAmountRaw;
        raisedRaw += usdgAmountRaw;
        _registry.push(
            PurchaseRecord({
                purchaser: msg.sender,
                usdgAmountWad: uint96(amountWad),
                timestamp: uint64(block.timestamp)
            })
        );
        emit Purchased(
            msg.sender, amountWad, amountWad * Constants.NET_UNIT / Constants.GENESIS_PRICE_WAD
        );
    }

    /// @inheritdoc IGenesisBond
    function refund() external {
        if (finalized) revert SaleNotFailed();
        if (block.timestamp <= saleDeadline) revert SaleNotFailed();
        if (raisedRaw * _usdgWadFactor >= Constants.GENESIS_MIN_RAISE_WAD) revert SaleNotFailed();
        uint256 amount = purchasedRaw[msg.sender];
        if (amount == 0) revert ZeroAmount();
        purchasedRaw[msg.sender] = 0;
        if (!usdg.transfer(msg.sender, amount)) revert TransferFailed();
        emit Refunded(msg.sender, amount * _usdgWadFactor);
    }

    // ── The atomic switch (specs/genesis.md §2) ──

    /// @inheritdoc IGenesisBond
    function finalize() external {
        _checkWired();
        if (finalized) revert AlreadyFinalized();
        uint256 raisedWad = raisedRaw * _usdgWadFactor;
        bool capHit = raisedWad == Constants.GENESIS_HARD_CAP_WAD;
        bool deadlinePassed =
            block.timestamp > saleDeadline && raisedWad >= Constants.GENESIS_MIN_RAISE_WAD;
        if (!capHit && !deadlinePassed) revert CannotFinalize();

        finalized = true;
        finalizeTime = uint64(block.timestamp);

        // 1. ~70% of proceeds to the Treasury.
        uint256 treasuryRaw = raisedRaw * Constants.TREASURY_SPLIT_BPS / Constants.BPS;
        if (!usdg.transfer(address(treasury), treasuryRaw)) revert TransferFailed();

        // 2. Pair the remaining ~30% with newly minted NET at GENESIS_PRICE
        //    and seed the canonical v2 pool; LP to the Treasury. Direct
        //    transfer + pair.mint (not the router) so pre-finalize token
        //    donations to the pair cannot brick or skew the seed ratio we
        //    submit — any donated balance is simply absorbed into POL.
        uint256 polRaw = raisedRaw - treasuryRaw;
        uint256 polWad = polRaw * _usdgWadFactor;
        uint256 netForPol =
            FixedPointMath.mulDiv(polWad, Constants.NET_UNIT, Constants.GENESIS_PRICE_WAD);
        treasury.mintNet(address(this), netForPol);
        if (!net.transfer(address(pairContract), netForPol)) revert TransferFailed();
        if (!usdg.transfer(address(pairContract), polRaw)) revert TransferFailed();
        pairContract.mint(address(treasury));

        // 3. Mint the bonders' NET into the 5-day vesting escrow.
        uint256 netSold =
            FixedPointMath.mulDiv(raisedWad, Constants.NET_UNIT, Constants.GENESIS_PRICE_WAD);
        treasury.mintNet(address(this), netSold);

        // 4. Enable staking, standard bonds, and the trading tax; prime the
        //    oracle; the pTEAM vest + tax-decay clock starts at finalizeTime.
        staking.enable();
        bondDepository.enable();
        net.enableTax(address(pairContract));
        oracle.checkpoint();

        emit Finalized(raisedWad, treasuryRaw * _usdgWadFactor, polWad, address(pairContract));
    }

    // ── Vesting claims (5-day linear from finalize) ──

    /// @inheritdoc IGenesisBond
    function claim() external returns (uint256 netAmount) {
        if (!finalized) revert NotFinalized();
        netAmount = claimableNetOf(msg.sender);
        if (netAmount == 0) return 0;
        claimedNet[msg.sender] += netAmount;
        if (!net.transfer(msg.sender, netAmount)) revert TransferFailed();
        emit Claimed(msg.sender, netAmount);
    }

    /// @inheritdoc IGenesisBond
    function purchasedNetOf(address account) public view returns (uint256) {
        return FixedPointMath.mulDiv(
            purchasedRaw[account] * _usdgWadFactor, Constants.NET_UNIT, Constants.GENESIS_PRICE_WAD
        );
    }

    /// @inheritdoc IGenesisBond
    function claimableNetOf(address account) public view returns (uint256) {
        if (!finalized) return 0;
        uint256 total = purchasedNetOf(account);
        uint256 elapsed = block.timestamp - finalizeTime;
        uint256 vested =
            elapsed >= Constants.GENESIS_VEST ? total : total * elapsed / Constants.GENESIS_VEST;
        return vested - claimedNet[account];
    }

    /// @inheritdoc IGenesisBond
    function totalRaised() external view returns (uint256) {
        return raisedRaw * _usdgWadFactor;
    }

    /// @inheritdoc IGenesisBond
    function registryLength() external view returns (uint256) {
        return _registry.length;
    }

    /// @inheritdoc IGenesisBond
    function registryAt(uint256 i) external view returns (PurchaseRecord memory) {
        return _registry[i];
    }
}
