// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IVaultAdmin} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultAdmin.sol";
import {
    IBalancerContractRegistry,
    ContractType
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/standalone-utils/IBalancerContractRegistry.sol";
import {
    HooksConfig,
    LiquidityManagement,
    PoolRoleAccounts,
    SwapKind,
    TokenConfig,
    PoolSwapParams,
    AddLiquidityKind,
    RemoveLiquidityKind
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {CastingHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/CastingHelpers.sol";
import {ArrayHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/test/ArrayHelpers.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

import {BaseVaultTest} from "@crane/contracts/external/balancer/v3/vault/test/foundry/utils/BaseVaultTest.sol";
import {PoolFactoryMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/PoolFactoryMock.sol";
import {PoolMock} from "@crane/contracts/external/balancer/v3/vault/contracts/test/PoolMock.sol";

import {MevCaptureHook, IMevCaptureHook} from
    "@crane/contracts/protocols/dexes/balancer/v3/hooks/MevCaptureHook.sol";

/**
 * @title MockBalancerContractRegistry
 * @notice Mock registry for testing MevCaptureHook.
 */
contract MockBalancerContractRegistry is IBalancerContractRegistry {
    mapping(address => bool) private _trustedRouters;

    function setTrustedRouter(address router, bool trusted) external {
        _trustedRouters[router] = trusted;
    }

    function isTrustedRouter(address router) external view override returns (bool) {
        return _trustedRouters[router];
    }

    // Required interface implementations (minimal stubs)
    function registerBalancerContract(ContractType, string memory, address) external pure override {
        revert("Not implemented");
    }

    function deregisterBalancerContract(string memory) external pure override {
        revert("Not implemented");
    }

    function deprecateBalancerContract(address) external pure override {
        revert("Not implemented");
    }

    function addOrUpdateBalancerContractAlias(string memory, address) external pure override {
        revert("Not implemented");
    }

    function isActiveBalancerContract(ContractType, address) external pure override returns (bool) {
        return false;
    }

    function getBalancerContract(ContractType, string memory) external pure override returns (address, bool) {
        return (address(0), false);
    }

    function getBalancerContractInfo(address) external pure override returns (ContractInfo memory) {
        return ContractInfo(ContractType.OTHER, false, false);
    }
}

/**
 * @title MevCaptureHookTest
 * @notice Tests for the MevCaptureHook contract.
 * @dev Verifies MEV tax mechanism based on priority gas price.
 *
 * Key behaviors tested:
 * - Higher priority gas = higher swap fees
 * - Exempt senders bypass MEV tax
 * - Proportional liquidity ops allowed regardless of gas price
 */
contract MevCaptureHookTest is BaseVaultTest {
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    uint256 internal daiIdx;
    uint256 internal usdcIdx;

    address internal mevHook;
    MockBalancerContractRegistry internal mockRegistry;
    PoolFactoryMock internal poolFactoryMock;

    uint256 internal constant SWAP_FEE_PERCENTAGE = 1e16; // 1%
    uint256 internal constant DEFAULT_MEV_MULTIPLIER = 1e18; // 1x
    uint256 internal constant DEFAULT_MEV_THRESHOLD = 1 gwei;

    function setUp() public override {
        // Deploy mock registry before vault setup
        mockRegistry = new MockBalancerContractRegistry();
        // Trust the router
        mockRegistry.setTrustedRouter(address(0), false); // Ensure address(0) is not trusted

        super.setUp();

        (daiIdx, usdcIdx) = getSortedIndexes(address(dai), address(usdc));
        poolFactoryMock = PoolFactoryMock(address(vault.getPoolFactoryMock()));

        // Trust the router after it's deployed
        mockRegistry.setTrustedRouter(address(router), true);

        // Set static swap fee
        authorizer.grantRole(
            vault.getActionId(IVaultAdmin.setStaticSwapFeePercentage.selector),
            admin
        );
        vm.prank(admin);
        vault.setStaticSwapFeePercentage(pool, SWAP_FEE_PERCENTAGE);
    }

    function createHook() internal override returns (address) {
        vm.prank(lp);
        mevHook = address(
            new MevCaptureHook(
                IVault(address(vault)),
                IBalancerContractRegistry(address(mockRegistry)),
                DEFAULT_MEV_MULTIPLIER,
                DEFAULT_MEV_THRESHOLD
            )
        );
        vm.label(mevHook, "MEV Capture Hook");
        return mevHook;
    }

    function _createPool(
        address[] memory tokens,
        string memory label
    ) internal override returns (address newPool, bytes memory poolArgs) {
        string memory name = "MEV Pool";
        string memory symbol = "MEV-POOL";

        newPool = address(deployPoolMock(IVault(address(vault)), name, symbol));
        vm.label(newPool, label);

        PoolRoleAccounts memory roleAccounts;
        roleAccounts.poolCreator = lp;

        LiquidityManagement memory liquidityManagement;

        PoolFactoryMock(poolFactory).registerPool(
            newPool,
            vault.buildTokenConfig(tokens.asIERC20()),
            roleAccounts,
            poolHooksContract,
            liquidityManagement
        );

        poolArgs = abi.encode(vault, name, symbol);
    }

    /* ========================================================================== */
    /*                             REGISTRATION TESTS                             */
    /* ========================================================================== */

    function testSuccessfulRegistry() public view {
        HooksConfig memory hooksConfig = vault.getHooksConfig(pool);

        assertEq(hooksConfig.hooksContract, poolHooksContract, "hooksContract is wrong");
        assertTrue(
            hooksConfig.shouldCallComputeDynamicSwapFee,
            "shouldCallComputeDynamicSwapFee is false"
        );
        assertTrue(
            hooksConfig.shouldCallBeforeAddLiquidity,
            "shouldCallBeforeAddLiquidity is false"
        );
        assertTrue(
            hooksConfig.shouldCallBeforeRemoveLiquidity,
            "shouldCallBeforeRemoveLiquidity is false"
        );
    }

    function testDefaultParameters() public view {
        assertTrue(
            MevCaptureHook(mevHook).isMevTaxEnabled(),
            "MEV tax should be enabled by default"
        );
        assertEq(
            MevCaptureHook(mevHook).getDefaultMevTaxMultiplier(),
            DEFAULT_MEV_MULTIPLIER,
            "Default multiplier is wrong"
        );
        assertEq(
            MevCaptureHook(mevHook).getDefaultMevTaxThreshold(),
            DEFAULT_MEV_THRESHOLD,
            "Default threshold is wrong"
        );
    }

    /* ========================================================================== */
    /*                            MEV TAX TESTS                                   */
    /* ========================================================================== */

    function testLowPriorityGasNoTax() public {
        // Set low gas price (at base fee)
        vm.txGasPrice(block.basefee);

        BaseVaultTest.Balances memory balances = getBalances(lp);
        uint256[] memory balancesScaled18 = balances.poolTokens;

        vm.prank(address(vault));
        (, uint256 feePercentage) = MevCaptureHook(mevHook)
            .onComputeDynamicSwapFeePercentage(
                PoolSwapParams({
                    kind: SwapKind.EXACT_IN,
                    amountGivenScaled18: poolInitAmount / 10,
                    balancesScaled18: balancesScaled18,
                    indexIn: daiIdx,
                    indexOut: usdcIdx,
                    router: address(router),
                    userData: bytes("")
                }),
                pool,
                SWAP_FEE_PERCENTAGE
            );

        // With no priority gas, fee should equal static fee
        assertEq(feePercentage, SWAP_FEE_PERCENTAGE, "Fee should be static with no priority gas");
    }

    function testHighPriorityGasIncreasesFee() public {
        // Set high gas price (well above base fee)
        uint256 highPriority = 100 gwei;
        vm.txGasPrice(block.basefee + highPriority);

        BaseVaultTest.Balances memory balances = getBalances(lp);
        uint256[] memory balancesScaled18 = balances.poolTokens;

        vm.prank(address(vault));
        (, uint256 feePercentage) = MevCaptureHook(mevHook)
            .onComputeDynamicSwapFeePercentage(
                PoolSwapParams({
                    kind: SwapKind.EXACT_IN,
                    amountGivenScaled18: poolInitAmount / 10,
                    balancesScaled18: balancesScaled18,
                    indexIn: daiIdx,
                    indexOut: usdcIdx,
                    router: address(router),
                    userData: bytes("")
                }),
                pool,
                SWAP_FEE_PERCENTAGE
            );

        // With high priority gas, fee should be higher
        assertTrue(
            feePercentage > SWAP_FEE_PERCENTAGE,
            "Fee should be higher with high priority gas"
        );
    }

    function testMevTaxDisabled() public {
        // Disable MEV tax
        authorizer.grantRole(
            MevCaptureHook(mevHook).getActionId(IMevCaptureHook.disableMevTax.selector),
            admin
        );
        vm.prank(admin);
        MevCaptureHook(mevHook).disableMevTax();

        // Set high gas price
        vm.txGasPrice(block.basefee + 100 gwei);

        BaseVaultTest.Balances memory balances = getBalances(lp);
        uint256[] memory balancesScaled18 = balances.poolTokens;

        vm.prank(address(vault));
        (, uint256 feePercentage) = MevCaptureHook(mevHook)
            .onComputeDynamicSwapFeePercentage(
                PoolSwapParams({
                    kind: SwapKind.EXACT_IN,
                    amountGivenScaled18: poolInitAmount / 10,
                    balancesScaled18: balancesScaled18,
                    indexIn: daiIdx,
                    indexOut: usdcIdx,
                    router: address(router),
                    userData: bytes("")
                }),
                pool,
                SWAP_FEE_PERCENTAGE
            );

        // With MEV tax disabled, fee should equal static fee
        assertEq(feePercentage, SWAP_FEE_PERCENTAGE, "Fee should be static when MEV tax disabled");
    }

    /* ========================================================================== */
    /*                        LIQUIDITY OPERATION TESTS                           */
    /* ========================================================================== */

    function testProportionalAddLiquidityAlwaysAllowed() public {
        // Even with high priority gas, proportional add is allowed
        vm.txGasPrice(block.basefee + 100 gwei);

        uint256[] memory amounts = [poolInitAmount / 10, poolInitAmount / 10].toMemoryArray();

        vm.prank(lp);
        router.addLiquidityProportional(pool, amounts, 0, false, bytes(""));
    }

    function testProportionalRemoveLiquidityAlwaysAllowed() public {
        // Even with high priority gas, proportional remove is allowed
        vm.txGasPrice(block.basefee + 100 gwei);

        uint256 bptAmount = poolInitAmount / 10;
        uint256[] memory minAmounts = [uint256(0), uint256(0)].toMemoryArray();

        vm.prank(lp);
        router.removeLiquidityProportional(pool, bptAmount, minAmounts, false, bytes(""));
    }

    /* ========================================================================== */
    /*                            EXEMPT SENDER TESTS                             */
    /* ========================================================================== */

    function testAddExemptSender() public {
        address exemptAddress = address(0x1234);

        authorizer.grantRole(
            MevCaptureHook(mevHook).getActionId(IMevCaptureHook.addMevTaxExemptSenders.selector),
            admin
        );

        address[] memory senders = new address[](1);
        senders[0] = exemptAddress;

        vm.prank(admin);
        MevCaptureHook(mevHook).addMevTaxExemptSenders(senders);

        assertTrue(
            MevCaptureHook(mevHook).isMevTaxExemptSender(exemptAddress),
            "Sender should be exempt"
        );
    }

    function testRemoveExemptSender() public {
        address exemptAddress = address(0x1234);

        authorizer.grantRole(
            MevCaptureHook(mevHook).getActionId(IMevCaptureHook.addMevTaxExemptSenders.selector),
            admin
        );
        authorizer.grantRole(
            MevCaptureHook(mevHook).getActionId(IMevCaptureHook.removeMevTaxExemptSenders.selector),
            admin
        );

        address[] memory senders = new address[](1);
        senders[0] = exemptAddress;

        vm.prank(admin);
        MevCaptureHook(mevHook).addMevTaxExemptSenders(senders);

        vm.prank(admin);
        MevCaptureHook(mevHook).removeMevTaxExemptSenders(senders);

        assertFalse(
            MevCaptureHook(mevHook).isMevTaxExemptSender(exemptAddress),
            "Sender should not be exempt"
        );
    }

    /* ========================================================================== */
    /*                            CONFIGURATION TESTS                             */
    /* ========================================================================== */

    function testSetPoolMevTaxMultiplier() public {
        uint256 newMultiplier = 2e18; // 2x

        authorizer.grantRole(
            MevCaptureHook(mevHook).getActionId(IMevCaptureHook.setPoolMevTaxMultiplier.selector),
            admin
        );

        vm.prank(admin);
        MevCaptureHook(mevHook).setPoolMevTaxMultiplier(pool, newMultiplier);

        assertEq(
            MevCaptureHook(mevHook).getPoolMevTaxMultiplier(pool),
            newMultiplier,
            "Multiplier not updated"
        );
    }

    function testSetPoolMevTaxThreshold() public {
        uint256 newThreshold = 5 gwei;

        authorizer.grantRole(
            MevCaptureHook(mevHook).getActionId(IMevCaptureHook.setPoolMevTaxThreshold.selector),
            admin
        );

        vm.prank(admin);
        MevCaptureHook(mevHook).setPoolMevTaxThreshold(pool, newThreshold);

        assertEq(
            MevCaptureHook(mevHook).getPoolMevTaxThreshold(pool),
            newThreshold,
            "Threshold not updated"
        );
    }
}
