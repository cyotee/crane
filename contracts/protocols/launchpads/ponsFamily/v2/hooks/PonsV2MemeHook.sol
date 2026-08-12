// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Ownable} from "@crane/contracts/external/openzeppelin-contracts-v5/access/Ownable.sol";
import {Ownable2Step} from "@crane/contracts/external/openzeppelin-contracts-v5/access/Ownable2Step.sol";
import {ReentrancyGuard} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/ReentrancyGuard.sol";
import {SafeCast} from "@crane/contracts/external/openzeppelin-contracts-v5/utils/math/SafeCast.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/IERC20.sol";
import {SafeERC20} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/utils/SafeERC20.sol";

import {IHooks} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IHooks.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {IUnlockCallback} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/callback/IUnlockCallback.sol";
import {Hooks} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/Hooks.sol";
import {StateLibrary} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/StateLibrary.sol";
import {TickMath} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/TickMath.sol";
import {FullMath} from "@crane/contracts/protocols/dexes/uniswap/libraries/FullMath.sol";
import {PoolKey} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";
import {PoolId} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolId.sol";
import {Currency} from "@crane/contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {BalanceDelta} from "@crane/contracts/protocols/dexes/uniswap/v4/types/BalanceDelta.sol";
import {SwapParams} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolOperation.sol";
import {BaseHook} from "@crane/contracts/protocols/dexes/uniswap/v4/hooks/public/base/BaseHook.sol";

import {PonsV2BuybackVault} from "../PonsV2BuybackVault.sol";
import {FeePolicySnapshot, IPonsV2FeeEscrow, IPonsV2FeePolicy} from "../interfaces/ILaunchpadV2.sol";

/**
 * @title PonsV2MemeHook
 * @notice Singleton Uniswap V4 hook shared by every graduated pons v2 pool.
 * Takes a fee cut on every swap via `afterSwap` (Flaunch-style Internal Swap
 * Pool), and whenever that cut lands in the memecoin, converts it back to
 * the pool's quote currency (ETH for the common native pairToken, or the
 * launch's chosen ERC-20 pairToken otherwise) against the pool's own
 * liquidity before it is ever distributed. The same protocol / creator /
 * buyback-and-burn split that governs PonsV2BondingCurve's pre-graduation
 * fee sweep lives here, read live by the curve through IPonsV2FeePolicy so
 * both phases behave identically.
 */
contract PonsV2MemeHook is BaseHook, IUnlockCallback, IPonsV2FeePolicy, Ownable2Step, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum SwapDirection {
        MemecoinToQuote,
        QuoteToMemecoin
    }

    struct LaunchInfo {
        bool registered;
        bool memecoinIsCurrency0;
        address memecoin;
        address quoteToken; // address(0) denotes native ETH
        address creator;
        // Buyback locks retain this recipient even when future immediate
        // creator payouts are transferred to a different address.
        address buybackCreatorRecipient;
        address protocolFeeRecipient;
        // Creator-chosen at launch on PonsV2LaunchFactory, snapshotted here
        // at registerPool time. Charged the same way hookFeeBps is, but paid
        // entirely to the creator, bypassing the protocol/buyback split.
        uint16 creatorTaxBps;
        uint16 protocolFeeShareBps;
        uint16 buybackBurnBps;
        uint16 hookFeeBps;
        uint16 maxInternalPriceImpactBps;
        bool buybackEnabled;
    }

    uint256 private constant BASIS_POINTS = 10_000;
    uint256 private constant MAX_PROTOCOL_FEE_SHARE_BPS = 5_000;
    uint256 private constant MAX_HOOK_FEE_BPS = 1_000;
    // Mirrors PonsV2BondingCurve's own ceiling, so a graduated pool can never
    // charge more per trade than the curve it graduated from.
    uint256 private constant MAX_TOTAL_TRADE_FEE_BPS = 2_000;

    error NotFactory();
    error AlreadySet();
    error OwnershipCannotBeRenounced();
    error ZeroAddress();
    error InvalidBps();
    error AlreadyRegistered();
    error UnknownPool();
    error InvalidPoolKey();
    error NotFeeSweepOperator();
    error InternalSwapRequiresOperator();
    error SlippageExceeded(uint256 actual, uint256 minimum);
    error MinimumOutputRequired();
    error InexactQuoteTransfer(address token, uint256 expected, uint256 received);
    error NothingToRescue();

    event FactorySet(address factory);
    event PoolRegistered(PoolId indexed poolId, address memecoin, address quoteToken, address creator);
    event CreatorFeeRecipientUpdated(
        PoolId indexed poolId, address indexed previousRecipient, address indexed newRecipient
    );
    // Reported separately because the two accrue to different ledgers: the
    // fee splits across protocol, buyback and creator on sweep, while the tax
    // is paid to the creator in full.
    event HookFeeCollected(PoolId indexed poolId, address currency, uint256 feeAmount, uint256 taxAmount);
    event PoolFeesSwept(
        PoolId indexed poolId,
        uint256 protocolAmount,
        uint256 buybackAmount,
        uint256 creatorAmount,
        uint256 tokensLocked
    );
    event PoolFeesRescued(
        PoolId indexed poolId, address indexed quoteToken, uint256 protocolAmount, uint256 creatorAmount
    );
    event PoolBuybackSkipped(PoolId indexed poolId, uint256 foldedBackQuote);
    event PoolConversionSkipped(PoolId indexed poolId, uint256 retainedMemecoin);
    event BuybackVaultSet(address vault);
    event ProtocolFeeShareUpdated(uint256 bps);
    event BuybackBurnBpsUpdated(uint256 bps);
    event HookFeeBpsUpdated(uint256 bps);
    event MaxInternalPriceImpactUpdated(uint256 bps);
    event ProtocolFeeRecipientUpdated(address recipient);
    event FeeSweepOperatorUpdated(address operator);
    event BuybackEnabledUpdated(PoolId indexed poolId, bool enabled);

    IPonsV2FeeEscrow public immutable feeEscrow;

    address public factory;
    PonsV2BuybackVault public buybackVault;
    address public protocolFeeRecipient;
    uint256 public protocolFeeShareBps;
    uint256 public buybackBurnBps;
    uint256 public hookFeeBps;
    uint256 public maxInternalPriceImpactBps;
    address public feeSweepOperator;

    mapping(PoolId => LaunchInfo) public launches;
    mapping(PoolId => PoolKey) private _poolKeys;
    mapping(PoolId => mapping(address currency => uint256 amount)) public pendingFees;
    // Tracked separately from pendingFees so the creator tax never enters
    // the protocol/buyback split math; it is folded straight into the
    // creator's payout at sweep time.
    mapping(PoolId => mapping(address currency => uint256 amount)) public pendingCreatorTax;
    // The slice of pendingFees already earmarked for buyback-and-lock, set
    // aside as each swap's fee was charged under whatever the pool's buyback
    // flag said at that moment. Bucketing at accrual rather than deriving the
    // slice at sweep time keeps the flag forward-looking: toggling it decides
    // how the next swap's fee is split, never how an already-charged one is.
    // Held per currency and carried across the memecoin-to-quote conversion
    // in proportion to the fee it rode in on, so an earmark accrued in the
    // memecoin still reaches the vest.
    mapping(PoolId => mapping(address currency => uint256 amount)) public pendingBuyback;

    modifier onlyFactory() {
        if (msg.sender != factory) revert NotFactory();
        _;
    }

    /**
     * @param poolManager_ The canonical Uniswap V4 pool manager.
     * @param feeEscrow_ Shared claimable balance ledger, also used by every bonding curve.
     * @param protocolFeeRecipient_ Escrow key credited with the protocol's share.
     * @param initialOwner_ Protocol deployer; the only address that can ever change fee policy.
     */
    constructor(
        IPoolManager poolManager_,
        IPonsV2FeeEscrow feeEscrow_,
        address protocolFeeRecipient_,
        address initialOwner_
    ) BaseHook(poolManager_) Ownable(initialOwner_) {
        if (address(poolManager_) == address(0) || address(feeEscrow_) == address(0)) {
            revert ZeroAddress();
        }
        if (protocolFeeRecipient_ == address(0)) revert ZeroAddress();

        feeEscrow = feeEscrow_;
        protocolFeeRecipient = protocolFeeRecipient_;
        protocolFeeShareBps = 3_000;
        buybackBurnBps = 5_000;
        hookFeeBps = 100;
        maxInternalPriceImpactBps = 300;
        feeSweepOperator = initialOwner_;
    }

    /**
     * @notice Only `afterSwap` is enabled: fee collection happens once per
     * swap, after the pool's own core swap math has already run.
     */
    function getHookPermissions() public pure override returns (Hooks.Permissions memory) {
        return Hooks.Permissions({
            beforeInitialize: true,
            afterInitialize: false,
            beforeAddLiquidity: false,
            afterAddLiquidity: false,
            beforeRemoveLiquidity: false,
            afterRemoveLiquidity: false,
            beforeSwap: false,
            afterSwap: true,
            beforeDonate: false,
            afterDonate: false,
            beforeSwapReturnDelta: false,
            afterSwapReturnDelta: true,
            afterAddLiquidityReturnDelta: false,
            afterRemoveLiquidityReturnDelta: false
        });
    }

    // ---------------------------------------------------------------------
    // Owner-only configuration
    // ---------------------------------------------------------------------

    /**
     * @notice One-time wiring of the v2 factory, set after both are deployed
     * since the factory needs this hook's mined address to build pool keys.
     */
    function setFactory(address factory_) external onlyOwner {
        if (factory != address(0)) revert AlreadySet();
        if (factory_ == address(0)) revert ZeroAddress();
        factory = factory_;
        emit FactorySet(factory_);
    }

    /**
     * @notice One-time wiring of the shared five-year buyback vest, set
     * after both are deployed, so `_distribute` can lock the buyback leg
     * into it instead of burning it.
     */
    function setBuybackVault(PonsV2BuybackVault buybackVault_) external onlyOwner {
        if (address(buybackVault) != address(0)) revert AlreadySet();
        if (address(buybackVault_) == address(0)) revert ZeroAddress();
        buybackVault = buybackVault_;
        emit BuybackVaultSet(address(buybackVault_));
    }

    /**
     * @notice Permanently disabled. An ownerless hook could never rotate the
     * fee sweep operator, so accrued fees on every graduated pool would stay
     * stranded. Ownership can still be transferred to a new owner.
     */
    function renounceOwnership() public pure override {
        revert OwnershipCannotBeRenounced();
    }

    function setProtocolFeeShareBps(uint256 bps) external onlyOwner {
        if (bps > MAX_PROTOCOL_FEE_SHARE_BPS) revert InvalidBps();
        protocolFeeShareBps = bps;
        emit ProtocolFeeShareUpdated(bps);
    }

    function setBuybackBurnBps(uint256 bps) external onlyOwner {
        if (bps > BASIS_POINTS) revert InvalidBps();
        buybackBurnBps = bps;
        emit BuybackBurnBpsUpdated(bps);
    }

    function setHookFeeBps(uint256 bps) external onlyOwner {
        if (bps > MAX_HOOK_FEE_BPS) revert InvalidBps();
        hookFeeBps = bps;
        emit HookFeeBpsUpdated(bps);
    }

    function setMaxInternalPriceImpactBps(uint256 bps) external onlyOwner {
        if (bps == 0 || bps >= BASIS_POINTS) revert InvalidBps();
        maxInternalPriceImpactBps = bps;
        emit MaxInternalPriceImpactUpdated(bps);
    }

    function setProtocolFeeRecipient(address recipient) external onlyOwner {
        if (recipient == address(0)) revert ZeroAddress();
        protocolFeeRecipient = recipient;
        emit ProtocolFeeRecipientUpdated(recipient);
    }

    /**
     * @notice Sets the trusted operator that executes fee conversions with
     * explicit minimum outputs, preventing arbitrary callers from triggering
     * predictable swaps against a manipulated spot price.
     */
    function setFeeSweepOperator(address operator) external onlyOwner {
        if (operator == address(0)) revert ZeroAddress();
        feeSweepOperator = operator;
        emit FeeSweepOperatorUpdated(operator);
    }

    /**
     * @notice Returns the policy terms new launches snapshot immutably.
     */
    function currentFeePolicy() external view override returns (FeePolicySnapshot memory) {
        return _currentFeePolicy();
    }

    function _currentFeePolicy() private view returns (FeePolicySnapshot memory) {
        return FeePolicySnapshot({
            protocolFeeRecipient: protocolFeeRecipient,
            protocolFeeShareBps: uint16(protocolFeeShareBps),
            buybackBurnBps: uint16(buybackBurnBps),
            hookFeeBps: uint16(hookFeeBps),
            maxInternalPriceImpactBps: uint16(maxInternalPriceImpactBps)
        });
    }

    // ---------------------------------------------------------------------
    // Factory wiring
    // ---------------------------------------------------------------------

    /**
     * @notice Registers a pool with fee terms frozen at launch by the factory.
     * @dev `buybackCreatorRecipient` is the creator recipient the curve was
     * constructed with, passed so the vest this pool tops up lands in the
     * same vault epoch as any tranche the curve locked pre-graduation.
     *
     * It is not immutable in effect. The vault only reads it to seed an empty
     * slot, and the factory forwards every later creator-fee-recipient
     * rotation into `updateCreatorRecipient`, so the live beneficiary follows
     * the creator fee stream. That is deliberate: it is what lets a
     * compromised creator key be recovered without orphaning the vest.
     */
    function registerPool(
        PoolKey calldata key,
        address memecoin,
        address creator,
        address buybackCreatorRecipient,
        uint16 creatorTaxBps,
        bool buybackEnabled,
        FeePolicySnapshot calldata policy
    ) external onlyFactory {
        _registerPool(key, memecoin, creator, buybackCreatorRecipient, creatorTaxBps, buybackEnabled, policy);
    }

    /// @dev Args for `_registerPool` so policy + addresses do not all live on the stack.
    struct RegisterPoolArgs {
        address memecoin;
        address creator;
        address buybackCreatorRecipient;
        uint16 creatorTaxBps;
        bool buybackEnabled;
        FeePolicySnapshot policy;
    }

    function _registerPool(
        PoolKey calldata key,
        address memecoin,
        address creator,
        address buybackCreatorRecipient,
        uint16 creatorTaxBps,
        bool buybackEnabled,
        FeePolicySnapshot memory policy
    ) private {
        RegisterPoolArgs memory args = RegisterPoolArgs({
            memecoin: memecoin,
            creator: creator,
            buybackCreatorRecipient: buybackCreatorRecipient,
            creatorTaxBps: creatorTaxBps,
            buybackEnabled: buybackEnabled,
            policy: policy
        });
        _registerPoolWithArgs(key, args);
    }

    function _registerPoolWithArgs(PoolKey calldata key, RegisterPoolArgs memory args) private {
        PoolId poolId = key.toId();
        if (launches[poolId].registered) revert AlreadyRegistered();
        if (args.creator == address(0) || args.buybackCreatorRecipient == address(0)) revert ZeroAddress();
        // Terms frozen here govern the pool for life, so each is held to the
        // same ceiling as the setter that produced it. protocolFeeShareBps
        // against BASIS_POINTS rather than MAX_PROTOCOL_FEE_SHARE_BPS would
        // let a pool be registered on terms the live policy could never
        // reach, paying the creator nothing.
        if (
            args.policy.protocolFeeRecipient == address(0)
                || args.policy.protocolFeeShareBps > MAX_PROTOCOL_FEE_SHARE_BPS
                || args.policy.buybackBurnBps > BASIS_POINTS || args.policy.hookFeeBps > MAX_HOOK_FEE_BPS
                || args.policy.maxInternalPriceImpactBps == 0
                || args.policy.maxInternalPriceImpactBps >= BASIS_POINTS
        ) {
            revert InvalidBps();
        }
        // The curve bounds the same sum in its own constructor rather than
        // inheriting it from the factory. A pool taking more than the whole
        // unspecified leg would flip the swapper's output delta negative.
        if (uint256(args.creatorTaxBps) + args.policy.hookFeeBps > MAX_TOTAL_TRADE_FEE_BPS) revert InvalidBps();

        // The factory builds the key correctly today, but these two facts are
        // what every later fee credit and swap direction is derived from. A
        // memecoin that is neither currency would silently designate the wrong
        // side as quote and route fees to a slot nothing ever reads.
        if (address(key.hooks) != address(this)) revert InvalidPoolKey();
        bool memecoinIsCurrency0 = Currency.unwrap(key.currency0) == args.memecoin;
        if (!memecoinIsCurrency0 && Currency.unwrap(key.currency1) != args.memecoin) revert InvalidPoolKey();

        address quoteToken =
            memecoinIsCurrency0 ? Currency.unwrap(key.currency1) : Currency.unwrap(key.currency0);

        launches[poolId] = LaunchInfo({
            registered: true,
            memecoinIsCurrency0: memecoinIsCurrency0,
            memecoin: args.memecoin,
            quoteToken: quoteToken,
            creator: args.creator,
            buybackCreatorRecipient: args.buybackCreatorRecipient,
            protocolFeeRecipient: args.policy.protocolFeeRecipient,
            creatorTaxBps: args.creatorTaxBps,
            protocolFeeShareBps: args.policy.protocolFeeShareBps,
            buybackBurnBps: args.policy.buybackBurnBps,
            hookFeeBps: args.policy.hookFeeBps,
            maxInternalPriceImpactBps: args.policy.maxInternalPriceImpactBps,
            buybackEnabled: args.buybackEnabled
        });
        _poolKeys[poolId] = key;

        emit PoolRegistered(poolId, args.memecoin, quoteToken, args.creator);
    }

    /**
     * @notice Updates who receives this pool's creator fee share. Restricted
     * to the factory, which gates both self-service creator transfers and
     * protocol-owner overrides before forwarding here, so this contract only
     * needs to trust one caller.
     */
    function setCreatorFeeRecipient(PoolId poolId, address newRecipient) external onlyFactory {
        LaunchInfo storage info = launches[poolId];
        if (!info.registered) revert UnknownPool();
        if (newRecipient == address(0)) revert ZeroAddress();

        emit CreatorFeeRecipientUpdated(poolId, info.creator, newRecipient);
        info.creator = newRecipient;
    }

    /**
     * @notice Updates whether a registered launch routes its configured fee
     * share through buyback-and-lock.
     * @dev Applies to fees charged from here on, not to fees already pending.
     * Each swap earmarks its buyback slice as it is charged, so a toggle
     * cannot reach back and reroute value that accrued under the opposite
     * setting. Without that, a disable landing before a sweep would divert a
     * buyback the creator had already earned into their own payout, and an
     * enable would sweep fees earned under a plain split into the vest.
     */
    function setBuybackEnabled(PoolId poolId, bool enabled) external onlyFactory {
        LaunchInfo storage info = launches[poolId];
        if (!info.registered) revert UnknownPool();
        info.buybackEnabled = enabled;
        emit BuybackEnabledUpdated(poolId, enabled);
    }

    // ---------------------------------------------------------------------
    // IHooks: only beforeInitialize and afterSwap are enabled. BaseHook
    // supplies the externally reachable callbacks, each already restricted to
    // the pool manager, and reverts HookNotImplemented for every permission
    // getHookPermissions() leaves off.
    // ---------------------------------------------------------------------

    /**
     * @dev Registration is what binds a pool id to its memecoin, quote asset,
     * and fee recipients, and every later fee credit is derived from that
     * record. Restricting initialization to the factory keeps a pool bearing
     * this hook from existing without one.
     */
    function _beforeInitialize(address sender, PoolKey calldata, uint160) internal view override returns (bytes4) {
        if (sender != factory) revert NotFactory();
        return IHooks.beforeInitialize.selector;
    }

    /**
     * @notice Takes `hookFeeBps` plus this pool's `creatorTaxBps` of the
     * swap's unspecified currency straight out of the pool manager's
     * flash-accounting ledger in a single `take`, crediting the two cuts to
     * separate pending balances so the creator tax never mixes with the
     * protocol/buyback-and-lock split. If either cut lands in the
     * memecoin, it is left untouched here and only converted to the quote
     * currency later, in a batched `sweepPoolFees` call, rather than on
     * every single swap.
     */
    /// @dev Scratch space for `_afterSwap` fee skim under non-IR codegen.
    struct AfterSwapCtx {
        PoolId poolId;
        LaunchInfo info;
        Currency feeCurrency;
        address feeCurrencyAddr;
        uint256 feeAmount;
        uint256 taxAmount;
        uint256 totalAmount;
    }

    function _afterSwap(address, PoolKey calldata key, SwapParams calldata params, BalanceDelta delta, bytes calldata)
        internal
        override
        returns (bytes4, int128)
    {
        // The conversion and buyback legs swap against this same pool, but
        // they are never taxed here: v4-core skips a pool's hooks when the
        // hook itself is the caller (Hooks.afterSwap). Were that not so, the
        // skim would come out of the buyback before it reached the vault.
        AfterSwapCtx memory ctx;
        ctx.poolId = key.toId();
        ctx.info = launches[ctx.poolId];
        if (!ctx.info.registered) return (IHooks.afterSwap.selector, 0);
        if (ctx.info.hookFeeBps == 0 && ctx.info.creatorTaxBps == 0) return (IHooks.afterSwap.selector, 0);

        bool specifiedIsCurrency0 = (params.amountSpecified < 0) == params.zeroForOne;
        int128 unspecifiedAmount;
        (ctx.feeCurrency, unspecifiedAmount) =
            specifiedIsCurrency0 ? (key.currency1, delta.amount1()) : (key.currency0, delta.amount0());
        if (unspecifiedAmount < 0) unspecifiedAmount = -unspecifiedAmount;
        if (unspecifiedAmount == 0) return (IHooks.afterSwap.selector, 0);

        uint256 unspecified = uint256(uint128(unspecifiedAmount));
        ctx.feeAmount = (unspecified * ctx.info.hookFeeBps) / BASIS_POINTS;
        ctx.taxAmount = (unspecified * ctx.info.creatorTaxBps) / BASIS_POINTS;
        ctx.totalAmount = ctx.feeAmount + ctx.taxAmount;
        if (ctx.totalAmount == 0) return (IHooks.afterSwap.selector, 0);

        ctx.feeCurrencyAddr = Currency.unwrap(ctx.feeCurrency);
        _takeExact(ctx.feeCurrency, ctx.feeCurrencyAddr, ctx.totalAmount);
        if (ctx.feeAmount != 0) {
            pendingFees[ctx.poolId][ctx.feeCurrencyAddr] += ctx.feeAmount;
            if (ctx.info.buybackEnabled) {
                // The buyback comes out of the creator's bucket alone, so it
                // is measured against what remains after the protocol's share.
                uint256 creatorSlice =
                    ctx.feeAmount - (ctx.feeAmount * ctx.info.protocolFeeShareBps) / BASIS_POINTS;
                pendingBuyback[ctx.poolId][ctx.feeCurrencyAddr] +=
                    (creatorSlice * ctx.info.buybackBurnBps) / BASIS_POINTS;
            }
        }
        if (ctx.taxAmount != 0) pendingCreatorTax[ctx.poolId][ctx.feeCurrencyAddr] += ctx.taxAmount;

        emit HookFeeCollected(ctx.poolId, ctx.feeCurrencyAddr, ctx.feeAmount, ctx.taxAmount);
        return (IHooks.afterSwap.selector, int128(uint128(ctx.totalAmount)));
    }

    // ---------------------------------------------------------------------
    // Fee sweep: ISP conversion, buyback-and-lock, and distribution
    // ---------------------------------------------------------------------

    /**
     * @notice Converts any pending memecoin-denominated fee into the pool's
     * quote currency against the pool's own liquidity, then splits the
     * combined quote-currency total into protocol / buyback-and-lock /
     * creator using the live policy, exactly mirroring the bonding curve's
     * own sweep. The trusted sweep operator is required whenever the sweep
     * would execute an internal conversion or buyback. The creator may still
     * distribute already-quoted fees when no internal swap is needed.
     */
    /// @dev Locals for `sweepPoolFees` under non-IR codegen.
    struct SweepPoolCtx {
        PoolId poolId;
        LaunchInfo info;
        uint256 minConversionQuoteOut;
        uint256 minBuybackTokensOut;
        uint256 convertedFeeQuote;
        uint256 convertedTaxQuote;
        uint256 convertedBuybackQuote;
        bool converted;
        uint256 totalQuote;
        uint256 taxQuote;
        uint256 buybackQuote;
    }

    function sweepPoolFees(PoolId poolId, uint256 minConversionQuoteOut, uint256 minBuybackTokensOut)
        external
        nonReentrant
    {
        SweepPoolCtx memory ctx;
        ctx.poolId = poolId;
        ctx.info = launches[poolId];
        ctx.minConversionQuoteOut = minConversionQuoteOut;
        ctx.minBuybackTokensOut = minBuybackTokensOut;

        if (!ctx.info.registered) revert UnknownPool();
        bool isOperator = msg.sender == feeSweepOperator;
        if (!isOperator && msg.sender != ctx.info.creator) revert NotFeeSweepOperator();
        if (!isOperator && _requiresTrustedOperator(ctx.poolId, ctx.info)) revert InternalSwapRequiresOperator();

        (ctx.convertedFeeQuote, ctx.convertedTaxQuote, ctx.convertedBuybackQuote, ctx.converted) =
            _convertPendingMemecoin(ctx.poolId, ctx.info, ctx.minConversionQuoteOut);
        // Only a conversion that actually executed is subject to the caller's
        // minimum. Enforcing it when there was nothing to convert, or when the
        // swap filled nothing and the pending amount was restored for a later
        // retry, would block the quote-denominated legs of the sweep over a
        // conversion that never happened.
        {
            uint256 conversionQuoteOut = ctx.convertedFeeQuote + ctx.convertedTaxQuote;
            if (ctx.converted && conversionQuoteOut < ctx.minConversionQuoteOut) {
                revert SlippageExceeded(conversionQuoteOut, ctx.minConversionQuoteOut);
            }
        }

        ctx.totalQuote = pendingFees[ctx.poolId][ctx.info.quoteToken] + ctx.convertedFeeQuote;
        ctx.taxQuote = pendingCreatorTax[ctx.poolId][ctx.info.quoteToken] + ctx.convertedTaxQuote;
        ctx.buybackQuote = pendingBuyback[ctx.poolId][ctx.info.quoteToken] + ctx.convertedBuybackQuote;
        if (ctx.totalQuote == 0 && ctx.taxQuote == 0) return;
        pendingFees[ctx.poolId][ctx.info.quoteToken] = 0;
        pendingCreatorTax[ctx.poolId][ctx.info.quoteToken] = 0;
        pendingBuyback[ctx.poolId][ctx.info.quoteToken] = 0;

        _distributeFromSweep(ctx);
    }

    function _distributeFromSweep(SweepPoolCtx memory sweep) private {
        _distribute(
            sweep.poolId,
            sweep.info,
            sweep.totalQuote,
            sweep.taxQuote,
            sweep.buybackQuote,
            sweep.minBuybackTokensOut
        );
    }

    /**
     * @notice Owner-only escape hatch for a pool's pending quote-token fees
     * when they can no longer reach the protocol and creator through the
     * normal exact-delivery path, for example an approved pair token that
     * later turns out to be fee-on-transfer, rebasing, or otherwise unable
     * to move its exact nominal amount. `sweepPoolFees` would revert
     * indefinitely in that case, since `_payOut` enforces exact delivery
     * into the fee escrow and there is no way to satisfy it. This bypasses
     * the escrow and the buyback conversion entirely (the buyback swap
     * would fail for the same underlying reason) and pays the protocol and
     * creator their regular split with a direct transfer instead, so the
     * quote-token balance the hook already holds is never permanently
     * stuck. A native quote leg is skipped rather than rejected: ETH cannot
     * fail an exact-delivery transfer, so it has nothing to rescue.
     *
     * The pool's memecoin-denominated fees are rescued regardless of what the
     * quote currency is, because their only ordinary exit is the conversion
     * swap. Gating the whole function on an ERC-20 quote would leave a native
     * pool's memecoin fees with no recovery at all, and would also strand its
     * ETH fees behind them, since sweepPoolFees converts before it
     * distributes and reverts as a unit.
     */
    function rescuePoolFees(PoolId poolId)
        external
        onlyOwner
        nonReentrant
        returns (uint256 protocolAmount, uint256 creatorAmount)
    {
        LaunchInfo memory info = launches[poolId];
        if (!info.registered) revert UnknownPool();
        address quoteToken = info.quoteToken;

        if (quoteToken != address(0)) {
            (protocolAmount, creatorAmount) = _rescueCurrency(poolId, info, quoteToken);
        }
        (uint256 memecoinProtocol, uint256 memecoinCreator) = _rescueCurrency(poolId, info, info.memecoin);
        if (protocolAmount == 0 && creatorAmount == 0 && memecoinProtocol == 0 && memecoinCreator == 0) {
            revert NothingToRescue();
        }
    }

    /**
     * @dev Zeroes one currency's pending buckets for a pool and pays the
     * protocol and creator their regular split directly, bypassing the
     * escrow. Returns zero for both legs when there is nothing pending, so
     * the caller can tell whether any currency had a balance to rescue.
     */
    function _rescueCurrency(PoolId poolId, LaunchInfo memory info, address currency)
        private
        returns (uint256 protocolAmount, uint256 creatorAmount)
    {
        uint256 total = pendingFees[poolId][currency];
        uint256 tax = pendingCreatorTax[poolId][currency];
        if (total == 0 && tax == 0) return (0, 0);

        pendingFees[poolId][currency] = 0;
        pendingCreatorTax[poolId][currency] = 0;
        // The rescue pays the creator their whole bucket rather than running
        // a buyback, since the swap would fail for the same reason the escrow
        // path did. Clearing the earmark keeps it from surviving as a claim
        // on fees this call has already paid out.
        pendingBuyback[poolId][currency] = 0;

        protocolAmount = (total * info.protocolFeeShareBps) / BASIS_POINTS;
        creatorAmount = total - protocolAmount + tax;

        if (protocolAmount != 0) IERC20(currency).safeTransfer(info.protocolFeeRecipient, protocolAmount);
        if (creatorAmount != 0) IERC20(currency).safeTransfer(info.creator, creatorAmount);

        emit PoolFeesRescued(poolId, currency, protocolAmount, creatorAmount);
    }

    /**
     * @dev Limits price-sensitive pool interactions to the protocol's sweep
     * operator. A creator can distribute direct quote balances when buyback is
     * disabled, but cannot select a permissive minimum around a manipulable
     * spot price for inventory shared with the protocol.
     */
    function _requiresTrustedOperator(PoolId poolId, LaunchInfo memory info) private view returns (bool) {
        if (pendingFees[poolId][info.memecoin] != 0 || pendingCreatorTax[poolId][info.memecoin] != 0) {
            return true;
        }

        return pendingBuyback[poolId][info.quoteToken] != 0;
    }

    /**
     * @dev Converts fee and creator-tax memecoin inventory in one swap so the
     * sweep receives one aggregate price boundary. Partial input and output
     * are allocated proportionally back to their separate accounting buckets.
     * The buyback earmark rides along inside the fee bucket, converting in
     * the same proportion so a partial fill leaves the unconverted remainder
     * carrying the share of the earmark it still owes.
     */
    /// @dev Scratch space for memecoin→quote conversion under non-IR codegen.
    struct ConvertCtx {
        uint256 feePending;
        uint256 taxPending;
        uint256 buybackPending;
        uint256 totalPending;
        uint256 consumed;
        uint256 quoteOut;
        uint256 feeConsumed;
        uint256 taxConsumed;
        uint256 feeQuoteOut;
        uint256 taxQuoteOut;
        uint256 buybackQuoteOut;
        bool converted;
    }

    function _convertPendingMemecoin(PoolId poolId, LaunchInfo memory info, uint256 minConversionQuoteOut)
        private
        returns (uint256 feeQuoteOut, uint256 taxQuoteOut, uint256 buybackQuoteOut, bool converted)
    {
        ConvertCtx memory ctx;
        ctx.feePending = pendingFees[poolId][info.memecoin];
        ctx.taxPending = pendingCreatorTax[poolId][info.memecoin];
        ctx.buybackPending = pendingBuyback[poolId][info.memecoin];
        ctx.totalPending = ctx.feePending + ctx.taxPending;
        if (ctx.totalPending == 0) return (0, 0, 0, false);
        if (minConversionQuoteOut == 0) revert MinimumOutputRequired();

        pendingFees[poolId][info.memecoin] = 0;
        pendingCreatorTax[poolId][info.memecoin] = 0;
        pendingBuyback[poolId][info.memecoin] = 0;
        (ctx.consumed, ctx.quoteOut) =
            _executeInternalSwap(poolId, SwapDirection.MemecoinToQuote, ctx.totalPending);
        if (ctx.consumed == 0) {
            pendingFees[poolId][info.memecoin] += ctx.feePending;
            pendingCreatorTax[poolId][info.memecoin] += ctx.taxPending;
            pendingBuyback[poolId][info.memecoin] += ctx.buybackPending;
            emit PoolConversionSkipped(poolId, ctx.totalPending);
            return (0, 0, 0, false);
        }
        ctx.converted = true;

        ctx.feeConsumed = FullMath.mulDiv(ctx.consumed, ctx.feePending, ctx.totalPending);
        ctx.taxConsumed = ctx.consumed - ctx.feeConsumed;
        ctx.feeQuoteOut = FullMath.mulDiv(ctx.quoteOut, ctx.feeConsumed, ctx.consumed);
        ctx.taxQuoteOut = ctx.quoteOut - ctx.feeQuoteOut;

        // The earmark is a marker on part of the fee bucket, so it converts
        // at the fee bucket's own fill ratio and then at the rate that bucket
        // actually realised. feePending is non-zero whenever the earmark is,
        // since the earmark was accrued as a fraction of it.
        if (ctx.buybackPending != 0) {
            uint256 buybackConsumed = FullMath.mulDiv(ctx.buybackPending, ctx.feeConsumed, ctx.feePending);
            ctx.buybackQuoteOut =
                ctx.feeConsumed == 0 ? 0 : FullMath.mulDiv(ctx.feeQuoteOut, buybackConsumed, ctx.feeConsumed);
            pendingBuyback[poolId][info.memecoin] += ctx.buybackPending - buybackConsumed;
        }

        pendingFees[poolId][info.memecoin] += ctx.feePending - ctx.feeConsumed;
        pendingCreatorTax[poolId][info.memecoin] += ctx.taxPending - ctx.taxConsumed;

        return (ctx.feeQuoteOut, ctx.taxQuoteOut, ctx.buybackQuoteOut, ctx.converted);
    }

    /**
     * @dev Splits `totalQuote` into protocol / buyback-and-lock / creator,
     * running the buyback leg as a real swap of the quote currency back
     * into the memecoin before locking the result into the shared
     * five-year vest instead of burning it. `taxQuote` bypasses the split
     * entirely and is added straight to the creator's payout.
     * @param buybackQuote The slice of `totalQuote` earmarked for buyback as
     * its fees were charged. Passed in rather than derived here so a toggle
     * of the pool's buyback flag cannot reroute value that already accrued.
     */
    /// @dev Scratch space for `_distribute` under non-IR codegen.
    struct DistributeCtx {
        PoolId poolId;
        LaunchInfo info;
        uint256 totalQuote;
        uint256 taxQuote;
        uint256 buybackQuote;
        uint256 minBuybackTokensOut;
        uint256 protocolAmount;
        uint256 creatorBucket;
        uint256 requestedBuyback;
        uint256 creatorAmount;
        uint256 buybackSpent;
        uint256 tokensLocked;
    }

    function _distribute(
        PoolId poolId,
        LaunchInfo memory info,
        uint256 totalQuote,
        uint256 taxQuote,
        uint256 buybackQuote,
        uint256 minBuybackTokensOut
    ) private {
        DistributeCtx memory ctx;
        ctx.poolId = poolId;
        ctx.info = info;
        ctx.totalQuote = totalQuote;
        ctx.taxQuote = taxQuote;
        ctx.buybackQuote = buybackQuote;
        ctx.minBuybackTokensOut = minBuybackTokensOut;

        ctx.protocolAmount = (ctx.totalQuote * ctx.info.protocolFeeShareBps) / BASIS_POINTS;
        ctx.creatorBucket = ctx.totalQuote - ctx.protocolAmount;
        // The earmark was summed per swap, so its rounding can land a wei or
        // two above the bucket recomputed here on the aggregate. Clamping
        // keeps the subtraction below sound at a full buyback share, where
        // the two would otherwise be equal.
        ctx.requestedBuyback = ctx.buybackQuote < ctx.creatorBucket ? ctx.buybackQuote : ctx.creatorBucket;
        ctx.creatorAmount = ctx.creatorBucket - ctx.requestedBuyback + ctx.taxQuote;

        _distributeBuyback(ctx);

        _payOut(ctx.info.creator, ctx.info.quoteToken, ctx.creatorAmount);
        _payOut(ctx.info.protocolFeeRecipient, ctx.info.quoteToken, ctx.protocolAmount);

        emit PoolFeesSwept(
            ctx.poolId, ctx.protocolAmount, ctx.buybackSpent, ctx.creatorAmount, ctx.tokensLocked
        );
    }

    /**
     * @dev Buyback leg of `_distribute`. Mutates `ctx` only.
     */
    function _distributeBuyback(DistributeCtx memory ctx) private {
        if (ctx.requestedBuyback == 0) return;
        if (ctx.minBuybackTokensOut == 0) revert MinimumOutputRequired();

        (ctx.buybackSpent, ctx.tokensLocked) =
            _executeInternalSwap(ctx.poolId, SwapDirection.QuoteToMemecoin, ctx.requestedBuyback);
        // Return the unfilled quote amount to the creator bucket. The
        // price limit bounds execution without silently retaining value
        // that has already been removed from the creator's accounting.
        ctx.creatorAmount += ctx.requestedBuyback - ctx.buybackSpent;
        if (ctx.tokensLocked != 0) {
            IERC20(ctx.info.memecoin).forceApprove(address(buybackVault), ctx.tokensLocked);
            buybackVault.lock(
                ctx.info.memecoin,
                ctx.tokensLocked,
                ctx.info.buybackCreatorRecipient,
                ctx.info.protocolFeeRecipient,
                ctx.info.protocolFeeShareBps
            );
            if (ctx.tokensLocked < ctx.minBuybackTokensOut) {
                revert SlippageExceeded(ctx.tokensLocked, ctx.minBuybackTokensOut);
            }
        } else if (ctx.buybackSpent == 0) {
            // Same rule the curve applies: only a buyback that actually
            // executes is subject to the caller's minimum. Enforcing it on
            // a buyback that filled nothing would block the creator and
            // protocol legs too, stranding the whole distribution over a
            // leg that has already been folded back above.
            emit PoolBuybackSkipped(ctx.poolId, ctx.requestedBuyback);
        } else {
            // Input was consumed but rounded to no output at all. That
            // quote is gone into the pool with nothing locked against it,
            // so it can be neither folded back nor treated as a skip.
            revert SlippageExceeded(0, ctx.minBuybackTokensOut);
        }
    }

    function _payOut(address recipient, address quoteToken, uint256 amount) private {
        if (amount == 0) return;
        if (quoteToken == address(0)) {
            feeEscrow.credit{value: amount}(recipient);
        } else {
            uint256 balanceBefore = IERC20(quoteToken).balanceOf(address(feeEscrow));
            IERC20(quoteToken).forceApprove(address(feeEscrow), amount);
            feeEscrow.creditToken(recipient, quoteToken, amount);
            uint256 received = IERC20(quoteToken).balanceOf(address(feeEscrow)) - balanceBefore;
            if (received != amount) revert InexactQuoteTransfer(quoteToken, amount, received);
        }
    }

    /**
     * @dev Opens a standalone unlock context to run one exact-input internal
     * swap, bounded by a price-impact ceiling measured against the pool's
     * live price.
     *
     * That ceiling limits how far this swap moves the price, not where the
     * price started. A front-run that depresses spot first shifts the whole
     * band down with it, so the bound is slippage control rather than
     * manipulation resistance. What actually caps the loss on a sandwich is
     * the caller's `minConversionQuoteOut` / `minBuybackTokensOut`, which is
     * why every price-sensitive sweep is gated to the sweep operator by
     * `_requiresTrustedOperator`. Treat those minimums as the real defense
     * and size them off an independent price.
     */
    function _executeInternalSwap(PoolId poolId, SwapDirection direction, uint256 amountIn)
        private
        returns (uint256 amountInConsumed, uint256 amountOut)
    {
        bytes memory result = poolManager.unlock(abi.encode(poolId, direction, amountIn));
        (amountInConsumed, amountOut) = abi.decode(result, (uint256, uint256));
    }

    /// @dev Scratch for `unlockCallback` under non-IR codegen.
    struct UnlockCtx {
        PoolId poolId;
        SwapDirection direction;
        uint256 amountIn;
        LaunchInfo info;
        PoolKey key;
        bool zeroForOne;
        uint160 sqrtPriceLimitX96;
        BalanceDelta delta;
        uint256 amountInConsumed;
        uint256 amountOut;
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        if (msg.sender != address(poolManager)) revert NotPoolManager();

        UnlockCtx memory ctx;
        (ctx.poolId, ctx.direction, ctx.amountIn) = abi.decode(data, (PoolId, SwapDirection, uint256));
        ctx.info = launches[ctx.poolId];
        ctx.key = _poolKeys[ctx.poolId];
        ctx.zeroForOne = ctx.direction == SwapDirection.MemecoinToQuote
            ? ctx.info.memecoinIsCurrency0
            : !ctx.info.memecoinIsCurrency0;

        (uint160 sqrtPriceX96,,,) = StateLibrary.getSlot0(poolManager, ctx.poolId);
        ctx.sqrtPriceLimitX96 = _priceLimit(sqrtPriceX96, ctx.zeroForOne, ctx.info.maxInternalPriceImpactBps);

        ctx.delta = poolManager.swap(
            ctx.key,
            SwapParams({
                zeroForOne: ctx.zeroForOne,
                amountSpecified: -SafeCast.toInt256(ctx.amountIn),
                sqrtPriceLimitX96: ctx.sqrtPriceLimitX96
            }),
            ""
        );

        _settleCurrency(ctx.key.currency0, ctx.delta.amount0());
        _settleCurrency(ctx.key.currency1, ctx.delta.amount1());

        int128 inputDelta = ctx.zeroForOne ? ctx.delta.amount0() : ctx.delta.amount1();
        int128 outputDelta = ctx.zeroForOne ? ctx.delta.amount1() : ctx.delta.amount0();
        ctx.amountInConsumed = inputDelta < 0 ? SafeCast.toUint256(-int256(inputDelta)) : 0;
        ctx.amountOut = outputDelta > 0 ? SafeCast.toUint256(int256(outputDelta)) : 0;
        return abi.encode(ctx.amountInConsumed, ctx.amountOut);
    }

    function _settleCurrency(Currency currency, int128 amount) private {
        if (amount < 0) {
            uint256 owed = uint256(uint128(-amount));
            if (currency.isAddressZero()) {
                // PoolManager.sync carries no unlock modifier, so the synced-
                // currency slot is transient state anyone can leave set for
                // the rest of a transaction. Settling native against a stale
                // non-zero slot takes the ERC-20 branch and reverts
                // NonzeroNativeValue, which v4-core calls out as a DoS vector.
                poolManager.sync(currency);
                poolManager.settle{value: owed}();
            } else {
                address token = Currency.unwrap(currency);
                uint256 balanceBefore = IERC20(token).balanceOf(address(poolManager));
                poolManager.sync(currency);
                IERC20(token).safeTransfer(address(poolManager), owed);
                uint256 received = IERC20(token).balanceOf(address(poolManager)) - balanceBefore;
                if (received != owed) revert InexactQuoteTransfer(token, owed, received);
                poolManager.settle();
            }
        } else if (amount > 0) {
            _takeExact(currency, Currency.unwrap(currency), uint256(uint128(amount)));
        }
    }

    /**
     * @dev Records only assets that reached the hook in full. Uniswap V4's
     * flash accounting requires exact ERC-20 transfers, so transfer-tax quote
     * assets fail atomically instead of creating an underfunded fee balance.
     *
     * On an exact-output swap the fee is charged on the swapper's input leg,
     * which the PoolManager has not been paid yet, so this take draws from
     * the shared pot and reverts if the fee alone exceeds the PoolManager's
     * whole balance of that currency. Reaching that needs an input on the
     * order of fifty times the PoolManager's holdings, and the revert falls
     * on the swap that caused it. No other pool can lose value to it either,
     * since v4's unlock invariant makes the swapper settle the enlarged debt
     * before the transaction ends.
     */
    function _takeExact(Currency currency, address token, uint256 amount) private {
        if (currency.isAddressZero()) {
            poolManager.take(currency, address(this), amount);
            return;
        }

        uint256 balanceBefore = IERC20(token).balanceOf(address(this));
        poolManager.take(currency, address(this), amount);
        uint256 received = IERC20(token).balanceOf(address(this)) - balanceBefore;
        if (received != amount) revert InexactQuoteTransfer(token, amount, received);
    }

    /**
     * @dev Bounds the pool's sqrt-price movement for batched internal swaps.
     * For a constant-product pool this matches the bonding curve's
     * `amountIn / (reserve + amountIn)` reserve-movement bound. The resulting
     * spot-price percentage is larger because spot price is proportional to
     * sqrtPriceX96 squared; `maxInternalPriceImpactBps` is retained as the
     * public policy name for compatibility across both phases.
     */
    function _priceLimit(uint160 sqrtPriceX96, bool zeroForOne, uint256 maxPriceImpactBps)
        private
        pure
        returns (uint160)
    {
        uint256 factor = BASIS_POINTS - maxPriceImpactBps;
        if (zeroForOne) {
            uint256 limit = (uint256(sqrtPriceX96) * factor) / BASIS_POINTS;
            // forge-lint: disable-next-line(unsafe-typecast)
            return limit <= TickMath.MIN_SQRT_PRICE ? TickMath.MIN_SQRT_PRICE + 1 : uint160(limit);
        } else {
            uint256 limit = (uint256(sqrtPriceX96) * BASIS_POINTS) / factor;
            // casting to uint160 is safe because this branch only runs when limit < TickMath.MAX_SQRT_PRICE, which is itself < type(uint160).max
            // forge-lint: disable-next-line(unsafe-typecast)
            return limit >= TickMath.MAX_SQRT_PRICE ? TickMath.MAX_SQRT_PRICE - 1 : uint160(limit);
        }
    }

    /**
     * @notice Accepts native ETH pulled out of the pool manager via `take`.
     */
    receive() external payable {}
}
