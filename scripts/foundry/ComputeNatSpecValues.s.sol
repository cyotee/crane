// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Script} from "forge-std/Script.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {IStandardExchangeIn} from "@crane/contracts/interfaces/IStandardExchangeIn.sol";
import {IStandardExchangeOut} from "@crane/contracts/interfaces/IStandardExchangeOut.sol";
import {IStandardizedYield} from "@crane/contracts/protocols/perps/pendle/interfaces/IStandardizedYield.sol";
import {IUnlockCallback} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/callback/IUnlockCallback.sol";
import {IBasicVault} from "contracts/vaults/basic/IBasicVault.sol";
import {IStandardVault} from "contracts/interfaces/IStandardVault.sol";
import {IStandardVaultPkg} from "contracts/interfaces/IStandardVaultPkg.sol";
import {UniswapV4PairTokenStandardExchangeVaultWorkBudgetTest as PairTokenWorkBudgetTest} from "test/foundry/spec/vaults/standard/exchange/protocols/uniswap/v4/pairToken/UniswapV4PairTokenStandardExchangeVaultWorkBudget.t.sol";
import {IUniswapV4PairTokenStandardExchangeVault as IVault} from "contracts/vaults/standard/exchange/protocols/uniswap/v4/pairToken/interfaces/IUniswapV4PairTokenStandardExchangeVault.sol";
import {IUniswapV4PairTokenStandardExchangeVaultDFPkg as IPairTokenPackage} from "contracts/vaults/standard/exchange/protocols/uniswap/v4/pairToken/interfaces/IUniswapV4PairTokenStandardExchangeVaultDFPkg.sol";
import {UniswapV4PairTokenStandardExchangeVaultRepo as PairTokenRepo} from "contracts/vaults/standard/exchange/protocols/uniswap/v4/pairToken/UniswapV4PairTokenStandardExchangeVaultRepo.sol";
import {UniswapV4PairTokenStandardExchangeVaultMath as PTMath} from "contracts/vaults/standard/exchange/protocols/uniswap/v4/pairToken/UniswapV4PairTokenStandardExchangeVaultMath.sol";
import {UniswapV4PairTokenStandardExchangeVaultProjection as PTProjection} from "contracts/vaults/standard/exchange/protocols/uniswap/v4/pairToken/UniswapV4PairTokenStandardExchangeVaultProjection.sol";
import {UniswapV4PairTokenStandardExchangeVaultPlanner as PTPlanner} from "contracts/vaults/standard/exchange/protocols/uniswap/v4/pairToken/UniswapV4PairTokenStandardExchangeVaultPlanner.sol";
import {UniswapV4PairTokenStandardExchangeVaultExecution as PTExecution} from "contracts/vaults/standard/exchange/protocols/uniswap/v4/pairToken/UniswapV4PairTokenStandardExchangeVaultExecution.sol";
import {UniswapV4PairTokenStandardExchangeVaultComponent_FactoryService as PTComponents} from "contracts/vaults/standard/exchange/protocols/uniswap/v4/pairToken/UniswapV4PairTokenStandardExchangeVaultComponent_FactoryService.sol";

/**
 * @dev Minimal interface declarations for interfaceId computation ONLY.
 *      Mirrors the public surface of the real interfaces for accurate type().interfaceId.
 *      Kept in sync with real interfaces; used exclusively by this verification script.
 */
interface IFacet {
    function facetName() external view returns (string memory);
    function facetInterfaces() external view returns (bytes4[] memory);
    function facetFuncs() external view returns (bytes4[] memory);
    function facetMetadata() external view returns (string memory, bytes4[] memory, bytes4[] memory);
}

interface IDiamondFactoryPackage {
    function packageName() external view returns (string memory);
    function facetInterfaces() external view returns (bytes4[] memory);
    function facetAddresses() external view returns (address[] memory);
    function packageMetadata() external view returns (string memory, bytes4[] memory, address[] memory, bytes memory);
    function facetCuts() external view returns (bytes memory); // simplified; real returns struct[]
    function diamondConfig() external view returns (bytes memory);
    function calcSalt(bytes memory pkgArgs) external view returns (bytes32);
    function processArgs(bytes memory pkgArgs) external view returns (bytes memory);
    function updatePkg(address account, bytes memory updateArgs) external;
    function initAccount(bytes memory initArgs) external;
    function postDeploy(address account) external returns (bool);
}

interface IDiamondPackageCallBackFactory {
    function PROXY_INIT_HASH() external view returns (bytes32);
    function ERC165_FACET() external view returns (address);
    function DIAMOND_LOUPE_FACET() external view returns (address);
    function POST_DEPLOY_HOOK_FACET() external view returns (address);
    function pkgOfAccount(address account) external view returns (address);
    function pkgArgsOfAccount(address account) external view returns (bytes memory);
    function calcAddress(address pkg, bytes memory pkgArgs) external view returns (address);
    function deploy(address pkg, bytes memory pkgArgs) external returns (address account);
    function initAccount(address account, bytes memory initArgs) external;
}

interface ICreate3Factory {
    function diamondPackageFactory() external view returns (address);
    function setDiamondPackageFactory(address factory) external;
    function create3(bytes memory creationCode, bytes32 salt) external returns (address);
    function create3WithArgs(bytes memory creationCode, bytes memory constructorArgs, bytes32 salt)
        external
        returns (address);
}

interface IOperable {
    function isOperator(address operator) external view returns (bool);
    function isOperatorFor(bytes4 func, address operator) external view returns (bool);
    function setOperator(address operator, bool status) external;
    function setOperatorFor(bytes4 func, address operator, bool status) external;
}

interface IMultiStepOwnable {
    function initiateOwnershipTransfer(address newOwner) external;
    function confirmOwnershipTransfer(address newOwner) external;
    function cancelPendingOwnershipTransfer() external;
    function acceptOwnershipTransfer() external;
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function preConfirmedOwner() external view returns (address);
    function getOwnershipTransferBuffer() external view returns (uint256);
}

/**
 * @title ComputeNatSpecValues
 * @notice Dedicated Foundry Script per LR-1 to authoritatively compute
 *         @custom:selector / @custom:interfaceid / @custom:topiczero values
 *         using the Solidity compiler (type(I).interfaceId and keccak inside compiled code).
 *         Run with: forge script scripts/foundry/ComputeNatSpecValues.s.sol --sig "run()" -vvv
 *         (Values appear in console logs. Use for populating CENTRALLY_COMPUTED_NATSPEC_VALUES.md and sources.)
 * @dev This replaces ad-hoc `cast` usage for verification/central population. Re-runnable in CI/release.
 * @custom:signature run()
 */
contract ComputeNatSpecValues is Script {
    /* -------------------------------------------------------------------------- */
    /*                                 Constants                                  */
    /* -------------------------------------------------------------------------- */

    // tag::ComputeNatSpecValues[]
    /**
     * @notice Computes and logs NatSpec custom tag values for core interfaces and symbols.
     * @dev Interface IDs use the compiler's type(I).interfaceId (XOR of function selectors).
     *      Selectors and topic0 use keccak256 in Solidity for exact compiler match.
     */
    function run() public view {
        _pairTokenValues();
        _pairTokenLinkedValues();
        _assertPairTokenSelector("test_BUD_Crossing12Allowed13RejectedWithoutFetchingTick()", PairTokenWorkBudgetTest.test_BUD_Crossing12Allowed13RejectedWithoutFetchingTick.selector);
        _assertPairTokenSelector("test_BUD_RepeatCrossingsShareTheWholeCandidateBudget()", PairTokenWorkBudgetTest.test_BUD_RepeatCrossingsShareTheWholeCandidateBudget.selector);
        _assertPairTokenSelector("test_BUD_DistinctWord16Allowed17RejectedAndRepeatReadFree()", PairTokenWorkBudgetTest.test_BUD_DistinctWord16Allowed17RejectedAndRepeatReadFree.selector);
        _assertPairTokenSelector("test_BUD_Iteration64Allowed65RejectedComponentGuard()", PairTokenWorkBudgetTest.test_BUD_Iteration64Allowed65RejectedComponentGuard.selector);
        _assertPairTokenSelector("test_BUD_DenseSingleExitRejectedBeforeBurnAndPairRemainsAffordable()", PairTokenWorkBudgetTest.test_BUD_DenseSingleExitRejectedBeforeBurnAndPairRemainsAffordable.selector);
        _assertPairTokenSelector("test_BUD_BitmapExhaustionPreservesPairedEscapeAndRejectsZap()", PairTokenWorkBudgetTest.test_BUD_BitmapExhaustionPreservesPairedEscapeAndRejectsZap.selector);
        _assertPairTokenSelector("test_BUD_MaximumCrossingFallbackWithBothFeeCurrencies()", PairTokenWorkBudgetTest.test_BUD_MaximumCrossingFallbackWithBothFeeCurrencies.selector);
        _assertPairTokenSelector("test_BUD_MaintenanceFitsButFinalSaleExhaustsSharedBudget()", PairTokenWorkBudgetTest.test_BUD_MaintenanceFitsButFinalSaleExhaustsSharedBudget.selector);
        _assertPairTokenSelector("test_BUD_MaximumSupportedEntryAcrossMaintenanceAndZap()", PairTokenWorkBudgetTest.test_BUD_MaximumSupportedEntryAcrossMaintenanceAndZap.selector);
        _assertPairTokenSelector("test_BUD_MaximumSupportedToken1Entry()", PairTokenWorkBudgetTest.test_BUD_MaximumSupportedToken1Entry.selector);
        _assertPairTokenSelector("test_BUD_MaximumSupportedNativeEntry()", PairTokenWorkBudgetTest.test_BUD_MaximumSupportedNativeEntry.selector);
        _assertPairTokenSelector("test_BUD_MaximumSupportedWrappedEntry()", PairTokenWorkBudgetTest.test_BUD_MaximumSupportedWrappedEntry.selector);
        _assertPairTokenSelector("test_BUD_MaximumSupportedNativePoolToken1Entry()", PairTokenWorkBudgetTest.test_BUD_MaximumSupportedNativePoolToken1Entry.selector);
        _assertPairTokenSelector("test_BUD_MaximumFullCompoundPairedAndTerminalExits()", PairTokenWorkBudgetTest.test_BUD_MaximumFullCompoundPairedAndTerminalExits.selector);
        _assertPairTokenSelector("test_BUD_MaximumNativeFullCompoundPairedAndTerminalExits()", PairTokenWorkBudgetTest.test_BUD_MaximumNativeFullCompoundPairedAndTerminalExits.selector);
        console2.log("=== Crane NatSpec Values (Foundry Script - LR-1) ===");
        console2.log("Date: use current; regenerate when interfaces change");
        console2.log("");

        // --- Interface IDs (preferred compiler method) ---
        console2.log("Interface IDs:");
        console2.log("IFacet: ");
        console2.logBytes4(type(IFacet).interfaceId);
        console2.log("IDiamondFactoryPackage: ");
        console2.logBytes4(type(IDiamondFactoryPackage).interfaceId);
        console2.log("IDiamondPackageCallBackFactory: ");
        console2.logBytes4(type(IDiamondPackageCallBackFactory).interfaceId);
        console2.log("ICreate3Factory: ");
        console2.logBytes4(type(ICreate3Factory).interfaceId);
        console2.log("IOperable: ");
        console2.logBytes4(type(IOperable).interfaceId);
        console2.log("IMultiStepOwnable: ");
        console2.logBytes4(type(IMultiStepOwnable).interfaceId);
        console2.log("");

        // --- Common Function Selectors (via keccak in script for reproducibility) ---
        console2.log("Function selectors:");
        _logSelector("facetName()", type(IFacet).interfaceId); // example, but actually use the interface's
        _logSelector("facetInterfaces()", type(IFacet).interfaceId);
        _logSelector("facetFuncs()", type(IFacet).interfaceId);
        _logSelector("facetMetadata()", type(IFacet).interfaceId);
        _logSelector("supportsInterface(bytes4)", type(IFacet).interfaceId); // note: this is IERC165

        _logSelector("packageName()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("facetInterfaces()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("facetAddresses()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("packageMetadata()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("facetCuts()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("diamondConfig()", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("calcSalt(bytes)", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("processArgs(bytes)", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("updatePkg(address,bytes)", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("initAccount(bytes)", type(IDiamondFactoryPackage).interfaceId);
        _logSelector("postDeploy(address)", type(IDiamondFactoryPackage).interfaceId);

        _logSelector("deploy(address,bytes)", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("calcAddress(address,bytes)", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("initAccount(address,bytes)", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("pkgOfAccount(address)", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("PROXY_INIT_HASH()", type(IDiamondPackageCallBackFactory).interfaceId);
        _logSelector("pkgConfig()", 0); // impl only

        _logSelector("diamondPackageFactory()", type(ICreate3Factory).interfaceId);
        _logSelector("setDiamondPackageFactory(address)", type(ICreate3Factory).interfaceId);
        _logSelector("create3(bytes,bytes32)", type(ICreate3Factory).interfaceId);
        _logSelector("create3WithArgs(bytes,bytes,bytes32)", type(ICreate3Factory).interfaceId);

        _logSelector("isOperator(address)", type(IOperable).interfaceId);
        _logSelector("isOperatorFor(bytes4,address)", type(IOperable).interfaceId);
        _logSelector("setOperator(address,bool)", type(IOperable).interfaceId);
        _logSelector("setOperatorFor(bytes4,address,bool)", type(IOperable).interfaceId);

        _logSelector("initiateOwnershipTransfer(address)", type(IMultiStepOwnable).interfaceId);
        _logSelector("confirmOwnershipTransfer(address)", type(IMultiStepOwnable).interfaceId);
        _logSelector("cancelPendingOwnershipTransfer()", type(IMultiStepOwnable).interfaceId);
        _logSelector("acceptOwnershipTransfer()", type(IMultiStepOwnable).interfaceId);
        _logSelector("owner()", type(IMultiStepOwnable).interfaceId);
        _logSelector("pendingOwner()", type(IMultiStepOwnable).interfaceId);
        _logSelector("preConfirmedOwner()", type(IMultiStepOwnable).interfaceId);
        _logSelector("getOwnershipTransferBuffer()", type(IMultiStepOwnable).interfaceId);

        console2.log("");

        // --- Event topic0 (keccak of canonical signature) ---
        console2.log("Event topic0:");
        _logTopic0("NewGlobalOperatorStatus(address,bool)");
        _logTopic0("NewFunctionOperatorStatus(address,bytes4,bool)");
        _logTopic0("OwnershipTransferInitiated(address,address)");
        _logTopic0("OwnershipTransferConfirmed(address,address)");
        _logTopic0("OwnershipTransferred(address,address)");

        console2.log("");

        // --- Error selectors ---
        console2.log("Error selectors:");
        _logSelector("NotOperator(address)", 0);
        _logSelector("NotOwner(address)", 0);
        _logSelector("NotPending(address)", 0);
        _logSelector("BufferPeriodNotElapsed(uint256,uint256)", 0);
        _logSelector("DeploymentAddressMismatch(address,address)", 0);

        console2.log("");
        console2.log("=== End NatSpec Values ===");
        console2.log("Copy the bytes values above into CENTRALLY_COMPUTED_NATSPEC_VALUES.md and source NatSpec.");
        console2.log("Re-run after any interface change to keep single source of truth.");
    }

    // end::ComputeNatSpecValues[]

    /* -------------------------------------------------------------------------- */
    /*                               Internal Utils                               */
    /* -------------------------------------------------------------------------- */

    // tag::_logSelector(string-bytes4)[]
    /**
     * @dev Logs a function/error selector using Solidity keccak (compiler accurate).
     * @param sig The canonical signature string e.g. "foo(address)".
     * @param _ignored present for call compatibility in listing.
     */
    function _logSelector(string memory sig, bytes4 _ignored) internal pure {
        bytes4 sel = bytes4(keccak256(bytes(sig)));
        console2.log(string.concat("selector(", sig, ") = "));
        console2.logBytes4(sel);
    }

    // end::_logSelector(string-bytes4)[]

    // tag::_logTopic0(string)[]
    /**
     * @dev Logs event topic0 using Solidity keccak.
     * @param sig The event signature e.g. "Event(address)".
     */
    function _logTopic0(string memory sig) internal pure {
        bytes32 topic = keccak256(bytes(sig));
        console2.log(string.concat("topic0(", sig, ") = "));
        console2.logBytes32(topic);
    }
    // end::_logTopic0(string)[]

    /// @dev New family checks import the real interfaces, unlike the historical core mirrors above.
    function _pairTokenValues() internal pure {
        console2.log("=== PairToken Standard Exchange typed values ===");
        _assertPairTokenSelector("name()", IERC20Metadata.name.selector);
        _assertPairTokenSelector("symbol()", IERC20Metadata.symbol.selector);
        _assertPairTokenSelector("decimals()", IERC20Metadata.decimals.selector);
        _assertPairTokenSelector("totalSupply()", IERC20.totalSupply.selector);
        _assertPairTokenSelector("balanceOf(address)", IERC20.balanceOf.selector);
        _assertPairTokenSelector("allowance(address,address)", IERC20.allowance.selector);
        _assertPairTokenSelector("approve(address,uint256)", IERC20.approve.selector);
        _assertPairTokenSelector("transfer(address,uint256)", IERC20.transfer.selector);
        _assertPairTokenSelector("transferFrom(address,address,uint256)", IERC20.transferFrom.selector);
        _assertPairTokenSelector("permit(address,address,uint256,uint256,uint8,bytes32,bytes32)", IERC20Permit.permit.selector);
        _assertPairTokenSelector("nonces(address)", IERC20Permit.nonces.selector);
        _assertPairTokenSelector("DOMAIN_SEPARATOR()", IERC20Permit.DOMAIN_SEPARATOR.selector);
        _assertPairTokenSelector("eip712Domain()", IERC5267.eip712Domain.selector);
        _assertPairTokenSelector("vaultTokens()", IBasicVault.vaultTokens.selector);
        _assertPairTokenSelector("reserveOfToken(address)", IBasicVault.reserveOfToken.selector);
        _assertPairTokenSelector("reserves()", IBasicVault.reserves.selector);
        _assertPairTokenSelector("vaultFeeTypeIds()", IStandardVault.vaultFeeTypeIds.selector);
        _assertPairTokenSelector("contentsId()", IStandardVault.contentsId.selector);
        _assertPairTokenSelector("vaultTypes()", IStandardVault.vaultTypes.selector);
        _assertPairTokenSelector("vaultConfig()", IStandardVault.vaultConfig.selector);
        _assertPairTokenSelector("exchangeIn(address,uint256,address,uint256,address,bool,uint256)", IStandardExchangeIn.exchangeIn.selector);
        _assertPairTokenSelector("depositPair(uint256,uint256,uint256,address,uint256)", IVault.depositPair.selector);
        _assertPairTokenSelector("redeemPair(uint256,uint256,uint256,address,uint256)", IVault.redeemPair.selector);
        _assertPairTokenSelector("donate(address,uint256)", IVault.donate.selector);
        _assertPairTokenSelector("compound()", IVault.compound.selector);
        _assertPairTokenSelector("previewExchangeIn(address,uint256,address)", IStandardExchangeIn.previewExchangeIn.selector);
        _assertPairTokenSelector("previewDepositPair(uint256,uint256)", IVault.previewDepositPair.selector);
        _assertPairTokenSelector("previewRedeemPair(uint256)", IVault.previewRedeemPair.selector);
        _assertPairTokenSelector("previewWithdrawalMode(uint256,bool,address)", IVault.previewWithdrawalMode.selector);
        _assertPairTokenSelector("previewZapCredit(address,uint256)", IVault.previewZapCredit.selector);
        _assertPairTokenSelector("previewExchangeOut(address,address,uint256)", IStandardExchangeOut.previewExchangeOut.selector);
        _assertPairTokenSelector("exchangeOut(address,uint256,address,uint256,address,bool,uint256)", IStandardExchangeOut.exchangeOut.selector);
        _assertPairTokenSelector("poolManager()", IVault.poolManager.selector);
        _assertPairTokenSelector("poolKey()", IVault.poolKey.selector);
        _assertPairTokenSelector("wrappedNative()", IVault.wrappedNative.selector);
        _assertPairTokenSelector("rateAsset()", IVault.rateAsset.selector);
        _assertPairTokenSelector("tickLower()", IVault.tickLower.selector);
        _assertPairTokenSelector("tickUpper()", IVault.tickUpper.selector);
        _assertPairTokenSelector("positionLiquidity()", IVault.positionLiquidity.selector);
        _assertPairTokenSelector("localReserves()", IVault.localReserves.selector);
        _assertPairTokenSelector("basket()", IVault.basket.selector);
        _assertPairTokenSelector("maxZapBps()", IVault.maxZapBps.selector);
        _assertPairTokenSelector("maxZapTickMove()", IVault.maxZapTickMove.selector);
        _assertPairTokenSelector("deposit(address,address,uint256,uint256)", IStandardizedYield.deposit.selector);
        _assertPairTokenSelector("redeem(address,uint256,address,uint256,bool)", IStandardizedYield.redeem.selector);
        _assertPairTokenSelector("rewardIndexesCurrent()", IStandardizedYield.rewardIndexesCurrent.selector);
        _assertPairTokenSelector("claimRewards(address)", IStandardizedYield.claimRewards.selector);
        _assertPairTokenSelector("previewDeposit(address,uint256)", IStandardizedYield.previewDeposit.selector);
        _assertPairTokenSelector("previewRedeem(address,uint256)", IStandardizedYield.previewRedeem.selector);
        _assertPairTokenSelector("getTokensIn()", IStandardizedYield.getTokensIn.selector);
        _assertPairTokenSelector("getTokensOut()", IStandardizedYield.getTokensOut.selector);
        _assertPairTokenSelector("yieldToken()", IStandardizedYield.yieldToken.selector);
        _assertPairTokenSelector("assetInfo()", IStandardizedYield.assetInfo.selector);
        _assertPairTokenSelector("exchangeRate()", IStandardizedYield.exchangeRate.selector);
        _assertPairTokenSelector("isValidTokenIn(address)", IStandardizedYield.isValidTokenIn.selector);
        _assertPairTokenSelector("isValidTokenOut(address)", IStandardizedYield.isValidTokenOut.selector);
        _assertPairTokenSelector("getRewardTokens()", IStandardizedYield.getRewardTokens.selector);
        _assertPairTokenSelector("accruedRewards(address)", IStandardizedYield.accruedRewards.selector);
        _assertPairTokenSelector("rewardIndexesStored()", IStandardizedYield.rewardIndexesStored.selector);
        _assertPairTokenSelector("unlockCallback(bytes)", IUnlockCallback.unlockCallback.selector);
        _assertPairTokenSelector("ReentrantOperation()", IVault.ReentrantOperation.selector);
        _assertPairTokenSelector("ManagerAlreadyUnlocked()", IVault.ManagerAlreadyUnlocked.selector);
        _assertPairTokenSelector("EconomicStateChanged()", IVault.EconomicStateChanged.selector);
        _assertPairTokenSelector("InvalidAccountingState()", IVault.InvalidAccountingState.selector);
        _assertPairTokenSelector("ZeroPayout()", IVault.ZeroPayout.selector);
        _assertPairTokenSelector("QuoteWorkExceeded(uint256,uint256)", IVault.QuoteWorkExceeded.selector);
        _assertPairTokenSelector("QuoteTickCrossingsExceeded(uint256,uint256)", IVault.QuoteTickCrossingsExceeded.selector);
        _assertPairTokenSelector("QuoteBitmapWordsExceeded(uint256,uint256)", IVault.QuoteBitmapWordsExceeded.selector);
        _assertPairTokenSelector("IssuanceDisabled()", IVault.IssuanceDisabled.selector);
        _assertPairTokenSelector("InvalidComponent()", IPairTokenPackage.InvalidComponent.selector);
        _assertPairTokenSelector("InvalidPoolKey()", IPairTokenPackage.InvalidPoolKey.selector);
        _assertPairTokenSelector("InvalidRateAsset()", IPairTokenPackage.InvalidRateAsset.selector);
        _assertPairTokenSelector("InvalidZapLimits()", IPairTokenPackage.InvalidZapLimits.selector);
        _assertPairTokenSelector("InvalidWrappedNative()", IPairTokenPackage.InvalidWrappedNative.selector);
        _assertPairTokenSelector("NotCalledByRegistry()", IPairTokenPackage.NotCalledByRegistry.selector);
        _assertPairTokenSelector("InvalidInitializationContext()", IPairTokenPackage.InvalidInitializationContext.selector);
        _assertPairTokenSelector("AlreadyInitialized()", IPairTokenPackage.AlreadyInitialized.selector);
        _assertPairTokenSelector("DirectCallNotAllowed()", PTMath.DirectCallNotAllowed.selector);
        _assertPairTokenSelector("InvalidPrice()", PTMath.InvalidPrice.selector);
        _assertPairTokenSelector("InvalidAccountingState()", PTMath.InvalidAccountingState.selector);
        _assertPairTokenSelector("ZeroShares()", PTMath.ZeroShares.selector);
        _assertPairTokenSelector("InvalidAllocation()", PTMath.InvalidAllocation.selector);
        _assertPairTokenSelector("LiquidityOverflow()", PTMath.LiquidityOverflow.selector);
        _assertPairTokenSelector("ArithmeticOverflow()", PTMath.ArithmeticOverflow.selector);
        _assertPairTokenSelector("DirectCallNotAllowed()", PTProjection.DirectCallNotAllowed.selector);
        _assertPairTokenSelector("DirectCallNotAllowed()", PTPlanner.DirectCallNotAllowed.selector);
        _assertPairTokenSelector("ZapSizeExceeded(uint256,uint256)", PTPlanner.ZapSizeExceeded.selector);
        _assertPairTokenSelector("ZapTickMoveExceeded(uint256,uint256)", PTPlanner.ZapTickMoveExceeded.selector);
        _assertPairTokenSelector("IncompleteExitSale(uint256,uint256)", PTPlanner.IncompleteExitSale.selector);
        _assertPairTokenSelector("InvalidCallback()", PTExecution.InvalidCallback.selector);
        _assertPairTokenSelector("InvalidNativeValue(uint256,uint256)", PTExecution.InvalidNativeValue.selector);
        _assertPairTokenSelector("NativeTransferFailed()", PTExecution.NativeTransferFailed.selector);
        _assertPairTokenSelector("SettlementMismatch()", PTExecution.SettlementMismatch.selector);
        _assertPairTokenSelector("RuntimeArtifactMismatch(address)", PTComponents.RuntimeArtifactMismatch.selector);
        _assertPairTokenSelector("PackageBindingMismatch(address)", PTComponents.PackageBindingMismatch.selector);
        _assertPairTokenSelector("bindingHash()", IPairTokenPackage.bindingHash.selector);
        _assertPairTokenSelector("vaultDeclaration()", IStandardVaultPkg.vaultDeclaration.selector);
        _assertPairTokenSelector("deployVault(((address,address,uint24,int24,address),address,string,string,uint16,int24))", IPairTokenPackage.deployVault.selector);
        require(keccak256(bytes("PairDeposited(address,address,uint256,uint256,uint256,uint256,uint256)")) == IVault.PairDeposited.selector, "PairToken event mismatch");
        _logTopic0("PairDeposited(address,address,uint256,uint256,uint256,uint256,uint256)");
        require(keccak256(bytes("PairRedeemed(address,address,uint256,uint128,uint256,uint256,uint256,uint256)")) == IVault.PairRedeemed.selector, "PairToken event mismatch");
        _logTopic0("PairRedeemed(address,address,uint256,uint128,uint256,uint256,uint256,uint256)");
        require(keccak256(bytes("WithdrawalSale(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)")) == IVault.WithdrawalSale.selector, "PairToken event mismatch");
        _logTopic0("WithdrawalSale(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)");
        require(keccak256(bytes("Donated(address,address,uint256)")) == IVault.Donated.selector, "PairToken event mismatch");
        _logTopic0("Donated(address,address,uint256)");
        require(keccak256(bytes("Compounded(uint256,uint256,uint256,uint256,uint128)")) == IVault.Compounded.selector, "PairToken event mismatch");
        _logTopic0("Compounded(uint256,uint256,uint256,uint256,uint128)");
        require(keccak256(bytes("ZapCredit(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)")) == IVault.ZapCredit.selector, "PairToken event mismatch");
        _logTopic0("ZapCredit(address,address,address,uint256,uint256,uint256,uint256,uint256,uint256)");
        require(keccak256(bytes("WithdrawalMaintenanceSelected(uint8,uint8)")) == IVault.WithdrawalMaintenanceSelected.selector, "PairToken event mismatch");
        _logTopic0("WithdrawalMaintenanceSelected(uint8,uint8)");
        console2.log("PairToken family interface:");
        console2.logBytes4(type(IVault).interfaceId);
        console2.log("PairToken package interface:");
        console2.logBytes4(type(IPairTokenPackage).interfaceId);
        console2.log("PairToken SY interface:");
        console2.logBytes4(type(IStandardizedYield).interfaceId);
        bytes32 slot_ = bytes32(uint256(keccak256(abi.encode("indexedex.vaults.standard.exchange.uniswap.v4.pairToken"))) - 1);
        require(slot_ == PairTokenRepo.DEFAULT_SLOT, "PairToken slot mismatch");
        console2.log("PairToken Repo slot:");
        console2.logBytes32(slot_);
    }

    function _assertPairTokenSelector(string memory signature_, bytes4 typed_) internal pure {
        require(bytes4(keccak256(bytes(signature_))) == typed_, "PairToken typed selector mismatch");
        _logSelector(signature_, 0);
    }

    /// @dev Library struct arguments use Solidity's qualified library signatures.
    /// Verify the compiler's actual identifiers, including both witness overloads.
    function _pairTokenLinkedValues() internal view {
        string memory prefix_ = "UniswapV4PairTokenStandardExchangeVault";
        string[7] memory files_ = ["Math", "Projection", "Projection", "Planner", "Execution", "Execution", "ComponentBindings"];
        string[7] memory names_ = ["Math", "Projection", "SwapProjection", "Planner", "Execution", "ExecutionPreparation", "ComponentBindings"];
        for (uint256 i_; i_ < files_.length; ++i_) {
            string memory name_ = i_ == 6 ? string.concat("I", prefix_, names_[i_]) : string.concat(prefix_, names_[i_]);
            string memory json_ = vm.readFile(string.concat("out/", prefix_, files_[i_], ".sol/", name_, ".json"));
            string[] memory signatures_ = vm.parseJsonKeys(json_, ".methodIdentifiers");
            console2.log(name_);
            for (uint256 j_; j_ < signatures_.length; ++j_) {
                string memory value_ = vm.parseJsonString(json_, string.concat('.methodIdentifiers["', signatures_[j_], '"]'));
                _assertPairTokenSelector(signatures_[j_], bytes4(vm.parseBytes(string.concat("0x", value_))));
            }
        }
    }

}
