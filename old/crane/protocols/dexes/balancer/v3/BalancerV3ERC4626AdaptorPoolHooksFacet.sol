// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {
    AddLiquidityKind,
    AfterSwapParams,
    HookFlags,
    LiquidityManagement,
    PoolSwapParams,
    RemoveLiquidityKind,
    SwapKind,
    TokenConfig
} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Create3AwareContract} from "contracts/crane/factories/create2/aware/Create3AwareContract.sol";
import {BalancerV3HooksFacet} from "./vault/BalancerV3HooksFacet.sol";
import {ERC4626AwareStorage} from "contracts/crane/token/ERC20/extensions/utils/ERC4626AwareStorage.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "contracts/crane/token/ERC20/utils/BetterSafeERC20.sol";

// TODO Deperecate by integrating with BalancerV3ERC4625AdaptorPoolFacet
contract BalancerV3ERC4626AdaptorPoolHooksFacet is ERC4626AwareStorage, BalancerV3HooksFacet {
    using SafeERC20 for IERC20;

    constructor(CREATE3InitData memory create3InitData_) Create3AwareContract(create3InitData_) {}

    function onRegister(
        address, // factory,
        address, // pool,
        TokenConfig[] memory tokenConfig,
        LiquidityManagement calldata liquidityManagement
    ) public virtual override returns (bool success) {
        // ERC4626 adaptor pools do not support unbalanced liquidity.
        if (!liquidityManagement.disableUnbalancedLiquidity) {
            // Short circuit the evaluation by returning false.
            return false;
        }
        // ERC4626 adaptor pools do not support custom add liquidity.
        if (liquidityManagement.enableAddLiquidityCustom) {
            // Short circuit the evaluation by returning false.
            return false;
        }
        // ERC4626 adaptor pools do not support custom remove liquidity.
        else if (liquidityManagement.enableRemoveLiquidityCustom) {
            // Short circuit the evaluation by returning false.
            return false;
        }
        // ERC4626 adaptor pools do not support donations.
        if (liquidityManagement.enableDonation) {
            // Short circuit the evaluation by returning false.
            return false;
        }
        IERC4626 wrapper = _wrapper();
        IERC20 underlying = _underlying();
        for (uint256 cursor = 0; cursor < tokenConfig.length; cursor++) {
            // Strategy Vault adaptor pools do not support paying yield fees directly.
            // Strategy Vaults collect their own yield fees based on the underlying token.
            // Esnure that no token is authroized to be collected as yield fees.
            if (tokenConfig[cursor].paysYieldFees) {
                // Short circuit the evaluation by returning false.
                // Doesn't matter if the token is valid, none are allowed to be collected as yield fees.
                return false;
            } // No need for an else, yield fee check would terminate the loop.
            // Check if any iteration has identified an invalid token.
            if (
                address(tokenConfig[cursor].token) != address(wrapper)
                    && address(tokenConfig[cursor].token) != address(underlying)
            ) {
                // Short circuit the evaluation by returning false.
                return false;
            }
        }
        return true;
    }

    function getHookFlags() public view virtual override returns (HookFlags memory hookFlags) {
        // return HookFlags({
        //     enableHookAdjustedAmounts = true,
        //     shouldCallBeforeInitialize = true,
        //     shouldCallAfterInitialize = true,
        //     shouldCallComputeDynamicSwapFee = true,
        //     shouldCallBeforeSwap = true,
        //     shouldCallAfterSwap = true,
        //     shouldCallBeforeAddLiquidity = true,
        //     shouldCallAfterAddLiquidity = true,
        //     shouldCallBeforeRemoveLiquidity = true,
        //     shouldCallAfterRemoveLiquidity = true
        // });
        hookFlags.enableHookAdjustedAmounts = true;

        hookFlags.shouldCallBeforeInitialize = true;
        // hookFlags.shouldCallAfterInitialize = false;

        // hookFlags.shouldCallComputeDynamicSwapFee = false;

        // hookFlags.shouldCallBeforeSwap = true;
        hookFlags.shouldCallAfterSwap = true;

        hookFlags.shouldCallBeforeAddLiquidity = true;
        hookFlags.shouldCallAfterAddLiquidity = true;

        hookFlags.shouldCallBeforeRemoveLiquidity = true;
        hookFlags.shouldCallAfterRemoveLiquidity = true;
    }

    function onBeforeInitialize(uint256[] memory exactAmountsIn, bytes memory) public virtual override returns (bool) {
        // Liquidity may ONLY be the  Wrapper token.
        uint256 wrapperIndex = _balV3IndexOfToken(address(_wrapper()));
        // Iterate over the exact amounts in.
        for (uint256 cursor = 0; cursor < exactAmountsIn.length; cursor++) {
            // If the token is not the wrapper, and the amount is not 0, return false.
            if (cursor != wrapperIndex && exactAmountsIn[cursor] != 0) {
                return false;
            }
            // If the token is the wrapper, and does not meet the Balancer v3 minimum liquidity requirement, return false.
            if (exactAmountsIn[cursor] < 1e6) {
                return false;
            }
        }
        return true;
    }

    error InvalidAmount(uint256 index, uint256 amount);

    function onBeforeAddLiquidity(
        address, // router,
        address, // pool,
        AddLiquidityKind kind,
        uint256[] memory maxAmountsInScaled18,
        uint256, // minBptAmountOut,
        uint256[] memory, // balancesScaled18,
        bytes memory // userData
    ) public view override returns (bool) {
        // ERC4626 Adaptor Pools only hold the Wrapper as liquidity.
        // This means SINGLE_TOKEN_EXACT_OUT(WRAPPER) = PROPORTIONAL.
        if (kind == AddLiquidityKind.PROPORTIONAL || kind == AddLiquidityKind.SINGLE_TOKEN_EXACT_OUT) {
            uint256 wrapperIndex = _balV3IndexOfToken(address(_wrapper()));
            // Ensure only Wrapper tokens are provided
            for (uint256 cursor = 0; cursor < maxAmountsInScaled18.length; cursor++) {
                if (cursor != wrapperIndex) {
                    if (maxAmountsInScaled18[cursor] != 0) {
                        revert InvalidAmount(cursor, maxAmountsInScaled18[cursor]);
                    }
                }
            }
            return true;
        }
        return false;
    }

    function onBeforeRemoveLiquidity(
        address, // router,
        address, // pool,
        RemoveLiquidityKind kind,
        uint256, // maxBptAmountIn,
        uint256[] memory minAmountsOutScaled18,
        uint256[] memory, // balancesScaled18,
        bytes memory // userData
    ) public virtual override returns (bool) {
        // Because Strategy Vault Adaptor Pools only hold the Wrapper as liquidity.
        // This means SINGLE_TOKEN_EXACT_IN(WRAPPER) = PROPORTIONAL.
        // This means SINGLE_TOKEN_EXACT_OUT(WRAPPER) = PROPORTIONAL.
        if (
            kind == RemoveLiquidityKind.PROPORTIONAL || kind == RemoveLiquidityKind.SINGLE_TOKEN_EXACT_IN
                || kind == RemoveLiquidityKind.SINGLE_TOKEN_EXACT_OUT
        ) {
            uint256 wrapperIndex = _balV3IndexOfToken(address(_wrapper()));
            // Ensure only Wrapper tokens are reequested.
            for (uint256 cursor = 0; cursor < minAmountsOutScaled18.length; cursor++) {
                if (cursor != wrapperIndex) {
                    if (minAmountsOutScaled18[cursor] != 0) {
                        revert InvalidAmount(cursor, minAmountsOutScaled18[cursor]);
                    }
                }
            }
            return true;
        }
        return false;
    }

    // error InvalidTokenRoute(address tokenIn, address tokenOut);
    event InsufficientLiquidity(address token, uint256 actual, uint256 required);

    error AmountRejected(address token, uint256 amount);

    function onBeforeSwap(PoolSwapParams calldata params, address pool) public view override returns (bool) {
        IERC4626 wrapper = _wrapper();
        uint256 wrapperIndex = _balV3IndexOfToken(address(wrapper));
        IERC20 underlying = _underlying();
        uint256 underlyingIndex = _balV3IndexOfToken(address(underlying));
        IVault vault = _balV3Vault();
        // address tokenIn = _tokenOfBalV3Index(params.indexIn);
        // address tokenOut = _tokenOfBalV3Index(params.indexOut);
        if (params.kind == SwapKind.EXACT_IN) {
            if (params.indexIn == underlyingIndex) {
                // Check if the Wrapper will allow us to deposit this amount on behalf of the Vault.
                uint256 maxDeposit = wrapper.maxDeposit(address(vault));
                if (params.amountGivenScaled18 > maxDeposit) {
                    // revert AmountRejected(address(underlying), params.amountGivenScaled18);
                    return false;
                }
                // For an EXACT_IN, we can borrow up to that amount from the global Vault resereves.
                // Check if the Vault has enough liquidity to borrow the amount.
                uint256 transientDebtLimit = vault.getReservesOf(IERC20(address(underlying)));
                if (params.amountGivenScaled18 > transientDebtLimit) {
                    // If not log the error and return false.
                    // emit InsufficientLiquidity(address(underlying), transientDebtLimit, params.amountGivenScaled18);
                    return false;
                }
            } else if (params.indexIn == wrapperIndex) {
                // Check if the Wrapper will allow us to redeem this amount.
                uint256 maxWithdraw = wrapper.maxRedeem(address(vault));
                if (params.amountGivenScaled18 > maxWithdraw) {
                    return false;
                }
                // For an EXACT_IN, we can borrow up to that amount from the global Vault resereves.
                // Check if the Vault has enough liquidity to borrow the amount.
                uint256 transientDebtLimit = vault.getReservesOf(IERC20(address(wrapper)));
                if (params.amountGivenScaled18 > transientDebtLimit) {
                    // If not log the error and return false.
                    // emit InsufficientLiquidity(address(underlying), transientDebtLimit, params.amountGivenScaled18);
                    return false;
                }
            }
        } else if (params.kind == SwapKind.EXACT_OUT) {
            if (params.indexOut == underlyingIndex) {
                // Check if the Wrapper will allow us to withdraw this amount.
                uint256 maxWithdraw = wrapper.maxWithdraw(address(this));
                if (params.amountGivenScaled18 > maxWithdraw) {
                    return false;
                }
                uint256 reqShares = wrapper.previewWithdraw(params.amountGivenScaled18);
                // For an EXACT_OUT, we can borrow up to that amount from the pool Vault resereves.
                // Check if the pool has enough liquidity to borrow the amount.
                (uint256 transientDebtLimit,) = vault.getPoolTokenCountAndIndexOfToken(pool, wrapper);
                if (reqShares > transientDebtLimit) {
                    // If not log the error and return false.
                    // emit InsufficientLiquidity(address(underlying), transientDebtLimit, params.amountGivenScaled18);
                    return false;
                }
            } else if (params.indexOut == wrapperIndex) {
                // Check if the Vault will allow us to withdraw this amount.
                uint256 maxWithdraw = wrapper.maxMint(address(vault));
                if (params.amountGivenScaled18 > maxWithdraw) {
                    return false;
                }
                uint256 reqTokens = wrapper.previewMint(params.amountGivenScaled18);
                // For an EXACT_OUT, we can borrow up to that amount from the pool Vault resereves.
                // Check if the pool has enough liquidity to borrow the amount.
                (uint256 transientDebtLimit,) = vault.getPoolTokenCountAndIndexOfToken(pool, wrapper);
                if (reqTokens > transientDebtLimit) {
                    // If not log the error and return false.
                    // emit InsufficientLiquidity(address(underlying), transientDebtLimit, params.amountGivenScaled18);
                    return false;
                }
            }
        }
        return true;
    }

    function onAfterSwap(AfterSwapParams calldata params)
        public
        virtual
        override
        returns (bool success, uint256 hookAdjustedAmountCalculatedRaw)
    {
        IVault vault = _balV3Vault();
        IERC4626 wrapper = _wrapper();
        IERC20 underlying = _underlying();
        // Check swap orientation.
        if (params.kind == SwapKind.EXACT_IN) {
            // Underlying in indicates deposit into Wrapper.
            if (address(params.tokenIn) == address(underlying)) {
                // Pull the amount in from the Vault.
                vault.sendTo(params.tokenIn, address(this), params.amountInScaled18);
                // Approve the Wrapper to spend the tokens.
                IERC20(address(params.tokenIn)).safeApprove(address(wrapper), params.amountInScaled18);
                // Deposit the tokens into the Wrapper.
                uint256 wrapperShares = wrapper.deposit(params.amountInScaled18, address(vault));
                // Remove the approval.
                IERC20(address(params.tokenIn)).safeApprove(address(wrapper), 0);
                // Update the Vault's reserves of the underlying.
                vault.settle(IERC20(address(underlying)), params.amountInScaled18);
                // Update the Vault's reserves of the wrapper.
                vault.settle(params.tokenOut, wrapperShares);
                // Return the success and the amount of wrapper shares.
                return (true, wrapperShares);
            }
            // Wrapper in indicates redeem from Wrapper.
            else if (address(params.tokenIn) == address(wrapper)) {
                // Pull the Wrapper shares amount in from the Vault.
                vault.sendTo(params.tokenIn, address(this), params.amountInScaled18);
                // Redeem the shares from the Wrapper.
                uint256 redeemedTokens = wrapper.redeem(params.amountInScaled18, address(vault), address(this));
                // Update the Vault's reserves of the wrapper.
                vault.settle(params.tokenIn, params.amountInScaled18);
                // Update the Vault's reserves of the underlying.
                vault.settle(params.tokenOut, redeemedTokens);
                return (true, redeemedTokens);
            }
        } else if (params.kind == SwapKind.EXACT_OUT) {
            // Underlying out indicates withdraw from Wrapper.
            if (address(params.tokenOut) == address(underlying)) {
                // Calculate the amount of shares to withdraw.
                uint256 reqShares = wrapper.previewWithdraw(params.amountOutScaled18);
                // Pull the Wrapper shares from the Vault.
                vault.sendTo(params.tokenIn, address(this), reqShares);
                // Withdraw the shares from the Wrapper.
                // uint256 burnedShares =
                wrapper.withdraw(params.amountOutScaled18, address(vault), address(this));
                // Update the Vault's reserves of the wrapper.
                vault.settle(params.tokenIn, reqShares);
                // Update the Vault's reserves of the underlying.
                vault.settle(params.tokenOut, params.amountOutScaled18);
                return (true, params.amountOutScaled18);
            }
            // Wrapper out indicates mint into Wrapper.
            else if (address(params.tokenOut) == address(wrapper)) {
                // Calculate the amount of shares to mint.
                uint256 reqShares = wrapper.previewMint(params.amountOutScaled18);
                // Pull the underlying from the Vault.
                vault.sendTo(params.tokenIn, address(this), reqShares);
                // Mint the shares into the Vault.
                uint256 mintedShares = wrapper.mint(params.amountOutScaled18, address(vault));
                // Update the Vault's reserves of the wrapper.
                vault.settle(params.tokenIn, reqShares);
                // Update the Vault's reserves of the underlying.
                vault.settle(params.tokenOut, mintedShares);
                return (true, mintedShares);
            }
        }
    }
}
