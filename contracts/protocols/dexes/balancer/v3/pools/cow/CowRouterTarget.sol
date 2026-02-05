// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                              OpenZeppelin                                  */
/* -------------------------------------------------------------------------- */

import {SafeERC20} from "@crane/contracts/utils/SafeERC20.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                              Balancer V3 Interfaces                        */
/* -------------------------------------------------------------------------- */

import {ICowRouter} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-cow/ICowRouter.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {
    AddLiquidityKind,
    AddLiquidityParams,
    SwapKind,
    VaultSwapParams
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BalancerV3AuthenticationModifiers} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationModifiers.sol";
import {BalancerV3VaultAwareRepo} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareRepo.sol";
import {BalancerV3VaultGuardModifiers} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultGuardModifiers.sol";
import {CowRouterRepo} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowRouterRepo.sol";

/**
 * @title CowRouterTarget
 * @notice Implementation contract for Balancer V3 CoW Router functionality.
 * @dev CoW Routers handle MEV-protected swaps and surplus donations for CoW Protocol.
 *
 * Key features:
 * - Swap + Donate in single transaction (for MEV surplus capture)
 * - Pure donate functionality
 * - Protocol fee collection on donations
 * - Fee withdrawal to configurable sweeper
 *
 * Storage dependencies:
 * - CowRouterRepo: fee settings and collected fees
 * - BalancerV3VaultAwareRepo: vault reference
 */
contract CowRouterTarget is ICowRouter, BalancerV3AuthenticationModifiers, BalancerV3VaultGuardModifiers {
    using FixedPoint for uint256;
    using SafeERC20 for IERC20;

    /* -------------------------------------------------------------------------- */
    /*                              Getters and Setters                           */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICowRouter
    function getProtocolFeePercentage() external view returns (uint256 protocolFeePercentage) {
        return CowRouterRepo._getProtocolFeePercentage();
    }

    /// @inheritdoc ICowRouter
    function getMaxProtocolFeePercentage() external pure returns (uint256) {
        return CowRouterRepo._getMaxProtocolFeePercentage();
    }

    /// @inheritdoc ICowRouter
    function getCollectedProtocolFees(IERC20 token) external view returns (uint256 fees) {
        return CowRouterRepo._getCollectedProtocolFees(token);
    }

    /// @inheritdoc ICowRouter
    function getFeeSweeper() external view returns (address feeSweeper) {
        return CowRouterRepo._getFeeSweeper();
    }

    /// @inheritdoc ICowRouter
    function setProtocolFeePercentage(uint256 newProtocolFeePercentage)
        external
        authenticate(address(this))
    {
        CowRouterRepo._setProtocolFeePercentage(newProtocolFeePercentage);
    }

    /// @inheritdoc ICowRouter
    function setFeeSweeper(address newFeeSweeper) external authenticate(address(this)) {
        CowRouterRepo._setFeeSweeper(newFeeSweeper);
    }

    /* -------------------------------------------------------------------------- */
    /*                            Swaps and Donations                             */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICowRouter
    function swapExactInAndDonateSurplus(
        address pool,
        IERC20 swapTokenIn,
        IERC20 swapTokenOut,
        uint256 swapExactAmountIn,
        uint256 swapMinAmountOut,
        uint256 swapDeadline,
        uint256[] memory donationAmounts,
        uint256[] memory transferAmountHints,
        bytes memory userData
    ) external authenticate(address(this)) returns (uint256 exactAmountOut) {
        IVault vault = BalancerV3VaultAwareRepo._balancerV3Vault();

        (, exactAmountOut) = abi.decode(
            vault.unlock(
                abi.encodeCall(
                    CowRouterTarget.swapAndDonateSurplusHook,
                    SwapAndDonateHookParams({
                        pool: pool,
                        sender: msg.sender,
                        swapKind: SwapKind.EXACT_IN,
                        swapTokenIn: swapTokenIn,
                        swapTokenOut: swapTokenOut,
                        swapAmountGiven: swapExactAmountIn,
                        swapLimit: swapMinAmountOut,
                        swapDeadline: swapDeadline,
                        donationAmounts: donationAmounts,
                        transferAmountHints: transferAmountHints,
                        userData: userData
                    })
                )
            ),
            (uint256, uint256)
        );
    }

    /// @inheritdoc ICowRouter
    function swapExactOutAndDonateSurplus(
        address pool,
        IERC20 swapTokenIn,
        IERC20 swapTokenOut,
        uint256 swapMaxAmountIn,
        uint256 swapExactAmountOut,
        uint256 swapDeadline,
        uint256[] memory donationAmounts,
        uint256[] memory transferAmountHints,
        bytes memory userData
    ) external authenticate(address(this)) returns (uint256 exactAmountIn) {
        IVault vault = BalancerV3VaultAwareRepo._balancerV3Vault();

        (exactAmountIn,) = abi.decode(
            vault.unlock(
                abi.encodeCall(
                    CowRouterTarget.swapAndDonateSurplusHook,
                    SwapAndDonateHookParams({
                        pool: pool,
                        sender: msg.sender,
                        swapKind: SwapKind.EXACT_OUT,
                        swapTokenIn: swapTokenIn,
                        swapTokenOut: swapTokenOut,
                        swapAmountGiven: swapExactAmountOut,
                        swapLimit: swapMaxAmountIn,
                        swapDeadline: swapDeadline,
                        donationAmounts: donationAmounts,
                        transferAmountHints: transferAmountHints,
                        userData: userData
                    })
                )
            ),
            (uint256, uint256)
        );
    }

    /// @inheritdoc ICowRouter
    function donate(address pool, uint256[] memory donationAmounts, bytes memory userData)
        external
        authenticate(address(this))
    {
        IVault vault = BalancerV3VaultAwareRepo._balancerV3Vault();

        vault.unlock(
            abi.encodeCall(
                CowRouterTarget.donateHook,
                DonateHookParams({pool: pool, sender: msg.sender, donationAmounts: donationAmounts, userData: userData})
            )
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                          Withdraw Protocol Fees                            */
    /* -------------------------------------------------------------------------- */

    /// @inheritdoc ICowRouter
    function withdrawCollectedProtocolFees(IERC20 token) external {
        uint256 amountToWithdraw = CowRouterRepo._clearCollectedFees(token);
        if (amountToWithdraw > 0) {
            address feeSweeper = CowRouterRepo._getFeeSweeper();
            token.safeTransfer(feeSweeper, amountToWithdraw);
            emit ProtocolFeesWithdrawn(token, feeSweeper, amountToWithdraw);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    Hooks                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Hook for swapping and donating to a CoW AMM pool.
     * @dev Can only be called by the Vault.
     * @param swapAndDonateParams Swap and donate params (see ICowRouter for struct definition)
     * @return swapAmountIn Exact amount of tokenIn of the swap
     * @return swapAmountOut Exact amount of tokenOut of the swap
     */
    function swapAndDonateSurplusHook(SwapAndDonateHookParams memory swapAndDonateParams)
        external
        onlyBalancerV3Vault
        returns (uint256 swapAmountIn, uint256 swapAmountOut)
    {
        IVault vault = BalancerV3VaultAwareRepo._balancerV3Vault();
        (IERC20[] memory tokens,,,) = vault.getPoolTokenInfo(swapAndDonateParams.pool);

        // Deadline check
        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp > swapAndDonateParams.swapDeadline) {
            revert SwapDeadline();
        }

        // Execute swap
        if (swapAndDonateParams.swapKind == SwapKind.EXACT_IN) {
            swapAmountIn = swapAndDonateParams.swapAmountGiven;
            (,, swapAmountOut) = vault.swap(
                VaultSwapParams({
                    kind: SwapKind.EXACT_IN,
                    pool: swapAndDonateParams.pool,
                    tokenIn: swapAndDonateParams.swapTokenIn,
                    tokenOut: swapAndDonateParams.swapTokenOut,
                    amountGivenRaw: swapAndDonateParams.swapAmountGiven,
                    limitRaw: swapAndDonateParams.swapLimit,
                    userData: swapAndDonateParams.userData
                })
            );
        } else {
            swapAmountOut = swapAndDonateParams.swapAmountGiven;
            (, swapAmountIn,) = vault.swap(
                VaultSwapParams({
                    kind: SwapKind.EXACT_OUT,
                    pool: swapAndDonateParams.pool,
                    tokenIn: swapAndDonateParams.swapTokenIn,
                    tokenOut: swapAndDonateParams.swapTokenOut,
                    amountGivenRaw: swapAndDonateParams.swapAmountGiven,
                    limitRaw: swapAndDonateParams.swapLimit,
                    userData: swapAndDonateParams.userData
                })
            );
        }

        // Process donation
        (uint256[] memory donatedAmounts, uint256[] memory protocolFeeAmounts) =
            _donateToPool(vault, swapAndDonateParams.pool, tokens, swapAndDonateParams.donationAmounts, swapAndDonateParams.userData);

        // Settle
        _settleSwapAndDonation(
            vault,
            swapAndDonateParams.sender,
            tokens,
            swapAndDonateParams.swapTokenIn,
            swapAndDonateParams.swapTokenOut,
            swapAmountIn,
            swapAmountOut,
            swapAndDonateParams.transferAmountHints,
            donatedAmounts,
            protocolFeeAmounts
        );

        emit CoWSwapAndDonation(
            swapAndDonateParams.pool,
            swapAndDonateParams.swapTokenIn,
            swapAndDonateParams.swapTokenOut,
            swapAmountIn,
            swapAmountOut,
            donatedAmounts,
            protocolFeeAmounts,
            swapAndDonateParams.userData
        );
    }

    /**
     * @notice Hook for donating values to a CoW AMM pool.
     * @dev Can only be called by the Vault.
     * @param params Donate params (see ICowRouter for struct definition)
     */
    function donateHook(DonateHookParams memory params) external onlyBalancerV3Vault {
        IVault vault = BalancerV3VaultAwareRepo._balancerV3Vault();
        (IERC20[] memory tokens,,,) = vault.getPoolTokenInfo(params.pool);

        (uint256[] memory donatedAmounts, uint256[] memory protocolFeeAmounts) =
            _donateToPool(vault, params.pool, tokens, params.donationAmounts, params.userData);

        // This hook assumes exact transfers: donationAmounts == transferAmountHints, senderCredits == 0
        _settleDonation(
            vault,
            params.sender,
            tokens,
            params.donationAmounts,
            protocolFeeAmounts,
            new uint256[](params.donationAmounts.length)
        );

        emit CoWDonation(params.pool, donatedAmounts, protocolFeeAmounts, params.userData);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Private Helpers                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Process a donation to a pool, deducting protocol fees.
     * @param vault The Balancer V3 vault.
     * @param pool The pool to donate to.
     * @param tokens Pool tokens in registration order.
     * @param amountsToDonate Amounts to donate including fees.
     * @param userData Additional data for the donation.
     * @return donatedAmounts Amounts actually donated (after fee deduction).
     * @return protocolFeeAmounts Fees collected for each token.
     */
    function _donateToPool(
        IVault vault,
        address pool,
        IERC20[] memory tokens,
        uint256[] memory amountsToDonate,
        bytes memory userData
    ) private returns (uint256[] memory donatedAmounts, uint256[] memory protocolFeeAmounts) {
        donatedAmounts = new uint256[](amountsToDonate.length);
        protocolFeeAmounts = new uint256[](amountsToDonate.length);

        uint256 totalAmountToDonate;
        uint256 protocolFeePercentage = CowRouterRepo._getProtocolFeePercentage();

        for (uint256 i = 0; i < amountsToDonate.length; i++) {
            IERC20 token = tokens[i];

            uint256 donationAndFees = amountsToDonate[i];
            uint256 protocolFee = donationAndFees.mulUp(protocolFeePercentage);
            CowRouterRepo._addCollectedFees(token, protocolFee);
            protocolFeeAmounts[i] = protocolFee;
            donatedAmounts[i] = donationAndFees - protocolFee;

            totalAmountToDonate += donatedAmounts[i];
        }

        if (totalAmountToDonate > 0) {
            vault.addLiquidity(
                AddLiquidityParams({
                    pool: pool,
                    to: address(this), // Donation, no BPT transferred
                    maxAmountsIn: donatedAmounts,
                    minBptAmountOut: 0,
                    kind: AddLiquidityKind.DONATION,
                    userData: userData
                })
            );
        }
    }

    /**
     * @notice Settle a swap and donation operation.
     * @dev Verifies upfront transfers cover swap + donation + fees, returns excess to sender.
     */
    function _settleSwapAndDonation(
        IVault vault,
        address sender,
        IERC20[] memory tokens,
        IERC20 swapTokenIn,
        IERC20 swapTokenOut,
        uint256 swapAmountIn,
        uint256 swapAmountOut,
        uint256[] memory transferAmountHints,
        uint256[] memory donatedAmounts,
        uint256[] memory feeAmounts
    ) private {
        uint256[] memory senderCredits = new uint256[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            uint256 rawSenderCredits = transferAmountHints[i];
            uint256 rawSenderDebts = donatedAmounts[i] + feeAmounts[i];

            if (tokens[i] == swapTokenIn) {
                rawSenderDebts += swapAmountIn;
            } else if (tokens[i] == swapTokenOut) {
                rawSenderCredits += swapAmountOut;
            }

            if (rawSenderCredits < rawSenderDebts) {
                revert InsufficientFunds(tokens[i], rawSenderCredits, rawSenderDebts);
            }

            senderCredits[i] = rawSenderCredits - rawSenderDebts;
        }

        _settleDonation(vault, sender, tokens, transferAmountHints, feeAmounts, senderCredits);
    }

    /**
     * @notice Settle a donation by transferring tokens and settling vault reserves.
     */
    function _settleDonation(
        IVault vault,
        address sender,
        IERC20[] memory tokens,
        uint256[] memory transferAmountHints,
        uint256[] memory routerCredits,
        uint256[] memory senderCredits
    ) private {
        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = tokens[i];

            // Settle tokens transferred to vault
            uint256 transferAmountHint = transferAmountHints[i];
            if (transferAmountHint > 0) {
                vault.settle(token, transferAmountHint);
            }

            // Send protocol fees to router
            uint256 sendToRouterAmount = routerCredits[i];
            if (sendToRouterAmount > 0) {
                vault.sendTo(token, address(this), sendToRouterAmount);
            }

            // Return excess to sender
            uint256 returnToSenderAmount = senderCredits[i];
            if (returnToSenderAmount > 0) {
                vault.sendTo(token, sender, returnToSenderAmount);
            }
        }
    }
}
