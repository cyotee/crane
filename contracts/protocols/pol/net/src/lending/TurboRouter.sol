// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.24;

import {LendingConstants} from "@crane/contracts/protocols/pol/net/src/lending/LendingConstants.sol";
import {IMorpho, Id, MarketParams, Market, Position} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {
    IMorphoSupplyCollateralCallback,
    IMorphoRepayCallback
} from "@crane/contracts/external/morpho/blue/interfaces/IMorphoCallbacks.sol";
import {IOracle} from "@crane/contracts/external/morpho/blue/interfaces/IOracle.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IUniswapV2Router02} from "@crane/contracts/interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router02.sol";
import {IStaking} from "@crane/contracts/protocols/pol/net/src/interfaces/IStaking.sol";

/// @notice Minimal wsNET surface the router composes.
interface IWsNET {
    function wrap(uint256 sNetAmount) external returns (uint256 wsOut);
    function unwrap(uint256 wsAmount) external returns (uint256 sNetOut);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

/// @notice Minimal Zap surface (NET → stake → wrap, specs/perp.md §2).
interface IZap {
    function zap(uint256 netAmount) external returns (uint256 wsOut);
}

/// @title TurboRouter — Loopback loop/unwind in one transaction each
/// @notice specs/lending.md §4. Stateless between transactions, immutable,
///         permissionless, no owner, holds no funds after any call. Uses
///         Morpho Blue callbacks (no flash loans):
///
///         - `turbo`: supply wsNET collateral and, in the same transaction,
///           borrow USDG → buy NET on the canonical v2 pair (5% tax fires,
///           by design) → Zap (stake + wrap) → the looped wsNET lands as
///           additional collateral. Refuses to leave the position above
///           TARGET_LTV (53.125% — 85% of LLTV; UX guardrail, not a
///           protocol cap).
///         - `unwind`: repay USDG debt and, in the same transaction, free
///           wsNET collateral → unwrap → unstake → sell NET on the pair
///           (5% tax fires) → repay from proceeds, surplus USDG to caller.
///
///         One-time setup per user: `morpho.setAuthorization(router, true)`
///         so the router may borrow / withdraw collateral on their behalf.
///
///         Migration to a successor market (specs/lending.md §1.3) is
///         implemented by the SUCCESSOR's router (close-here / reopen-there
///         under the same authorization pattern), not by this contract.
contract TurboRouter is IMorphoSupplyCollateralCallback, IMorphoRepayCallback {
    error NotMorpho();
    error NoOpInFlight();
    error OpInFlight();
    error SlippageExceeded();
    error InsufficientProceeds();
    error AboveTargetLtv();
    error ZeroAmount();
    error TransferFailed();

    event Turbo(
        address indexed account,
        uint256 wsIn,
        uint256 usdgBorrowed,
        uint256 wsLooped,
        uint256 wsSurplusReturned
    );
    event Unwind(
        address indexed account, uint256 usdgRepaid, uint256 wsFreed, uint256 usdgSurplusReturned
    );

    uint256 private constant OP_NONE = 0;
    uint256 private constant OP_TURBO = 1;
    uint256 private constant OP_UNWIND = 2;

    IMorpho public immutable morpho;
    IERC20 public immutable usdg;
    IERC20 public immutable net;
    IERC20 public immutable sNet;
    IStaking public immutable staking;
    IWsNET public immutable wsNet;
    IZap public immutable zap;
    IUniswapV2Router02 public immutable swapRouter;

    // Market params (immutable market: fields stored individually).
    address public immutable oracle;
    address public immutable irm;
    uint256 public immutable lltv;
    bytes32 public immutable marketId;

    /// @dev Callback guard: which operation is in flight this transaction.
    uint256 private _op;

    constructor(
        address morpho_,
        address usdg_,
        address net_,
        address sNet_,
        address staking_,
        address wsNet_,
        address zap_,
        address swapRouter_,
        address oracle_,
        address irm_
    ) {
        morpho = IMorpho(morpho_);
        usdg = IERC20(usdg_);
        net = IERC20(net_);
        sNet = IERC20(sNet_);
        staking = IStaking(staking_);
        wsNet = IWsNET(wsNet_);
        zap = IZap(zap_);
        swapRouter = IUniswapV2Router02(swapRouter_);
        oracle = oracle_;
        irm = irm_;
        lltv = LendingConstants.LLTV;
        marketId = keccak256(
            abi.encode(
                MarketParams({
                    loanToken: usdg_,
                    collateralToken: wsNet_,
                    oracle: oracle_,
                    irm: irm_,
                    lltv: LendingConstants.LLTV
                })
            )
        );

        // One-time unlimited approvals to the fixed, trusted contracts this
        // router composes (mirrors the Zap pattern).
        IERC20(usdg_).approve(morpho_, type(uint256).max); // repay pulls
        IERC20(usdg_).approve(swapRouter_, type(uint256).max); // loop buys
        IERC20(net_).approve(zap_, type(uint256).max); // loop zaps
        IERC20(net_).approve(swapRouter_, type(uint256).max); // unwind sells
        IERC20(sNet_).approve(staking_, type(uint256).max); // unwind unstakes
        IWsNET(wsNet_).approve(morpho_, type(uint256).max); // collateral pulls
    }

    function marketParams() public view returns (MarketParams memory) {
        return MarketParams({
            loanToken: address(usdg),
            collateralToken: address(wsNet),
            oracle: oracle,
            irm: irm,
            lltv: lltv
        });
    }

    // ── Loop ──

    /// @notice One-transaction loop: supplies `wsIn` from the caller plus at
    ///         least `minWsFromLoop` bought with `borrowAssets` of fresh USDG
    ///         debt. Any loop output above `minWsFromLoop` is returned to the
    ///         caller as wsNET (it can be re-Turbo'd; slippage protection and
    ///         the collateral commitment must be exact at supply time).
    /// @param wsIn          wsNET pulled from the caller (may be 0 when
    ///                      adding leverage to an existing position).
    /// @param borrowAssets  USDG borrowed against the position (may be 0 for
    ///                      a plain collateral deposit).
    /// @param minWsFromLoop minimum wsNET the borrow→buy→zap leg must
    ///                      produce (the slippage bound; 0 when borrowAssets
    ///                      is 0).
    function turbo(uint256 wsIn, uint256 borrowAssets, uint256 minWsFromLoop) external {
        if (wsIn == 0 && borrowAssets == 0) revert ZeroAmount();
        if (borrowAssets == 0 && minWsFromLoop != 0) revert ZeroAmount();
        if (_op != OP_NONE) revert OpInFlight();
        _settleRebase();
        _op = OP_TURBO;

        morpho.supplyCollateral(
            marketParams(),
            wsIn + minWsFromLoop,
            msg.sender,
            abi.encode(msg.sender, wsIn, borrowAssets, minWsFromLoop)
        );
        _op = OP_NONE;

        // Never leave the position above the Turbo target advance rate
        // (specs/lending.md §5; interest is current — borrow accrued it).
        if (borrowAssets != 0 && _currentLtvWad(msg.sender) > LendingConstants.TARGET_LTV_WAD) {
            revert AboveTargetLtv();
        }
    }

    /// @inheritdoc IMorphoSupplyCollateralCallback
    function onMorphoSupplyCollateral(uint256, bytes calldata data) external {
        if (msg.sender != address(morpho)) revert NotMorpho();
        if (_op != OP_TURBO) revert NoOpInFlight();

        (address account, uint256 wsIn, uint256 borrowAssets, uint256 minWsFromLoop) =
            abi.decode(data, (address, uint256, uint256, uint256));

        if (wsIn != 0) {
            if (!wsNet.transferFrom(account, address(this), wsIn)) revert TransferFailed();
        }

        uint256 wsLooped;
        if (borrowAssets != 0) {
            // Collateral is already credited pre-callback, so the position
            // supports this borrow; Morpho enforces LLTV health here.
            morpho.borrow(marketParams(), borrowAssets, 0, account, address(this));

            // USDG → NET through the canonical (taxed, FoT-supporting) path.
            address[] memory path = new address[](2);
            path[0] = address(usdg);
            path[1] = address(net);
            swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                borrowAssets, 0, path, address(this), block.timestamp
            );

            wsLooped = zap.zap(net.balanceOf(address(this)));
            if (wsLooped < minWsFromLoop) revert SlippageExceeded();
            uint256 surplus = wsLooped - minWsFromLoop;
            if (surplus != 0) {
                if (!wsNet.transfer(account, surplus)) revert TransferFailed();
            }
            emit Turbo(account, wsIn, borrowAssets, wsLooped, surplus);
        } else {
            emit Turbo(account, wsIn, 0, 0, 0);
        }
        // Morpho now pulls exactly wsIn + minWsFromLoop from this contract.
    }

    // ── Unwind ──

    /// @notice One-transaction unwind: repays `repayShares` of the caller's
    ///         debt from the sale of `wsCollateralOut` freed collateral
    ///         (unwrap → unstake → taxed pair sale). Surplus USDG is
    ///         returned to the caller; pass the position's full borrowShares
    ///         and full collateral for a complete close.
    /// @param repayShares     borrow shares to repay (exact full close:
    ///                        the position's borrowShares).
    /// @param wsCollateralOut wsNET collateral to free and sell.
    /// @param minUsdgFromSale minimum sale proceeds (slippage bound).
    function unwind(uint256 repayShares, uint256 wsCollateralOut, uint256 minUsdgFromSale)
        external
    {
        if (repayShares == 0 || wsCollateralOut == 0) revert ZeroAmount();
        if (_op != OP_NONE) revert OpInFlight();
        _op = OP_UNWIND;

        morpho.repay(
            marketParams(),
            0,
            repayShares,
            msg.sender,
            abi.encode(msg.sender, wsCollateralOut, minUsdgFromSale)
        );
        _op = OP_NONE;
    }

    /// @inheritdoc IMorphoRepayCallback
    function onMorphoRepay(uint256 assets, bytes calldata data) external {
        if (msg.sender != address(morpho)) revert NotMorpho();
        if (_op != OP_UNWIND) revert NoOpInFlight();

        (address account, uint256 wsCollateralOut, uint256 minUsdgFromSale) =
            abi.decode(data, (address, uint256, uint256));

        // Debt is already reduced pre-callback, so freeing collateral passes
        // Morpho's health check at the post-repay debt level.
        morpho.withdrawCollateral(marketParams(), wsCollateralOut, account, address(this));

        wsNet.unwrap(wsCollateralOut);
        // Unstake until empty: every staking touch advances AT MOST ONE
        // pending rebase epoch, growing sNET balances mid-call — a single
        // balance read would strand that growth as router dust whenever the
        // epoch clock is behind. Iterations are bounded by pending epochs
        // (≤ 1 with a live keeper).
        staking.rebase();
        uint256 sNetBal = sNet.balanceOf(address(this));
        while (sNetBal != 0) {
            staking.unstake(address(this), sNetBal);
            sNetBal = sNet.balanceOf(address(this));
        }

        // NET → USDG through the canonical (taxed, FoT-supporting) path.
        address[] memory path = new address[](2);
        path[0] = address(net);
        path[1] = address(usdg);
        swapRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            net.balanceOf(address(this)), 0, path, address(this), block.timestamp
        );

        uint256 proceeds = usdg.balanceOf(address(this));
        if (proceeds < minUsdgFromSale) revert SlippageExceeded();
        if (proceeds < assets) revert InsufficientProceeds();
        uint256 surplus = proceeds - assets;
        if (surplus != 0) {
            if (!usdg.transfer(account, surplus)) revert TransferFailed();
        }
        emit Unwind(account, assets, wsCollateralOut, surplus);
        // Morpho now pulls exactly `assets` USDG from this contract.
    }

    /// @dev Settles pending rebase epochs (bounded) BEFORE any quoted work:
    ///      the zap's stake advances an epoch mid-transaction otherwise,
    ///      jumping the dividend index between the caller's quote and the
    ///      wrap — shrinking the wsNET fill against `minWsFromLoop` through
    ///      no fault of the quote. One pending epoch is the norm with a live
    ///      keeper; the cap only bounds pathological backlogs.
    function _settleRebase() internal {
        for (uint256 i; i < 8; ++i) {
            (,, uint64 end,) = staking.epoch();
            if (block.timestamp < end) break;
            staking.rebase();
        }
    }

    // ── Views ──

    /// @notice Current advance rate (LTV) of `account`, WAD. 0 when no debt.
    function _currentLtvWad(address account) internal view returns (uint256) {
        Position memory pos = morpho.position(Id.wrap(marketId), account);
        if (pos.borrowShares == 0) return 0;
        Market memory mkt = morpho.market(Id.wrap(marketId));
        // Round debt up (conservative).
        uint256 debt =
            (uint256(pos.borrowShares) * mkt.totalBorrowAssets + mkt.totalBorrowShares - 1)
                / mkt.totalBorrowShares;
        uint256 collateralLoanUnits = uint256(pos.collateral) * IOracle(oracle).price() / 1e36;
        if (collateralLoanUnits == 0) return type(uint256).max;
        return debt * 1e18 / collateralLoanUnits;
    }

    /// @notice Public LTV view for the app/keeper.
    function currentLtvWad(address account) external view returns (uint256) {
        return _currentLtvWad(account);
    }
}
