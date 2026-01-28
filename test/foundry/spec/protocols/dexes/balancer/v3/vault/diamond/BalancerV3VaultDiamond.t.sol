// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Foundry                                  */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                               OpenZeppelin                                 */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/* -------------------------------------------------------------------------- */
/*                                  Balancer                                  */
/* -------------------------------------------------------------------------- */

import {IAuthorizer} from "@balancer-labs/v3-interfaces/contracts/vault/IAuthorizer.sol";
import {IProtocolFeeController} from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IVaultMain} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultMain.sol";
import {IVaultExtension} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultExtension.sol";
import {IVaultAdmin} from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";

/* -------------------------------------------------------------------------- */
/*                           Balancer V3 Vault Diamond                        */
/* -------------------------------------------------------------------------- */

import {BalancerV3VaultDiamond} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultDiamond.sol";
import {BalancerV3VaultStorageRepo} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/BalancerV3VaultStorageRepo.sol";

// Facets
import {VaultTransientFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultTransientFacet.sol";
import {VaultSwapFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultSwapFacet.sol";
import {VaultLiquidityFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultLiquidityFacet.sol";
import {VaultBufferFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultBufferFacet.sol";
import {VaultPoolTokenFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultPoolTokenFacet.sol";
import {VaultQueryFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultQueryFacet.sol";
import {VaultRegistrationFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultRegistrationFacet.sol";
import {VaultAdminFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultAdminFacet.sol";
import {VaultRecoveryFacet} from
    "@crane/contracts/protocols/dexes/balancer/v3/vault/diamond/facets/VaultRecoveryFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                 Mock Contracts                             */
/* -------------------------------------------------------------------------- */

/// @notice Mock authorizer that allows all actions
contract MockAuthorizer is IAuthorizer {
    mapping(bytes32 => mapping(address => bool)) public permissions;
    bool public defaultAllow = true;

    function setDefaultAllow(bool allow) external {
        defaultAllow = allow;
    }

    function grantPermission(bytes32 actionId, address account) external {
        permissions[actionId][account] = true;
    }

    function canPerform(bytes32 actionId, address account, address) external view override returns (bool) {
        if (defaultAllow) return true;
        return permissions[actionId][account];
    }
}

/// @notice Mock protocol fee controller
contract MockProtocolFeeController is IProtocolFeeController {
    address public vault_;

    function vault() external view override returns (IVault) {
        return IVault(vault_);
    }

    function setVault(address _vault) external {
        vault_ = _vault;
    }

    function collectAggregateFees(address) external override {}

    function getGlobalProtocolSwapFeePercentage() external pure override returns (uint256) {
        return 0;
    }

    function getGlobalProtocolYieldFeePercentage() external pure override returns (uint256) {
        return 0;
    }

    function isPoolRegistered(address) external pure override returns (bool) {
        return false;
    }

    function getPoolProtocolSwapFeeInfo(address)
        external
        pure
        override
        returns (uint256 feePercentage, bool isOverride)
    {
        return (0, false);
    }

    function getPoolProtocolYieldFeeInfo(address)
        external
        pure
        override
        returns (uint256 feePercentage, bool isOverride)
    {
        return (0, false);
    }

    function getPoolCreatorSwapFeePercentage(address) external pure override returns (uint256) {
        return 0;
    }

    function getPoolCreatorYieldFeePercentage(address) external pure override returns (uint256) {
        return 0;
    }

    function computeAggregateFeePercentage(uint256, uint256) external pure override returns (uint256) {
        return 0;
    }

    function updateProtocolSwapFeePercentage(address) external override {}

    function updateProtocolYieldFeePercentage(address) external override {}

    function registerPool(address, address, bool) external pure override returns (uint256, uint256) {
        return (0, 0);
    }

    function setGlobalProtocolSwapFeePercentage(uint256) external override {}

    function setGlobalProtocolYieldFeePercentage(uint256) external override {}

    function setProtocolSwapFeePercentage(address, uint256) external override {}

    function setProtocolYieldFeePercentage(address, uint256) external override {}

    function setPoolCreatorSwapFeePercentage(address, uint256) external override {}

    function setPoolCreatorYieldFeePercentage(address, uint256) external override {}

    function withdrawPoolCreatorFees(address, address) external override {}

    function withdrawPoolCreatorFees(address) external override {}

    function withdrawProtocolFees(address, address) external override {}

    function withdrawProtocolFeesForToken(address, address, IERC20) external override {}

    function getProtocolFeeAmounts(address)
        external
        pure
        override
        returns (uint256[] memory feeAmounts)
    {
        return new uint256[](0);
    }

    function getPoolCreatorFeeAmounts(address)
        external
        pure
        override
        returns (uint256[] memory feeAmounts)
    {
        return new uint256[](0);
    }
}

/**
 * @title BalancerV3VaultDiamondTest
 * @notice Tests for the Balancer V3 Vault Diamond proxy.
 */
contract BalancerV3VaultDiamondTest is Test {
    BalancerV3VaultDiamond public diamond;
    MockAuthorizer public authorizer;
    MockProtocolFeeController public feeController;

    // Facet instances
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

    // Default config values (matching Balancer V3)
    uint256 constant MINIMUM_TRADE_AMOUNT = 1e6; // 1e6 in scaled18
    uint256 constant MINIMUM_WRAP_AMOUNT = 1e4; // 1e4 in native decimals
    uint32 constant PAUSE_WINDOW_DURATION = 365 days;
    uint32 constant BUFFER_PERIOD_DURATION = 90 days;

    function setUp() public {
        admin = makeAddr("admin");
        user = makeAddr("user");

        // Deploy mock contracts
        authorizer = new MockAuthorizer();
        feeController = new MockProtocolFeeController();

        // Deploy Diamond proxy
        diamond = new BalancerV3VaultDiamond();

        // Deploy all facets
        transientFacet = new VaultTransientFacet();
        swapFacet = new VaultSwapFacet();
        liquidityFacet = new VaultLiquidityFacet();
        bufferFacet = new VaultBufferFacet();
        poolTokenFacet = new VaultPoolTokenFacet();
        queryFacet = new VaultQueryFacet();
        registrationFacet = new VaultRegistrationFacet();
        adminFacet = new VaultAdminFacet();
        recoveryFacet = new VaultRecoveryFacet();

        // Set fee controller vault reference
        feeController.setVault(address(diamond));

        // Label addresses for debugging
        vm.label(address(diamond), "VaultDiamond");
        vm.label(address(authorizer), "MockAuthorizer");
        vm.label(address(feeController), "MockFeeController");
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
    /*                          Diamond Deployment Tests                          */
    /* ========================================================================== */

    function test_diamond_deploySuccessfully() public view {
        assertTrue(address(diamond) != address(0), "Diamond should deploy");
        assertTrue(address(diamond).code.length > 0, "Diamond should have code");
    }

    function test_diamond_vault_returnsSelf() public view {
        assertEq(address(diamond.vault()), address(diamond), "vault() should return self");
    }

    /* ========================================================================== */
    /*                          Facet Cutting Tests                               */
    /* ========================================================================== */

    function test_diamondCut_addTransientFacet() public {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = _buildFacetCut(
            address(transientFacet),
            IDiamond.FacetCutAction.Add,
            _getTransientFacetSelectors()
        );

        diamond.diamondCut(cuts, address(0), "");

        // Verify selector is registered
        // Note: We can't call facetAddress directly on diamond unless we add DiamondLoupe
        // For now, just verify the cut didn't revert
    }

    function test_diamondCut_addAllFacets() public {
        _cutAllFacets();
        // If we get here without reverting, all facets were added
    }

    /* ========================================================================== */
    /*                          Initialization Tests                              */
    /* ========================================================================== */

    function test_initializeVault_setsConfiguration() public {
        _cutAllFacets();

        diamond.initializeVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            authorizer,
            feeController
        );

        // Verify by reading through query facet
        // Cast diamond to IVaultExtension to call getVaultPausedState
        IVaultAdmin vaultAdmin = IVaultAdmin(address(diamond));
        (bool paused, uint32 pauseWindowEndTime, uint32 bufferPeriodEndTime) = vaultAdmin.getVaultPausedState();

        assertFalse(paused, "Vault should not be paused initially");
        assertEq(pauseWindowEndTime, uint32(block.timestamp) + PAUSE_WINDOW_DURATION, "Pause window end time incorrect");
        assertEq(
            bufferPeriodEndTime,
            uint32(block.timestamp) + PAUSE_WINDOW_DURATION + BUFFER_PERIOD_DURATION,
            "Buffer period end time incorrect"
        );
    }

    function test_initializeVault_revertsOnDoubleInit() public {
        _cutAllFacets();

        diamond.initializeVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            authorizer,
            feeController
        );

        vm.expectRevert("BalancerV3VaultStorageRepo: already initialized");
        diamond.initializeVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            authorizer,
            feeController
        );
    }

    /* ========================================================================== */
    /*                          Access Control Tests                              */
    /* ========================================================================== */

    function test_diamondCut_revertsAfterInitWithoutAuth() public {
        _cutAllFacets();

        diamond.initializeVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            authorizer,
            feeController
        );

        // Disable default allow
        authorizer.setDefaultAllow(false);

        // Try to cut - should fail because user is not authorized
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](1);
        cuts[0] = _buildFacetCut(
            address(transientFacet),
            IDiamond.FacetCutAction.Replace,
            _getTransientFacetSelectors()
        );

        vm.prank(user);
        vm.expectRevert(BalancerV3VaultDiamond.Unauthorized.selector);
        diamond.diamondCut(cuts, address(0), "");
    }

    /* ========================================================================== */
    /*                          Interface Compliance Tests                        */
    /* ========================================================================== */

    function test_interface_vaultExtensionFunctionsAccessible() public {
        _cutAllFacets();
        _initializeVault();

        // Test that we can call IVaultExtension functions
        IVaultExtension vaultExtension = IVaultExtension(address(diamond));

        // isUnlocked should be callable and return false initially
        assertFalse(vaultExtension.isUnlocked(), "Vault should be locked initially");
    }

    function test_interface_vaultAdminFunctionsAccessible() public {
        _cutAllFacets();
        _initializeVault();

        IVaultAdmin vaultAdmin = IVaultAdmin(address(diamond));

        // isVaultPaused should be callable
        assertFalse(vaultAdmin.isVaultPaused(), "Vault should not be paused");

        // areBuffersPaused should be callable
        assertFalse(vaultAdmin.areBuffersPaused(), "Buffers should not be paused");

        // isQueryDisabled is in IVaultExtension
        IVaultExtension vaultExtension = IVaultExtension(address(diamond));
        assertFalse(vaultExtension.isQueryDisabled(), "Queries should not be disabled");
    }

    /* ========================================================================== */
    /*                              Helper Functions                              */
    /* ========================================================================== */

    function _cutAllFacets() internal {
        IDiamond.FacetCut[] memory cuts = new IDiamond.FacetCut[](9);

        cuts[0] = _buildFacetCut(
            address(transientFacet),
            IDiamond.FacetCutAction.Add,
            _getTransientFacetSelectors()
        );
        cuts[1] = _buildFacetCut(address(swapFacet), IDiamond.FacetCutAction.Add, _getSwapFacetSelectors());
        cuts[2] = _buildFacetCut(address(liquidityFacet), IDiamond.FacetCutAction.Add, _getLiquidityFacetSelectors());
        cuts[3] = _buildFacetCut(address(bufferFacet), IDiamond.FacetCutAction.Add, _getBufferFacetSelectors());
        cuts[4] = _buildFacetCut(address(poolTokenFacet), IDiamond.FacetCutAction.Add, _getPoolTokenFacetSelectors());
        cuts[5] = _buildFacetCut(address(queryFacet), IDiamond.FacetCutAction.Add, _getQueryFacetSelectors());
        cuts[6] =
            _buildFacetCut(address(registrationFacet), IDiamond.FacetCutAction.Add, _getRegistrationFacetSelectors());
        cuts[7] = _buildFacetCut(address(adminFacet), IDiamond.FacetCutAction.Add, _getAdminFacetSelectors());
        cuts[8] = _buildFacetCut(address(recoveryFacet), IDiamond.FacetCutAction.Add, _getRecoveryFacetSelectors());

        diamond.diamondCut(cuts, address(0), "");
    }

    function _initializeVault() internal {
        diamond.initializeVault(
            MINIMUM_TRADE_AMOUNT,
            MINIMUM_WRAP_AMOUNT,
            PAUSE_WINDOW_DURATION,
            BUFFER_PERIOD_DURATION,
            authorizer,
            feeController
        );
    }

    function _buildFacetCut(address facetAddress, IDiamond.FacetCutAction action, bytes4[] memory selectors)
        internal
        pure
        returns (IDiamond.FacetCut memory)
    {
        return IDiamond.FacetCut({facetAddress: facetAddress, action: action, functionSelectors: selectors});
    }

    /* ========================================================================== */
    /*                          Selector Helper Functions                         */
    /* ========================================================================== */

    function _getTransientFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = IVaultMain.unlock.selector;
        selectors[1] = IVaultMain.settle.selector;
        selectors[2] = IVaultMain.sendTo.selector;
        selectors[3] = IVaultExtension.isUnlocked.selector;
        return selectors;
    }

    function _getSwapFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = IVaultMain.swap.selector;
        return selectors;
    }

    function _getLiquidityFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = IVaultMain.addLiquidity.selector;
        selectors[1] = IVaultMain.removeLiquidity.selector;
        return selectors;
    }

    function _getBufferFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = IVaultMain.erc4626BufferWrapOrUnwrap.selector;
        return selectors;
    }

    function _getPoolTokenFacetSelectors() internal pure returns (bytes4[] memory) {
        // BPT transfer functions - these use pool address as first param
        bytes4[] memory selectors = new bytes4[](5);
        // transfer(address pool, address from, address to, uint256 amount)
        selectors[0] = bytes4(keccak256("transfer(address,address,address,uint256)"));
        // transferFrom(address pool, address from, address to, uint256 amount)
        selectors[1] = bytes4(keccak256("transferFrom(address,address,address,uint256)"));
        // approve(address pool, address owner, address spender, uint256 amount)
        selectors[2] = bytes4(keccak256("approve(address,address,address,uint256)"));
        // balanceOf(address pool, address account)
        selectors[3] = bytes4(keccak256("balanceOf(address,address)"));
        // totalSupply(address pool)
        selectors[4] = bytes4(keccak256("totalSupply(address)"));
        return selectors;
    }

    function _getQueryFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](11);
        selectors[0] = IVaultExtension.getPoolTokens.selector;
        selectors[1] = IVaultExtension.getPoolConfig.selector;
        selectors[2] = IVaultExtension.getHooksConfig.selector;
        selectors[3] = IVaultExtension.getPoolTokenInfo.selector;
        selectors[4] = IVaultExtension.getCurrentLiveBalances.selector;
        selectors[5] = IVaultExtension.getPoolData.selector;
        selectors[6] = IVaultExtension.getPoolTokenRates.selector;
        selectors[7] = IVaultExtension.isPoolInitialized.selector;
        selectors[8] = IVaultExtension.isPoolRegistered.selector;
        selectors[9] = IVaultExtension.isQueryDisabled.selector;
        selectors[10] = IVaultExtension.isQueryDisabledPermanently.selector;
        return selectors;
    }

    function _getRegistrationFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = IVaultExtension.registerPool.selector;
        selectors[1] = IVaultExtension.initialize.selector;
        return selectors;
    }

    function _getAdminFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](17);
        selectors[0] = IVaultAdmin.pauseVault.selector;
        selectors[1] = IVaultAdmin.unpauseVault.selector;
        selectors[2] = IVaultAdmin.isVaultPaused.selector;
        selectors[3] = IVaultAdmin.getVaultPausedState.selector;
        selectors[4] = IVaultAdmin.pausePool.selector;
        selectors[5] = IVaultAdmin.unpausePool.selector;
        selectors[6] = IVaultAdmin.pauseVaultBuffers.selector;
        selectors[7] = IVaultAdmin.unpauseVaultBuffers.selector;
        selectors[8] = IVaultAdmin.areBuffersPaused.selector;
        selectors[9] = IVaultAdmin.setStaticSwapFeePercentage.selector;
        selectors[10] = IVaultAdmin.updateAggregateSwapFeePercentage.selector;
        selectors[11] = IVaultAdmin.updateAggregateYieldFeePercentage.selector;
        selectors[12] = IVaultAdmin.enableRecoveryMode.selector;
        selectors[13] = IVaultAdmin.disableRecoveryMode.selector;
        selectors[14] = IVaultAdmin.disableQuery.selector;
        selectors[15] = IVaultAdmin.disableQueryPermanently.selector;
        selectors[16] = IVaultAdmin.enableQuery.selector;
        return selectors;
    }

    function _getRecoveryFacetSelectors() internal pure returns (bytes4[] memory) {
        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = IVaultExtension.removeLiquidityRecovery.selector;
        return selectors;
    }
}
