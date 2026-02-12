// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                               OpenZeppelin                                 */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                  Balancer                                  */
/* -------------------------------------------------------------------------- */

import {IAuthorizer} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IVaultMain} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultMain.sol";
import {IVaultExtension} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultExtension.sol";
import {IVaultAdmin} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultAdmin.sol";
import "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {
    DiamondPackageCallBackFactory,
    IDiamondPackageCallBackFactoryInit
} from "@crane/contracts/factories/diamondPkg/DiamondPackageCallBackFactory.sol";
import {ERC165Facet} from "@crane/contracts/introspection/ERC165/ERC165Facet.sol";
import {DiamondLoupeFacet} from "@crane/contracts/introspection/ERC2535/DiamondLoupeFacet.sol";
import {ERC8109IntrospectionFacet} from "@crane/contracts/introspection/ERC8109/ERC8109IntrospectionFacet.sol";
import {PostDeployAccountHookFacet} from "@crane/contracts/factories/diamondPkg/PostDeployAccountHookFacet.sol";

/* -------------------------------------------------------------------------- */
/*                         Balancer V3 Vault DFPkg                            */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3VaultDFPkg,
    IBalancerV3VaultDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDFPkg.sol";
import {BalancerV3VaultStorageRepo} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultStorageRepo.sol";

// Facets
import {VaultTransientFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultTransientFacet.sol";
import {VaultSwapFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultSwapFacet.sol";
import {VaultLiquidityFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultLiquidityFacet.sol";
import {VaultBufferFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultBufferFacet.sol";
import {VaultPoolTokenFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol";
import {VaultQueryFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol";
import {VaultRegistrationFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultRegistrationFacet.sol";
import {VaultAdminFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultAdminFacet.sol";
import {VaultRecoveryFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultRecoveryFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                 Mock Contracts                             */
/* -------------------------------------------------------------------------- */

/// @notice Mock Authorizer for testing
contract MockAuthorizer is IAuthorizer {
    function canPerform(bytes32, address, address) external pure returns (bool) {
        return true;
    }
}

/// @notice Mock Protocol Fee Controller for testing
contract MockProtocolFeeController {
    function getGlobalProtocolSwapFeePercentage() external pure returns (uint256) {
        return 0;
    }

    function getGlobalProtocolYieldFeePercentage() external pure returns (uint256) {
        return 0;
    }

    function getPoolProtocolSwapFeeInfo(address) external pure returns (uint256, bool) {
        return (0, false);
    }

    function getPoolProtocolYieldFeeInfo(address) external pure returns (uint256, bool) {
        return (0, false);
    }
}

/**
 * @title BalancerV3VaultDFPkgTest
 * @notice Tests for the Balancer V3 Vault Diamond Factory Package.
 */
contract BalancerV3VaultDFPkgTest is Test {
    // Factory infrastructure
    DiamondPackageCallBackFactory public factory;
    ERC165Facet public erc165Facet;
    DiamondLoupeFacet public diamondLoupeFacet;
    ERC8109IntrospectionFacet public erc8109Facet;
    PostDeployAccountHookFacet public postDeployHookFacet;

    // Vault package
    BalancerV3VaultDFPkg public vaultPkg;

    // Mock contracts
    MockAuthorizer public authorizer;
    MockProtocolFeeController public protocolFeeController;

    // Vault facet instances
    VaultTransientFacet public transientFacet;
    VaultSwapFacet public swapFacet;
    VaultLiquidityFacet public liquidityFacet;
    VaultBufferFacet public bufferFacet;
    VaultPoolTokenFacet public poolTokenFacet;
    VaultQueryFacet public queryFacet;
    VaultRegistrationFacet public registrationFacet;
    VaultAdminFacet public adminFacet;
    VaultRecoveryFacet public recoveryFacet;

    // Test addresses
    address public admin;
    address public user;

    // Test constants
    uint256 constant MINIMUM_TRADE_AMOUNT = 1e6;
    uint256 constant MINIMUM_WRAP_AMOUNT = 1e6;
    uint32 constant PAUSE_WINDOW_DURATION = 365 days;
    uint32 constant BUFFER_PERIOD_DURATION = 90 days;

    function setUp() public {
        admin = makeAddr("admin");
        user = makeAddr("user");

        // Deploy mock contracts
        authorizer = new MockAuthorizer();
        protocolFeeController = new MockProtocolFeeController();

        // Deploy factory infrastructure facets
        erc165Facet = new ERC165Facet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        erc8109Facet = new ERC8109IntrospectionFacet();
        postDeployHookFacet = new PostDeployAccountHookFacet();

        // Deploy the DiamondPackageCallBackFactory
        factory = new DiamondPackageCallBackFactory(
            IDiamondPackageCallBackFactoryInit.InitArgs({
                erc165Facet: IFacet(address(erc165Facet)),
                diamondLoupeFacet: IFacet(address(diamondLoupeFacet)),
                erc8109IntrospectionFacet: IFacet(address(erc8109Facet)),
                postDeployHookFacet: IFacet(address(postDeployHookFacet))
            })
        );

        // Deploy vault facets
        transientFacet = new VaultTransientFacet();
        swapFacet = new VaultSwapFacet();
        liquidityFacet = new VaultLiquidityFacet();
        bufferFacet = new VaultBufferFacet();
        poolTokenFacet = new VaultPoolTokenFacet();
        queryFacet = new VaultQueryFacet();
        registrationFacet = new VaultRegistrationFacet();
        adminFacet = new VaultAdminFacet();
        recoveryFacet = new VaultRecoveryFacet();

        // Deploy the Vault DFPkg
        // Note: DiamondLoupe is added by the factory, not the package
        vaultPkg = new BalancerV3VaultDFPkg(
            IBalancerV3VaultDFPkg.PkgInit({
                vaultTransientFacet: IFacet(address(transientFacet)),
                vaultSwapFacet: IFacet(address(swapFacet)),
                vaultLiquidityFacet: IFacet(address(liquidityFacet)),
                vaultBufferFacet: IFacet(address(bufferFacet)),
                vaultPoolTokenFacet: IFacet(address(poolTokenFacet)),
                vaultQueryFacet: IFacet(address(queryFacet)),
                vaultRegistrationFacet: IFacet(address(registrationFacet)),
                vaultAdminFacet: IFacet(address(adminFacet)),
                vaultRecoveryFacet: IFacet(address(recoveryFacet)),
                diamondFactory: IDiamondPackageCallBackFactory(address(factory))
            })
        );

        // Label addresses for debugging
        vm.label(address(factory), "DiamondPackageCallBackFactory");
        vm.label(address(vaultPkg), "BalancerV3VaultDFPkg");
        vm.label(address(authorizer), "MockAuthorizer");
        vm.label(address(protocolFeeController), "MockProtocolFeeController");
        vm.label(address(transientFacet), "VaultTransientFacet");
        vm.label(address(swapFacet), "VaultSwapFacet");
        vm.label(address(liquidityFacet), "VaultLiquidityFacet");
        vm.label(address(bufferFacet), "VaultBufferFacet");
        vm.label(address(poolTokenFacet), "VaultPoolTokenFacet");
        vm.label(address(queryFacet), "VaultQueryFacet");
        vm.label(address(registrationFacet), "VaultRegistrationFacet");
        vm.label(address(adminFacet), "VaultAdminFacet");
        vm.label(address(recoveryFacet), "VaultRecoveryFacet");
    }

    /* ========================================================================== */
    /*                          Package Deployment Tests                          */
    /* ========================================================================== */

    function test_package_deploySuccessfully() public view {
        assertTrue(address(vaultPkg) != address(0), "Package should deploy");
        assertTrue(address(vaultPkg).code.length > 0, "Package should have code");
    }

    function test_package_returnsCorrectName() public view {
        assertEq(vaultPkg.packageName(), "BalancerV3VaultDFPkg", "Package name mismatch");
    }

    function test_package_returnsCorrectInterfaces() public view {
        bytes4[] memory interfaces = vaultPkg.facetInterfaces();
        assertEq(interfaces.length, 4, "Should have 4 interface IDs");
        assertEq(interfaces[0], type(IVaultMain).interfaceId, "IVaultMain interface mismatch");
        assertEq(interfaces[1], type(IVaultExtension).interfaceId, "IVaultExtension interface mismatch");
        assertEq(interfaces[2], type(IVaultAdmin).interfaceId, "IVaultAdmin interface mismatch");
        assertEq(interfaces[3], type(IDiamondLoupe).interfaceId, "IDiamondLoupe interface mismatch");
    }

    function test_package_returnsAllFacetAddresses() public view {
        address[] memory facets = vaultPkg.facetAddresses();
        // 9 package facets (DiamondLoupe is added by the factory, not the package)
        assertEq(facets.length, 9, "Should have 9 facet addresses");
        assertEq(facets[0], address(transientFacet), "TransientFacet address mismatch");
        assertEq(facets[1], address(swapFacet), "SwapFacet address mismatch");
        assertEq(facets[2], address(liquidityFacet), "LiquidityFacet address mismatch");
        assertEq(facets[3], address(bufferFacet), "BufferFacet address mismatch");
        assertEq(facets[4], address(poolTokenFacet), "PoolTokenFacet address mismatch");
        assertEq(facets[5], address(queryFacet), "QueryFacet address mismatch");
        assertEq(facets[6], address(registrationFacet), "RegistrationFacet address mismatch");
        assertEq(facets[7], address(adminFacet), "AdminFacet address mismatch");
        assertEq(facets[8], address(recoveryFacet), "RecoveryFacet address mismatch");
    }

    function test_package_returnsFacetCuts() public view {
        IDiamond.FacetCut[] memory cuts = vaultPkg.facetCuts();
        // 9 package facets (DiamondLoupe is added by the factory, not the package)
        assertEq(cuts.length, 9, "Should have 9 facet cuts");
        for (uint256 i = 0; i < cuts.length; i++) {
            assertEq(uint256(cuts[i].action), uint256(IDiamond.FacetCutAction.Add), "All cuts should be Add");
            assertTrue(cuts[i].functionSelectors.length > 0, "Each facet should have selectors");
        }
    }

    /* ========================================================================== */
    /*                          Vault Deployment Tests                           */
    /* ========================================================================== */

    function test_deployVault_createsVaultDiamond() public {
        address vault = vaultPkg.deployVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(address(authorizer)),
            IProtocolFeeController(address(protocolFeeController))
        );

        assertTrue(vault != address(0), "Vault should be deployed");
        assertTrue(vault.code.length > 0, "Vault should have code");
    }

    function test_deployVault_isDeterministic() public {
        // Calculate expected address before deployment
        bytes memory pkgArgs = abi.encode(
            IBalancerV3VaultDFPkg.PkgArgs({
                minimumTradeAmount: MINIMUM_TRADE_AMOUNT,
                minimumWrapAmount: MINIMUM_WRAP_AMOUNT,
                pauseWindowDuration: PAUSE_WINDOW_DURATION,
                bufferPeriodDuration: BUFFER_PERIOD_DURATION,
                authorizer: IAuthorizer(address(authorizer)),
                protocolFeeController: IProtocolFeeController(address(protocolFeeController))
            })
        );
        address expectedVault = factory.calcAddress(vaultPkg, pkgArgs);

        // Deploy and verify address matches
        address vault = vaultPkg.deployVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(address(authorizer)),
            IProtocolFeeController(address(protocolFeeController))
        );

        assertEq(vault, expectedVault, "Vault address should be deterministic");
    }

    function test_deployVault_returnsExistingIfRedeployed() public {
        address vault1 = vaultPkg.deployVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(address(authorizer)),
            IProtocolFeeController(address(protocolFeeController))
        );

        address vault2 = vaultPkg.deployVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(address(authorizer)),
            IProtocolFeeController(address(protocolFeeController))
        );

        assertEq(vault1, vault2, "Should return same vault on redeploy");
    }

    function test_deployVault_differentParamsGetDifferentAddresses() public {
        address vault1 = vaultPkg.deployVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(address(authorizer)),
            IProtocolFeeController(address(protocolFeeController))
        );

        address vault2 = vaultPkg.deployVault(
            MINIMUM_TRADE_AMOUNT * 2,  // Different param
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(address(authorizer)),
            IProtocolFeeController(address(protocolFeeController))
        );

        assertTrue(vault1 != vault2, "Different params should produce different addresses");
    }

    /* ========================================================================== */
    /*                          Facet Size Tests                                  */
    /* ========================================================================== */

    function test_facetSizes_allUnder24KB() public view {
        // Verify each facet is under the 24KB deployment limit
        assertTrue(address(transientFacet).code.length < 24576, "TransientFacet too large");
        assertTrue(address(swapFacet).code.length < 24576, "SwapFacet too large");
        assertTrue(address(liquidityFacet).code.length < 24576, "LiquidityFacet too large");
        assertTrue(address(bufferFacet).code.length < 24576, "BufferFacet too large");
        assertTrue(address(poolTokenFacet).code.length < 24576, "PoolTokenFacet too large");
        assertTrue(address(queryFacet).code.length < 24576, "QueryFacet too large");
        assertTrue(address(registrationFacet).code.length < 24576, "RegistrationFacet too large");
        assertTrue(address(adminFacet).code.length < 24576, "AdminFacet too large");
        assertTrue(address(recoveryFacet).code.length < 24576, "RecoveryFacet too large");
    }

    /* ========================================================================== */
    /*                          IFacet Compliance Tests                           */
    /* ========================================================================== */

    function test_facets_implementIFacet() public view {
        // Test each facet implements IFacet interface correctly
        _verifyFacetMetadata(IFacet(address(transientFacet)), "VaultTransientFacet");
        _verifyFacetMetadata(IFacet(address(swapFacet)), "VaultSwapFacet");
        _verifyFacetMetadata(IFacet(address(liquidityFacet)), "VaultLiquidityFacet");
        _verifyFacetMetadata(IFacet(address(bufferFacet)), "VaultBufferFacet");
        _verifyFacetMetadata(IFacet(address(poolTokenFacet)), "VaultPoolTokenFacet");
        _verifyFacetMetadata(IFacet(address(queryFacet)), "VaultQueryFacet");
        _verifyFacetMetadata(IFacet(address(registrationFacet)), "VaultRegistrationFacet");
        _verifyFacetMetadata(IFacet(address(adminFacet)), "VaultAdminFacet");
        _verifyFacetMetadata(IFacet(address(recoveryFacet)), "VaultRecoveryFacet");
    }

    function test_facets_haveNonEmptySelectors() public view {
        assertTrue(transientFacet.facetFuncs().length > 0, "TransientFacet should have selectors");
        assertTrue(swapFacet.facetFuncs().length > 0, "SwapFacet should have selectors");
        assertTrue(liquidityFacet.facetFuncs().length > 0, "LiquidityFacet should have selectors");
        assertTrue(bufferFacet.facetFuncs().length > 0, "BufferFacet should have selectors");
        assertTrue(poolTokenFacet.facetFuncs().length > 0, "PoolTokenFacet should have selectors");
        assertTrue(queryFacet.facetFuncs().length > 0, "QueryFacet should have selectors");
        assertTrue(registrationFacet.facetFuncs().length > 0, "RegistrationFacet should have selectors");
        assertTrue(adminFacet.facetFuncs().length > 0, "AdminFacet should have selectors");
        assertTrue(recoveryFacet.facetFuncs().length > 0, "RecoveryFacet should have selectors");
    }

    /* ========================================================================== */
    /*                    Interface Selector Coverage Tests                       */
    /* ========================================================================== */

    function test_interface_IVaultMain_selectorsResolveTofacets() public {
        address vault = _deployVault();

        // IVaultMain selectors
        _assertSelectorResolvesOnVault(vault, IVaultMain.unlock.selector, "unlock");
        _assertSelectorResolvesOnVault(vault, IVaultMain.settle.selector, "settle");
        _assertSelectorResolvesOnVault(vault, IVaultMain.sendTo.selector, "sendTo");
        _assertSelectorResolvesOnVault(vault, IVaultMain.swap.selector, "swap");
        _assertSelectorResolvesOnVault(vault, IVaultMain.addLiquidity.selector, "addLiquidity");
        _assertSelectorResolvesOnVault(vault, IVaultMain.removeLiquidity.selector, "removeLiquidity");
        _assertSelectorResolvesOnVault(vault, IVaultMain.getPoolTokenCountAndIndexOfToken.selector, "getPoolTokenCountAndIndexOfToken");
        _assertSelectorResolvesOnVault(vault, IVaultMain.transfer.selector, "transfer");
        _assertSelectorResolvesOnVault(vault, IVaultMain.transferFrom.selector, "transferFrom");
        _assertSelectorResolvesOnVault(vault, IVaultMain.erc4626BufferWrapOrUnwrap.selector, "erc4626BufferWrapOrUnwrap");
        _assertSelectorResolvesOnVault(vault, IVaultMain.getVaultExtension.selector, "getVaultExtension");
    }

    function test_interface_IVaultExtension_selectorsResolveTofacets() public {
        address vault = _deployVault();

        // IVaultExtension selectors - Transient accounting
        _assertSelectorResolvesOnVault(vault, IVaultExtension.isUnlocked.selector, "isUnlocked");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getNonzeroDeltaCount.selector, "getNonzeroDeltaCount");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getTokenDelta.selector, "getTokenDelta");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getReservesOf.selector, "getReservesOf");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getAddLiquidityCalledFlag.selector, "getAddLiquidityCalledFlag");

        // IVaultExtension selectors - Pool Registration
        _assertSelectorResolvesOnVault(vault, IVaultExtension.registerPool.selector, "registerPool");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.isPoolRegistered.selector, "isPoolRegistered");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.initialize.selector, "initialize");

        // IVaultExtension selectors - Pool Information
        _assertSelectorResolvesOnVault(vault, IVaultExtension.isPoolInitialized.selector, "isPoolInitialized");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getPoolTokens.selector, "getPoolTokens");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getPoolTokenRates.selector, "getPoolTokenRates");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getPoolData.selector, "getPoolData");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getPoolTokenInfo.selector, "getPoolTokenInfo");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getCurrentLiveBalances.selector, "getCurrentLiveBalances");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getPoolConfig.selector, "getPoolConfig");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getHooksConfig.selector, "getHooksConfig");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getBptRate.selector, "getBptRate");

        // IVaultExtension selectors - Pool Tokens
        _assertSelectorResolvesOnVault(vault, IVaultExtension.totalSupply.selector, "totalSupply");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.balanceOf.selector, "balanceOf");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.allowance.selector, "allowance");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.approve.selector, "approve");

        // IVaultExtension selectors - Pool Pausing
        _assertSelectorResolvesOnVault(vault, IVaultExtension.isPoolPaused.selector, "isPoolPaused");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getPoolPausedState.selector, "getPoolPausedState");

        // IVaultExtension selectors - ERC4626 Buffers
        _assertSelectorResolvesOnVault(vault, IVaultExtension.isERC4626BufferInitialized.selector, "isERC4626BufferInitialized");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getERC4626BufferAsset.selector, "getERC4626BufferAsset");

        // IVaultExtension selectors - Fees
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getAggregateSwapFeeAmount.selector, "getAggregateSwapFeeAmount");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getAggregateYieldFeeAmount.selector, "getAggregateYieldFeeAmount");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getStaticSwapFeePercentage.selector, "getStaticSwapFeePercentage");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getPoolRoleAccounts.selector, "getPoolRoleAccounts");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.computeDynamicSwapFeePercentage.selector, "computeDynamicSwapFeePercentage");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getProtocolFeeController.selector, "getProtocolFeeController");

        // IVaultExtension selectors - Recovery Mode
        _assertSelectorResolvesOnVault(vault, IVaultExtension.isPoolInRecoveryMode.selector, "isPoolInRecoveryMode");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.removeLiquidityRecovery.selector, "removeLiquidityRecovery");

        // IVaultExtension selectors - Queries
        _assertSelectorResolvesOnVault(vault, IVaultExtension.quote.selector, "quote");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.quoteAndRevert.selector, "quoteAndRevert");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.isQueryDisabled.selector, "isQueryDisabled");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.isQueryDisabledPermanently.selector, "isQueryDisabledPermanently");
        _assertSelectorResolvesOnVault(vault, IVaultExtension.emitAuxiliaryEvent.selector, "emitAuxiliaryEvent");

        // IVaultExtension selectors - Authentication
        _assertSelectorResolvesOnVault(vault, IVaultExtension.getAuthorizer.selector, "getAuthorizer");
    }

    function test_interface_IVaultAdmin_selectorsResolveTofacets() public {
        address vault = _deployVault();

        // IVaultAdmin selectors - Constants
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getPauseWindowEndTime.selector, "getPauseWindowEndTime");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getBufferPeriodDuration.selector, "getBufferPeriodDuration");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getBufferPeriodEndTime.selector, "getBufferPeriodEndTime");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getMinimumPoolTokens.selector, "getMinimumPoolTokens");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getMaximumPoolTokens.selector, "getMaximumPoolTokens");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getPoolMinimumTotalSupply.selector, "getPoolMinimumTotalSupply");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getBufferMinimumTotalSupply.selector, "getBufferMinimumTotalSupply");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getMinimumTradeAmount.selector, "getMinimumTradeAmount");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getMinimumWrapAmount.selector, "getMinimumWrapAmount");

        // IVaultAdmin selectors - Vault Pausing
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.isVaultPaused.selector, "isVaultPaused");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getVaultPausedState.selector, "getVaultPausedState");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.pauseVault.selector, "pauseVault");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.unpauseVault.selector, "unpauseVault");

        // IVaultAdmin selectors - Pool Pausing
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.pausePool.selector, "pausePool");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.unpausePool.selector, "unpausePool");

        // IVaultAdmin selectors - Fees
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.setStaticSwapFeePercentage.selector, "setStaticSwapFeePercentage");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.collectAggregateFees.selector, "collectAggregateFees");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.updateAggregateSwapFeePercentage.selector, "updateAggregateSwapFeePercentage");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.updateAggregateYieldFeePercentage.selector, "updateAggregateYieldFeePercentage");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.setProtocolFeeController.selector, "setProtocolFeeController");

        // IVaultAdmin selectors - Recovery Mode
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.enableRecoveryMode.selector, "enableRecoveryMode");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.disableRecoveryMode.selector, "disableRecoveryMode");

        // IVaultAdmin selectors - Query
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.disableQuery.selector, "disableQuery");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.disableQueryPermanently.selector, "disableQueryPermanently");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.enableQuery.selector, "enableQuery");

        // IVaultAdmin selectors - Buffers
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.areBuffersPaused.selector, "areBuffersPaused");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.pauseVaultBuffers.selector, "pauseVaultBuffers");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.unpauseVaultBuffers.selector, "unpauseVaultBuffers");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.initializeBuffer.selector, "initializeBuffer");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.addLiquidityToBuffer.selector, "addLiquidityToBuffer");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.removeLiquidityFromBuffer.selector, "removeLiquidityFromBuffer");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getBufferAsset.selector, "getBufferAsset");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getBufferOwnerShares.selector, "getBufferOwnerShares");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getBufferTotalShares.selector, "getBufferTotalShares");
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.getBufferBalance.selector, "getBufferBalance");

        // IVaultAdmin selectors - Authentication
        _assertSelectorResolvesOnVault(vault, IVaultAdmin.setAuthorizer.selector, "setAuthorizer");
    }

    function test_interface_IDiamondLoupe_selectorsResolveTofacets() public {
        address vault = _deployVault();

        // IDiamondLoupe selectors
        _assertSelectorResolvesOnVault(vault, IDiamondLoupe.facets.selector, "facets");
        _assertSelectorResolvesOnVault(vault, IDiamondLoupe.facetFunctionSelectors.selector, "facetFunctionSelectors");
        _assertSelectorResolvesOnVault(vault, IDiamondLoupe.facetAddresses.selector, "facetAddresses");
        _assertSelectorResolvesOnVault(vault, IDiamondLoupe.facetAddress.selector, "facetAddress");
    }

    /* ========================================================================== */
    /*                          DiamondLoupe Tests                                */
    /* ========================================================================== */

    function test_diamondLoupe_returnsFacets() public {
        address vault = _deployVault();
        IDiamondLoupe loupe = IDiamondLoupe(vault);

        IDiamondLoupe.Facet[] memory facets = loupe.facets();
        assertTrue(facets.length > 0, "Should return facets");

        // Verify each facet has selectors
        for (uint256 i = 0; i < facets.length; i++) {
            assertTrue(facets[i].facetAddress != address(0), "Facet address should not be zero");
            assertTrue(facets[i].functionSelectors.length > 0, "Facet should have selectors");
        }
    }

    function test_diamondLoupe_facetAddressReturnsCorrectAddress() public {
        address vault = _deployVault();
        IDiamondLoupe loupe = IDiamondLoupe(vault);

        // Check swap selector resolves to swap facet
        address swapFacetAddress = loupe.facetAddress(IVaultMain.swap.selector);
        assertEq(swapFacetAddress, address(swapFacet), "swap should resolve to VaultSwapFacet");

        // Check addLiquidity selector resolves to liquidity facet
        address liquidityFacetAddress = loupe.facetAddress(IVaultMain.addLiquidity.selector);
        assertEq(liquidityFacetAddress, address(liquidityFacet), "addLiquidity should resolve to VaultLiquidityFacet");
    }

    /* ========================================================================== */
    /*                              Helper Functions                              */
    /* ========================================================================== */

    function _deployVault() internal returns (address) {
        return vaultPkg.deployVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            IAuthorizer(address(authorizer)),
            IProtocolFeeController(address(protocolFeeController))
        );
    }

    function _verifyFacetMetadata(IFacet facet, string memory expectedName) internal view {
        (string memory name, bytes4[] memory interfaces, bytes4[] memory functions) = facet.facetMetadata();
        assertEq(name, expectedName, string.concat("Facet name mismatch for ", expectedName));
        assertTrue(interfaces.length > 0, string.concat(expectedName, " should have interfaces"));
        assertTrue(functions.length > 0, string.concat(expectedName, " should have functions"));
    }

    function _assertSelectorResolvesOnVault(address vault, bytes4 selector, string memory functionName) internal view {
        IDiamondLoupe loupe = IDiamondLoupe(vault);
        address facetAddress = loupe.facetAddress(selector);
        assertTrue(
            facetAddress != address(0),
            string.concat("Selector for ", functionName, " should resolve to a facet")
        );
    }
}
