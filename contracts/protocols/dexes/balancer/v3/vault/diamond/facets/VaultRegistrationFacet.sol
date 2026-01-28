// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IHooks} from "@balancer-labs/v3-interfaces/contracts/vault/IHooks.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IERC20MultiTokenErrors} from "@balancer-labs/v3-interfaces/contracts/vault/IERC20MultiTokenErrors.sol";
import "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";

import {PackedTokenBalance} from "@balancer-labs/v3-solidity-utils/contracts/helpers/PackedTokenBalance.sol";
import {ScalingHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/ScalingHelpers.sol";
import {InputHelpers} from "@balancer-labs/v3-solidity-utils/contracts/helpers/InputHelpers.sol";

import {PoolConfigLib, PoolConfigBits} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigLib.sol";
import {PoolConfigConst} from "@balancer-labs/v3-vault/contracts/lib/PoolConfigConst.sol";
import {HooksConfigLib} from "@balancer-labs/v3-vault/contracts/lib/HooksConfigLib.sol";
import {PoolDataLib} from "@balancer-labs/v3-vault/contracts/lib/PoolDataLib.sol";

import {BalancerV3VaultStorageRepo} from "../BalancerV3VaultStorageRepo.sol";
import {BalancerV3VaultModifiers} from "../BalancerV3VaultModifiers.sol";
import {BalancerV3MultiTokenRepo} from "../BalancerV3MultiTokenRepo.sol";

/* -------------------------------------------------------------------------- */
/*                          VaultRegistrationFacet                            */
/* -------------------------------------------------------------------------- */

/**
 * @title VaultRegistrationFacet
 * @notice Handles pool registration and initialization.
 * @dev Implements registerPool and initialize functions from IVaultExtension.
 *
 * Pool lifecycle:
 * 1. registerPool - Register pool with tokens, fees, hooks, and configuration
 * 2. initialize - Seed pool with initial liquidity and mint BPT
 *
 * Key features:
 * - Token validation and sorting enforcement
 * - Hooks contract integration
 * - Protocol fee controller integration
 * - Rate provider setup for yield-bearing tokens
 */
contract VaultRegistrationFacet is BalancerV3VaultModifiers, IERC20MultiTokenErrors {
    using PackedTokenBalance for bytes32;
    using PoolConfigLib for PoolConfigBits;
    using HooksConfigLib for PoolConfigBits;
    using PoolDataLib for PoolData;
    using ScalingHelpers for *;
    using InputHelpers for uint256;

    /// @notice Minimum number of tokens in a pool.
    uint256 private constant _MIN_TOKENS = 2;
    /// @notice Maximum number of tokens in a pool.
    uint256 private constant _MAX_TOKENS = 8;

    /// @notice Minimum pool BPT supply that must always exist (locked in address(0)).
    uint256 internal constant _POOL_MINIMUM_TOTAL_SUPPLY = 1e6;

    /// @dev Internal struct for pool registration parameters.
    struct PoolRegistrationParams {
        TokenConfig[] tokenConfig;
        uint256 swapFeePercentage;
        uint32 pauseWindowEndTime;
        bool protocolFeeExempt;
        PoolRoleAccounts roleAccounts;
        address poolHooksContract;
        LiquidityManagement liquidityManagement;
    }

    /* ========================================================================== */
    /*                              EXTERNAL FUNCTIONS                            */
    /* ========================================================================== */

    /**
     * @notice Registers a new pool with the vault.
     * @dev Called by pool factory during pool creation.
     *
     * @param pool The pool address
     * @param tokenConfig Token configurations (addresses, types, rate providers)
     * @param swapFeePercentage Initial swap fee percentage
     * @param pauseWindowEndTime When the pool's pause window ends
     * @param protocolFeeExempt Whether pool is exempt from protocol fees
     * @param roleAccounts Addresses for pause manager, swap fee manager, pool creator
     * @param poolHooksContract Hooks contract address (address(0) if no hooks)
     * @param liquidityManagement Liquidity management flags
     */
    function registerPool(
        address pool,
        TokenConfig[] memory tokenConfig,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        bool protocolFeeExempt,
        PoolRoleAccounts calldata roleAccounts,
        address poolHooksContract,
        LiquidityManagement calldata liquidityManagement
    ) external whenVaultNotPaused nonReentrant {
        _registerPool(
            pool,
            PoolRegistrationParams({
                tokenConfig: tokenConfig,
                swapFeePercentage: swapFeePercentage,
                pauseWindowEndTime: pauseWindowEndTime,
                protocolFeeExempt: protocolFeeExempt,
                roleAccounts: roleAccounts,
                poolHooksContract: poolHooksContract,
                liquidityManagement: liquidityManagement
            })
        );
    }

    /**
     * @notice Initializes a registered pool with initial liquidity.
     * @dev Seeds the pool, calculates invariant, and mints BPT to the recipient.
     *
     * @param pool The pool address
     * @param to Recipient of initial BPT
     * @param tokens Tokens in the same order as registration
     * @param exactAmountsIn Initial token amounts
     * @param minBptAmountOut Minimum BPT to receive
     * @param userData Additional data for hooks
     * @return bptAmountOut Amount of BPT minted
     */
    function initialize(
        address pool,
        address to,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256 minBptAmountOut,
        bytes memory userData
    )
        external
        onlyWhenUnlocked
        withRegisteredPool(pool)
        nonReentrant
        returns (uint256 bptAmountOut)
    {
        _ensureUnpaused(pool);

        PoolData memory poolData = _loadPoolData(pool, Rounding.ROUND_DOWN);

        if (poolData.poolConfigBits.isPoolInitialized()) {
            revert PoolAlreadyInitialized(pool);
        }

        uint256 numTokens = poolData.tokens.length;
        InputHelpers.ensureInputLengthMatch(numTokens, exactAmountsIn.length);

        // Scale amounts for pool math (round down)
        uint256[] memory exactAmountsInScaled18 = exactAmountsIn.copyToScaled18ApplyRateRoundDownArray(
            poolData.decimalScalingFactors,
            poolData.tokenRates
        );

        // Call beforeInitialize hook if configured
        if (poolData.poolConfigBits.shouldCallBeforeInitialize()) {
            IHooks hooksContract = BalancerV3VaultStorageRepo._hooksContract(pool);
            HooksConfigLib.callBeforeInitializeHook(exactAmountsInScaled18, userData, hooksContract);

            // Reload data after hook (rates may have changed)
            poolData.reloadBalancesAndRates(
                BalancerV3VaultStorageRepo._layout().poolTokenBalances[pool],
                Rounding.ROUND_DOWN
            );

            exactAmountsInScaled18 = exactAmountsIn.copyToScaled18ApplyRateRoundDownArray(
                poolData.decimalScalingFactors,
                poolData.tokenRates
            );
        }

        bptAmountOut = _initialize(pool, to, poolData, tokens, exactAmountsIn, exactAmountsInScaled18, minBptAmountOut);

        // Call afterInitialize hook if configured
        if (poolData.poolConfigBits.shouldCallAfterInitialize()) {
            IHooks hooksContract = BalancerV3VaultStorageRepo._hooksContract(pool);
            HooksConfigLib.callAfterInitializeHook(exactAmountsInScaled18, bptAmountOut, userData, hooksContract);
        }
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    function _registerPool(address pool, PoolRegistrationParams memory params) internal {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();

        // Ensure the pool isn't already registered
        if (_isPoolRegistered(pool)) {
            revert PoolAlreadyRegistered(pool);
        }

        uint256 numTokens = params.tokenConfig.length;
        if (numTokens < _MIN_TOKENS) {
            revert MinTokens();
        }
        if (numTokens > _MAX_TOKENS) {
            revert MaxTokens();
        }

        // Validate and store tokens
        IERC20[] memory poolTokens = new IERC20[](numTokens);
        IERC20 previousToken = IERC20(address(0));
        uint256 tokenDecimalDiffs;

        for (uint256 i = 0; i < numTokens; ++i) {
            TokenConfig memory tokenData = params.tokenConfig[i];
            IERC20 token = tokenData.token;

            // Validate token address
            if (address(token) == address(0) || address(token) == pool) {
                revert InvalidToken();
            }

            // Tokens must be sorted in ascending order
            if (token < previousToken) {
                revert InputHelpers.TokensNotSorted();
            }
            if (token == previousToken) {
                revert TokenAlreadyRegistered(token);
            }

            // Store token info
            TokenInfo memory tokenInfo = TokenInfo({
                tokenType: tokenData.tokenType,
                rateProvider: tokenData.rateProvider,
                paysYieldFees: tokenData.paysYieldFees
            });

            layout.poolTokenInfo[pool][token] = tokenInfo;
            layout.poolTokenBalances[pool][i] = bytes32(0);

            // Calculate decimal difference for scaling
            uint8 tokenDecimals = _getTokenDecimals(token);
            tokenDecimalDiffs |= uint256(18 - tokenDecimals) << (i * PoolConfigConst.DECIMAL_DIFF_BITLENGTH);

            poolTokens[i] = token;
            previousToken = token;
        }

        layout.poolTokens[pool] = poolTokens;

        // Store role accounts
        layout.poolRoleAccounts[pool] = params.roleAccounts;

        // Register with protocol fee controller if not exempt
        IProtocolFeeController feeController = layout.protocolFeeController;
        if (address(feeController) != address(0)) {
            feeController.registerPool(pool, address(0), params.protocolFeeExempt);
        }

        // Build pool config bits
        PoolConfigBits poolConfigBits;
        poolConfigBits = poolConfigBits.setPoolRegistered(true);
        poolConfigBits = poolConfigBits.setTokenDecimalDiffs(uint40(tokenDecimalDiffs));
        poolConfigBits = poolConfigBits.setPauseWindowEndTime(params.pauseWindowEndTime);

        // Set liquidity management flags
        poolConfigBits = poolConfigBits.setDisableUnbalancedLiquidity(
            params.liquidityManagement.disableUnbalancedLiquidity
        );
        poolConfigBits = poolConfigBits.setAddLiquidityCustom(
            params.liquidityManagement.enableAddLiquidityCustom
        );
        poolConfigBits = poolConfigBits.setRemoveLiquidityCustom(
            params.liquidityManagement.enableRemoveLiquidityCustom
        );
        poolConfigBits = poolConfigBits.setDonation(params.liquidityManagement.enableDonation);

        // Configure hooks if provided
        if (params.poolHooksContract != address(0)) {
            IHooks hooksContract = IHooks(params.poolHooksContract);
            layout.hooksContracts[pool] = hooksContract;

            // Get hooks config from the hooks contract and set each flag
            HookFlags memory hookFlags = hooksContract.getHookFlags();
            poolConfigBits = poolConfigBits.setHookAdjustedAmounts(hookFlags.enableHookAdjustedAmounts);
            poolConfigBits = poolConfigBits.setShouldCallBeforeInitialize(hookFlags.shouldCallBeforeInitialize);
            poolConfigBits = poolConfigBits.setShouldCallAfterInitialize(hookFlags.shouldCallAfterInitialize);
            poolConfigBits = poolConfigBits.setShouldCallComputeDynamicSwapFee(hookFlags.shouldCallComputeDynamicSwapFee);
            poolConfigBits = poolConfigBits.setShouldCallBeforeSwap(hookFlags.shouldCallBeforeSwap);
            poolConfigBits = poolConfigBits.setShouldCallAfterSwap(hookFlags.shouldCallAfterSwap);
            poolConfigBits = poolConfigBits.setShouldCallBeforeAddLiquidity(hookFlags.shouldCallBeforeAddLiquidity);
            poolConfigBits = poolConfigBits.setShouldCallAfterAddLiquidity(hookFlags.shouldCallAfterAddLiquidity);
            poolConfigBits = poolConfigBits.setShouldCallBeforeRemoveLiquidity(hookFlags.shouldCallBeforeRemoveLiquidity);
            poolConfigBits = poolConfigBits.setShouldCallAfterRemoveLiquidity(hookFlags.shouldCallAfterRemoveLiquidity);
        }

        // Set swap fee
        poolConfigBits = poolConfigBits.setStaticSwapFeePercentage(params.swapFeePercentage);

        layout.poolConfigBits[pool] = poolConfigBits;

        emit PoolRegistered(
            pool,
            msg.sender,
            params.tokenConfig,
            params.swapFeePercentage,
            params.pauseWindowEndTime,
            params.roleAccounts,
            poolConfigBits.toHooksConfig(IHooks(params.poolHooksContract)),
            params.liquidityManagement
        );
    }

    function _initialize(
        address pool,
        address to,
        PoolData memory poolData,
        IERC20[] memory tokens,
        uint256[] memory exactAmountsIn,
        uint256[] memory exactAmountsInScaled18,
        uint256 minBptAmountOut
    ) internal returns (uint256 bptAmountOut) {
        BalancerV3VaultStorageRepo.Storage storage layout = BalancerV3VaultStorageRepo._layout();
        mapping(uint256 tokenIndex => bytes32 packedTokenBalance) storage poolBalances = layout.poolTokenBalances[pool];

        uint256 numTokens = poolData.tokens.length;

        for (uint256 i = 0; i < numTokens; ++i) {
            IERC20 actualToken = poolData.tokens[i];

            // Verify tokens match registration order
            if (actualToken != tokens[i]) {
                revert TokensMismatch(pool, address(tokens[i]), address(actualToken));
            }

            _takeDebt(actualToken, exactAmountsIn[i]);
            poolBalances[i] = PackedTokenBalance.toPackedBalance(exactAmountsIn[i], exactAmountsInScaled18[i]);
        }

        // Mark pool as initialized
        poolData.poolConfigBits = poolData.poolConfigBits.setPoolInitialized(true);
        layout.poolConfigBits[pool] = poolData.poolConfigBits;

        // Compute initial BPT from invariant
        bptAmountOut = IBasePool(pool).computeInvariant(exactAmountsInScaled18, Rounding.ROUND_DOWN);

        // Ensure minimum total supply
        if (bptAmountOut < _POOL_MINIMUM_TOTAL_SUPPLY) {
            revert PoolTotalSupplyTooLow(bptAmountOut);
        }

        // Reserve minimum supply and mint remainder to recipient
        bptAmountOut -= _POOL_MINIMUM_TOTAL_SUPPLY;
        _mintMinimumSupplyReserve(pool);
        BalancerV3MultiTokenRepo._mint(pool, to, bptAmountOut);

        if (bptAmountOut < minBptAmountOut) {
            revert BptAmountOutBelowMin(bptAmountOut, minBptAmountOut);
        }

        emit LiquidityAdded(
            pool,
            to,
            AddLiquidityKind.UNBALANCED,
            BalancerV3MultiTokenRepo._totalSupply(pool),
            exactAmountsIn,
            new uint256[](numTokens)
        );

        emit PoolInitialized(pool);
    }

    function _mintMinimumSupplyReserve(address pool) internal {
        BalancerV3MultiTokenRepo._mint(pool, address(0), _POOL_MINIMUM_TOTAL_SUPPLY);
    }

    function _getTokenDecimals(IERC20 token) internal view returns (uint8) {
        // Try to get decimals, default to 18 if call fails
        (bool success, bytes memory data) = address(token).staticcall(
            abi.encodeWithSignature("decimals()")
        );
        if (success && data.length >= 32) {
            return abi.decode(data, (uint8));
        }
        return 18;
    }
}
