// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";
import {TokenConfig, TokenType} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {IBasePool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePool.sol";
import {IPoolInfo} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-utils/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {IUnbalancedLiquidityInvariantRatioBounds} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";
import {IAuthentication} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IAuthentication.sol";

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";

// Real facet imports
import {BalancerV3VaultAwareFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol";
import {BalancerV3PoolTokenFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol";
import {BalancerV3AuthenticationFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationFacet.sol";
import {BalancerV3ConstantProductPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol";

import {
    BalancerV3ConstantProductPoolDFPkg,
    IBalancerV3ConstantProductPoolStandardVaultPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol";

/**
 * @title BalancerV3ConstantProductPoolDFPkg_RealFacets_Test
 * @notice Tests for BalancerV3ConstantProductPoolDFPkg using REAL facets to detect selector collisions.
 * @dev This test deploys actual facet contracts to verify no selector collisions exist.
 *
 * The DFPkg composes multiple facets that may have overlapping selectors:
 * - BetterBalancerV3PoolTokenFacet: ERC20, ERC20Metadata, ERC20Permit, ERC5267, IBalancerPoolToken, IRateProvider
 * - BalancerV3VaultAwareFacet: IBalancerV3VaultAware
 * - DefaultPoolInfoFacet: IPoolInfo (DEPRECATED - in old/ directory)
 * - BalancerV3AuthenticationFacet: IAuthentication
 * - BalancerV3ConstantProductPoolFacet: IBasePool
 *
 * IMPORTANT: DefaultPoolInfoFacet is in the old/ directory and may be deprecated.
 * This test validates the package configuration to catch deployment issues early.
 */
contract BalancerV3ConstantProductPoolDFPkg_RealFacets_Test is Test {
    BalancerV3ConstantProductPoolDFPkg internal pkg;

    // Real facets
    BalancerV3VaultAwareFacet internal vaultAwareFacet;
    BalancerV3PoolTokenFacet internal poolTokenFacet;
    BalancerV3AuthenticationFacet internal authFacet;
    BalancerV3ConstantProductPoolFacet internal constProdFacet;

    // Mock for DefaultPoolInfoFacet since it's in old/ and may have different dependencies
    IFacet internal poolInfoFacet;

    // Dedicated mocks for fields that exist in PkgInit but are NOT wired into facetCuts().
    // Using separate mocks instead of reusing poolInfoFacet makes test intent explicit:
    // if these fields ever start affecting facetCuts(), tests will surface the change.
    IFacet internal swapFeeBoundsFacet;
    IFacet internal invariantRatioBoundsFacet;

    address internal mockVault;
    address internal mockDiamondFactory;
    address internal poolManager;

    function setUp() public {
        // Create mock addresses
        mockVault = makeAddr("vault");
        mockDiamondFactory = makeAddr("diamondFactory");
        poolManager = makeAddr("poolManager");

        // Deploy real facets
        vaultAwareFacet = new BalancerV3VaultAwareFacet();
        poolTokenFacet = new BalancerV3PoolTokenFacet();
        authFacet = new BalancerV3AuthenticationFacet();
        constProdFacet = new BalancerV3ConstantProductPoolFacet();

        // For poolInfoFacet, we create a mock that returns the IPoolInfo selectors
        // This simulates what DefaultPoolInfoFacet would return
        poolInfoFacet = IFacet(address(new MockPoolInfoFacet()));

        // Dedicated mocks for PkgInit fields that are currently unused by facetCuts()
        swapFeeBoundsFacet = IFacet(address(new MockSwapFeeBoundsFacet()));
        invariantRatioBoundsFacet = IFacet(address(new MockInvariantRatioBoundsFacet()));

        vm.label(address(vaultAwareFacet), "BalancerV3VaultAwareFacet");
        vm.label(address(poolTokenFacet), "BalancerV3PoolTokenFacet");
        vm.label(address(authFacet), "BalancerV3AuthenticationFacet");
        vm.label(address(constProdFacet), "BalancerV3ConstantProductPoolFacet");
        vm.label(address(poolInfoFacet), "MockPoolInfoFacet");
        vm.label(address(swapFeeBoundsFacet), "MockSwapFeeBoundsFacet");
        vm.label(address(invariantRatioBoundsFacet), "MockInvariantRatioBoundsFacet");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Real Facet Selector Collision Tests                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that no selector collisions exist when using real facets.
     * @dev This is the critical test for CRANE-054. It uses real facet implementations
     *      to detect actual selector collisions that would cause Diamond deployment to fail.
     */
    function test_facetCuts_noSelectorCollisions_realFacets() public {
        pkg = _deployPkgWithRealFacets();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        // Collect all selectors with their source facet for debugging
        uint256 totalSelectors = 0;
        for (uint256 i = 0; i < cuts.length; i++) {
            totalSelectors += cuts[i].functionSelectors.length;
        }

        bytes4[] memory allSelectors = new bytes4[](totalSelectors);
        address[] memory selectorSources = new address[](totalSelectors);
        uint256 index = 0;

        for (uint256 i = 0; i < cuts.length; i++) {
            for (uint256 j = 0; j < cuts[i].functionSelectors.length; j++) {
                allSelectors[index] = cuts[i].functionSelectors[j];
                selectorSources[index] = cuts[i].facetAddress;
                index++;
            }
        }

        // Check for zero selectors (catches partially initialized arrays)
        for (uint256 i = 0; i < allSelectors.length; i++) {
            if (allSelectors[i] == bytes4(0)) {
                emit log_named_address("Facet with zero selector", selectorSources[i]);
                emit log_named_uint("Selector index", i);
                fail("Zero selector detected: a facet returned bytes4(0), indicating a partially initialized array");
            }
        }

        // Check for duplicates with detailed error reporting
        for (uint256 i = 0; i < allSelectors.length; i++) {
            for (uint256 j = i + 1; j < allSelectors.length; j++) {
                if (allSelectors[i] == allSelectors[j]) {
                    // Log detailed collision info
                    emit log_named_bytes32("Colliding selector", bytes32(allSelectors[i]));
                    emit log_named_address("First facet", selectorSources[i]);
                    emit log_named_address("Second facet", selectorSources[j]);

                    fail(
                        string.concat(
                            "Selector collision detected: ",
                            vm.toString(bytes32(allSelectors[i])),
                            " between facets at indices ",
                            vm.toString(i),
                            " and ",
                            vm.toString(j)
                        )
                    );
                }
            }
        }
    }

    /**
     * @notice Verifies the total number of unique selectors across all facets.
     */
    function test_facetCuts_selectorCount_realFacets() public {
        pkg = _deployPkgWithRealFacets();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        uint256 totalSelectors = 0;
        for (uint256 i = 0; i < cuts.length; i++) {
            totalSelectors += cuts[i].functionSelectors.length;
            emit log_named_uint(
                string.concat("Facet ", vm.toString(i), " selector count"),
                cuts[i].functionSelectors.length
            );
        }

        emit log_named_uint("Total selectors", totalSelectors);

        // At minimum, we expect selectors from each facet
        assertGt(totalSelectors, 0, "Should have selectors from facets");
    }

    /**
     * @notice Lists all selectors for inspection/debugging.
     */
    function test_facetCuts_listAllSelectors_realFacets() public {
        pkg = _deployPkgWithRealFacets();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        for (uint256 i = 0; i < cuts.length; i++) {
            emit log_named_address(
                string.concat("Facet ", vm.toString(i)),
                cuts[i].facetAddress
            );

            for (uint256 j = 0; j < cuts[i].functionSelectors.length; j++) {
                emit log_named_bytes32(
                    string.concat("  Selector ", vm.toString(j)),
                    bytes32(cuts[i].functionSelectors[j])
                );
            }
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                         Individual Facet Selector Tests                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies BalancerV3VaultAwareFacet exposes expected selectors.
     */
    function test_vaultAwareFacet_selectors() public view {
        bytes4[] memory funcs = vaultAwareFacet.facetFuncs();

        assertEq(funcs.length, 3, "VaultAwareFacet should have 3 functions");
        assertEq(funcs[0], IBalancerV3VaultAware.balV3Vault.selector, "Should have balV3Vault");
        assertEq(funcs[1], IBalancerV3VaultAware.getVault.selector, "Should have getVault");
        assertEq(funcs[2], IBalancerV3VaultAware.getAuthorizer.selector, "Should have getAuthorizer");
    }

    /**
     * @notice Verifies BalancerV3PoolTokenFacet exposes expected ERC20 selectors.
     */
    function test_poolTokenFacet_selectors() public view {
        bytes4[] memory funcs = poolTokenFacet.facetFuncs();

        // Should have ERC20, ERC20Metadata, ERC20Permit, ERC5267, IRateProvider, IBalancerPoolToken functions
        assertGt(funcs.length, 10, "PoolTokenFacet should have many functions");

        // Verify key ERC20 selectors are present
        bool hasName = false;
        bool hasSymbol = false;
        bool hasDecimals = false;
        bool hasTotalSupply = false;
        bool hasBalanceOf = false;

        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IERC20Metadata.name.selector) hasName = true;
            if (funcs[i] == IERC20Metadata.symbol.selector) hasSymbol = true;
            if (funcs[i] == IERC20Metadata.decimals.selector) hasDecimals = true;
            if (funcs[i] == IERC20.totalSupply.selector) hasTotalSupply = true;
            if (funcs[i] == IERC20.balanceOf.selector) hasBalanceOf = true;
        }

        assertTrue(hasName, "Should have name()");
        assertTrue(hasSymbol, "Should have symbol()");
        assertTrue(hasDecimals, "Should have decimals()");
        assertTrue(hasTotalSupply, "Should have totalSupply()");
        assertTrue(hasBalanceOf, "Should have balanceOf()");
    }

    /**
     * @notice Verifies BalancerV3AuthenticationFacet exposes expected selectors.
     */
    function test_authFacet_selectors() public view {
        bytes4[] memory funcs = authFacet.facetFuncs();

        assertEq(funcs.length, 1, "AuthFacet should have 1 function");
        assertEq(funcs[0], IAuthentication.getActionId.selector, "Should have getActionId");
    }

    /**
     * @notice Verifies BalancerV3ConstantProductPoolFacet exposes expected selectors.
     */
    function test_constProdFacet_selectors() public view {
        bytes4[] memory funcs = constProdFacet.facetFuncs();

        // Should have IBasePool functions
        assertGt(funcs.length, 0, "ConstProdFacet should have functions");

        // Verify key IBasePool selectors are present
        bool hasComputeInvariant = false;
        bool hasComputeBalance = false;
        bool hasOnSwap = false;

        for (uint256 i = 0; i < funcs.length; i++) {
            if (funcs[i] == IBasePool.computeInvariant.selector) hasComputeInvariant = true;
            if (funcs[i] == IBasePool.computeBalance.selector) hasComputeBalance = true;
            if (funcs[i] == IBasePool.onSwap.selector) hasOnSwap = true;
        }

        assertTrue(hasComputeInvariant, "Should have computeInvariant()");
        assertTrue(hasComputeBalance, "Should have computeBalance()");
        assertTrue(hasOnSwap, "Should have onSwap()");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Package Metadata Tests                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies package metadata is correct with real facets.
     */
    function test_packageMetadata_realFacets() public {
        pkg = _deployPkgWithRealFacets();

        (string memory name, bytes4[] memory interfaces, address[] memory facets) = pkg.packageMetadata();

        assertEq(name, "BalancerV3ConstantProductPoolDFPkg", "Package name should match");
        assertEq(interfaces.length, 11, "Should have 11 interfaces");
        assertEq(facets.length, 5, "Should have 5 facets");

        // Verify facet addresses match what we deployed
        assertEq(facets[0], address(vaultAwareFacet), "First facet should be VaultAware");
        assertEq(facets[1], address(poolTokenFacet), "Second facet should be PoolToken");
        assertEq(facets[2], address(poolInfoFacet), "Third facet should be PoolInfo");
        assertEq(facets[3], address(authFacet), "Fourth facet should be Auth");
        assertEq(facets[4], address(constProdFacet), "Fifth facet should be ConstProd");
    }

    /**
     * @notice Verifies all expected interfaces are declared.
     */
    function test_facetInterfaces_realFacets() public {
        pkg = _deployPkgWithRealFacets();

        bytes4[] memory interfaces = pkg.facetInterfaces();

        // Check for key interfaces
        bool hasIERC20 = false;
        bool hasIERC20Metadata = false;
        bool hasIBalancerV3VaultAware = false;
        bool hasIPoolInfo = false;
        bool hasIBasePool = false;

        for (uint256 i = 0; i < interfaces.length; i++) {
            if (interfaces[i] == type(IERC20).interfaceId) hasIERC20 = true;
            if (interfaces[i] == type(IERC20Metadata).interfaceId) hasIERC20Metadata = true;
            if (interfaces[i] == type(IBalancerV3VaultAware).interfaceId) hasIBalancerV3VaultAware = true;
            if (interfaces[i] == type(IPoolInfo).interfaceId) hasIPoolInfo = true;
            if (interfaces[i] == type(IBasePool).interfaceId) hasIBasePool = true;
        }

        assertTrue(hasIERC20, "Should declare IERC20 interface");
        assertTrue(hasIERC20Metadata, "Should declare IERC20Metadata interface");
        assertTrue(hasIBalancerV3VaultAware, "Should declare IBalancerV3VaultAware interface");
        assertTrue(hasIPoolInfo, "Should declare IPoolInfo interface");
        assertTrue(hasIBasePool, "Should declare IBasePool interface");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Diamond Config Tests                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies diamondConfig returns valid cuts and interfaces.
     */
    function test_diamondConfig_realFacets() public {
        pkg = _deployPkgWithRealFacets();

        IDiamondFactoryPackage.DiamondConfig memory config = pkg.diamondConfig();

        assertEq(config.facetCuts.length, 5, "Should have 5 facet cuts");
        assertEq(config.interfaces.length, 11, "Should have 11 interfaces");

        // Verify all cuts have Add action
        for (uint256 i = 0; i < config.facetCuts.length; i++) {
            assertEq(
                uint8(config.facetCuts[i].action),
                uint8(IDiamond.FacetCutAction.Add),
                "All cuts should be Add action"
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                  Unused PkgInit Fields Regression Tests                    */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that standardSwapFeePercentageBoundsFacet is NOT used in facetCuts().
     * @dev The PkgInit struct accepts this field, but the constructor does not store it
     *      and facetCuts() does not reference it. This test will fail if that ever changes,
     *      surfacing the need to update mock usage accordingly.
     */
    function test_swapFeeBoundsFacet_notInFacetCuts() public {
        pkg = _deployPkgWithRealFacets();
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        for (uint256 i = 0; i < cuts.length; i++) {
            assertTrue(
                cuts[i].facetAddress != address(swapFeeBoundsFacet),
                "standardSwapFeePercentageBoundsFacet should NOT appear in facetCuts()"
            );
        }
    }

    /**
     * @notice Verifies that unbalancedLiquidityInvariantRatioBoundsFacet is NOT used in facetCuts().
     * @dev Same rationale as test_swapFeeBoundsFacet_notInFacetCuts.
     */
    function test_invariantRatioBoundsFacet_notInFacetCuts() public {
        pkg = _deployPkgWithRealFacets();
        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        for (uint256 i = 0; i < cuts.length; i++) {
            assertTrue(
                cuts[i].facetAddress != address(invariantRatioBoundsFacet),
                "unbalancedLiquidityInvariantRatioBoundsFacet should NOT appear in facetCuts()"
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                         Helper Functions                                    */
    /* -------------------------------------------------------------------------- */

    function _deployPkgWithRealFacets() internal returns (BalancerV3ConstantProductPoolDFPkg) {
        return new BalancerV3ConstantProductPoolDFPkg(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                betterBalancerV3PoolTokenFacet: IFacet(address(poolTokenFacet)),
                defaultPoolInfoFacet: IFacet(address(poolInfoFacet)),
                standardSwapFeePercentageBoundsFacet: swapFeeBoundsFacet,
                unbalancedLiquidityInvariantRatioBoundsFacet: invariantRatioBoundsFacet,
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                balancerV3ConstProdPoolFacet: IFacet(address(constProdFacet)),
                balancerV3Vault: IVault(mockVault),
                diamondFactory: IDiamondPackageCallBackFactory(mockDiamondFactory),
                poolFeeManager: poolManager
            })
        );
    }
}

/**
 * @title MockPoolInfoFacet
 * @notice Mock facet that simulates DefaultPoolInfoFacet's selectors.
 * @dev DefaultPoolInfoFacet is in old/ directory (deprecated).
 *      This mock returns the expected IPoolInfo selectors for testing.
 */
contract MockPoolInfoFacet is IFacet {
    function facetName() external pure returns (string memory) {
        return "MockPoolInfoFacet";
    }

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IPoolInfo).interfaceId;
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](5);
        funcs[0] = IPoolInfo.getTokens.selector;
        funcs[1] = IPoolInfo.getTokenInfo.selector;
        funcs[2] = IPoolInfo.getCurrentLiveBalances.selector;
        funcs[3] = IPoolInfo.getStaticSwapFeePercentage.selector;
        funcs[4] = IPoolInfo.getAggregateFeePercentages.selector;
    }

    function facetMetadata() external pure returns (string memory, bytes4[] memory, bytes4[] memory) {
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = type(IPoolInfo).interfaceId;

        bytes4[] memory funcs = new bytes4[](5);
        funcs[0] = IPoolInfo.getTokens.selector;
        funcs[1] = IPoolInfo.getTokenInfo.selector;
        funcs[2] = IPoolInfo.getCurrentLiveBalances.selector;
        funcs[3] = IPoolInfo.getStaticSwapFeePercentage.selector;
        funcs[4] = IPoolInfo.getAggregateFeePercentages.selector;

        return ("MockPoolInfoFacet", interfaces, funcs);
    }
}

/**
 * @title MockSwapFeeBoundsFacet
 * @notice Dedicated mock for the standardSwapFeePercentageBoundsFacet PkgInit field.
 * @dev This field exists in PkgInit but is NOT stored by the constructor and NOT
 *      referenced in facetCuts(). Using a dedicated mock (instead of reusing
 *      MockPoolInfoFacet) makes this explicit and catches regressions.
 */
contract MockSwapFeeBoundsFacet is IFacet {
    function facetName() external pure returns (string memory) {
        return "MockSwapFeeBoundsFacet";
    }

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(ISwapFeePercentageBounds).interfaceId;
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = ISwapFeePercentageBounds.getMinimumSwapFeePercentage.selector;
        funcs[1] = ISwapFeePercentageBounds.getMaximumSwapFeePercentage.selector;
    }

    function facetMetadata() external pure returns (string memory, bytes4[] memory, bytes4[] memory) {
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = type(ISwapFeePercentageBounds).interfaceId;

        bytes4[] memory funcs = new bytes4[](2);
        funcs[0] = ISwapFeePercentageBounds.getMinimumSwapFeePercentage.selector;
        funcs[1] = ISwapFeePercentageBounds.getMaximumSwapFeePercentage.selector;

        return ("MockSwapFeeBoundsFacet", interfaces, funcs);
    }
}

/**
 * @title MockInvariantRatioBoundsFacet
 * @notice Dedicated mock for the unbalancedLiquidityInvariantRatioBoundsFacet PkgInit field.
 * @dev This field exists in PkgInit but is NOT stored by the constructor and NOT
 *      referenced in facetCuts(). Using a dedicated mock (instead of reusing
 *      MockPoolInfoFacet) makes this explicit and catches regressions.
 */
contract MockInvariantRatioBoundsFacet is IFacet {
    function facetName() external pure returns (string memory) {
        return "MockInvariantRatioBoundsFacet";
    }

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](1);
        interfaces[0] = type(IUnbalancedLiquidityInvariantRatioBounds).interfaceId;
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = IUnbalancedLiquidityInvariantRatioBounds.getMinimumInvariantRatio.selector;
        funcs[1] = IUnbalancedLiquidityInvariantRatioBounds.getMaximumInvariantRatio.selector;
    }

    function facetMetadata() external pure returns (string memory, bytes4[] memory, bytes4[] memory) {
        bytes4[] memory interfaces = new bytes4[](1);
        interfaces[0] = type(IUnbalancedLiquidityInvariantRatioBounds).interfaceId;

        bytes4[] memory funcs = new bytes4[](2);
        funcs[0] = IUnbalancedLiquidityInvariantRatioBounds.getMinimumInvariantRatio.selector;
        funcs[1] = IUnbalancedLiquidityInvariantRatioBounds.getMaximumInvariantRatio.selector;

        return ("MockInvariantRatioBoundsFacet", interfaces, funcs);
    }
}
