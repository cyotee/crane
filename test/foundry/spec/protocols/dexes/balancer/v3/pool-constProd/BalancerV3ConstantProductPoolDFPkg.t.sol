// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {TokenConfig, TokenType} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IPoolInfo} from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@balancer-labs/v3-interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {IUnbalancedLiquidityInvariantRatioBounds} from "@balancer-labs/v3-interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
import {
    BalancerV3ConstantProductPoolDFPkg,
    IBalancerV3ConstantProductPoolStandardVaultPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol";

// Mock ERC20 for testing
contract MockERC20 is IERC20, IERC20Metadata {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() external view override returns (string memory) { return _name; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        _balances[msg.sender] -= amount;
        _balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        _allowances[from][msg.sender] -= amount;
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        _balances[to] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

// Mock Facet implementing IFacet for testing
contract MockFacet is IFacet {
    bytes4[] private _funcs;
    bytes4[] private _interfaces;
    string private _name;

    constructor(string memory name_, bytes4[] memory funcs_, bytes4[] memory interfaces_) {
        _name = name_;
        _funcs = funcs_;
        _interfaces = interfaces_;
    }

    function facetName() external view override returns (string memory) { return _name; }
    function facetInterfaces() external view override returns (bytes4[] memory) { return _interfaces; }
    function facetFuncs() external view override returns (bytes4[] memory) { return _funcs; }
    function facetMetadata() external view override returns (string memory, bytes4[] memory, bytes4[] memory) {
        return (_name, _interfaces, _funcs);
    }
}

/**
 * @title BalancerV3ConstantProductPoolDFPkg_Test
 * @notice Tests for BalancerV3ConstantProductPoolDFPkg Diamond Factory Package.
 * @dev Tests verify:
 *  - Full diamond deployment via DFPkg
 *  - No selector collisions in facetCuts
 *  - Package metadata correctness
 *  - Salt calculation determinism
 *  - Token configuration handling
 */
contract BalancerV3ConstantProductPoolDFPkg_Test is Test {
    BalancerV3ConstantProductPoolDFPkg internal pkg;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    MockERC20 internal tokenC;
    MockERC20 internal tokenD;

    // Mock facets with unique selectors
    MockFacet internal vaultAwareFacet;
    MockFacet internal poolTokenFacet;
    MockFacet internal poolInfoFacet;
    MockFacet internal authFacet;
    MockFacet internal constProdFacet;

    address internal mockVault;
    address internal mockDiamondFactory;
    address internal poolManager;

    function setUp() public {
        // Deploy mock tokens (with addresses that ensure specific order)
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        tokenC = new MockERC20("Token C", "TKNC", 18);
        tokenD = new MockERC20("Token D", "TKND", 18);

        // Create mock addresses
        mockVault = makeAddr("vault");
        mockDiamondFactory = makeAddr("diamondFactory");
        poolManager = makeAddr("poolManager");

        // Create mock facets with distinct selectors
        bytes4[] memory vaultAwareFuncs = new bytes4[](1);
        vaultAwareFuncs[0] = IBalancerV3VaultAware.balV3Vault.selector;
        bytes4[] memory vaultAwareInterfaces = new bytes4[](1);
        vaultAwareInterfaces[0] = type(IBalancerV3VaultAware).interfaceId;
        vaultAwareFacet = new MockFacet("VaultAwareFacet", vaultAwareFuncs, vaultAwareInterfaces);

        bytes4[] memory poolTokenFuncs = new bytes4[](2);
        poolTokenFuncs[0] = bytes4(keccak256("poolTokenFunc1()"));
        poolTokenFuncs[1] = bytes4(keccak256("poolTokenFunc2()"));
        bytes4[] memory poolTokenInterfaces = new bytes4[](1);
        poolTokenInterfaces[0] = type(IBalancerPoolToken).interfaceId;
        poolTokenFacet = new MockFacet("PoolTokenFacet", poolTokenFuncs, poolTokenInterfaces);

        bytes4[] memory poolInfoFuncs = new bytes4[](1);
        poolInfoFuncs[0] = bytes4(keccak256("poolInfoFunc()"));
        bytes4[] memory poolInfoInterfaces = new bytes4[](1);
        poolInfoInterfaces[0] = type(IPoolInfo).interfaceId;
        poolInfoFacet = new MockFacet("PoolInfoFacet", poolInfoFuncs, poolInfoInterfaces);

        bytes4[] memory authFuncs = new bytes4[](1);
        authFuncs[0] = bytes4(keccak256("authFunc()"));
        bytes4[] memory authInterfaces = new bytes4[](0);
        authFacet = new MockFacet("AuthFacet", authFuncs, authInterfaces);

        bytes4[] memory constProdFuncs = new bytes4[](3);
        constProdFuncs[0] = IBasePool.computeInvariant.selector;
        constProdFuncs[1] = IBasePool.computeBalance.selector;
        constProdFuncs[2] = IBasePool.onSwap.selector;
        bytes4[] memory constProdInterfaces = new bytes4[](1);
        constProdInterfaces[0] = type(IBasePool).interfaceId;
        constProdFacet = new MockFacet("ConstProdFacet", constProdFuncs, constProdInterfaces);

        // Note: Full deployment requires real DiamondPackageCallBackFactory
        // These tests focus on DFPkg configuration and metadata
    }

    /* -------------------------------------------------------------------------- */
    /*                           Package Metadata Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_packageName_returnsCorrectName() public {
        // Deploy package with mock dependencies
        pkg = _deployPkg();

        string memory name = pkg.packageName();
        assertEq(name, "BalancerV3ConstantProductPoolDFPkg", "Package name should match");
    }

    function test_packageMetadata_returnsAllData() public {
        pkg = _deployPkg();

        (string memory name, bytes4[] memory interfaces, address[] memory facets) = pkg.packageMetadata();

        assertEq(name, "BalancerV3ConstantProductPoolDFPkg", "Name should match");
        assertEq(interfaces.length, 11, "Should have 11 interfaces");
        assertEq(facets.length, 5, "Should have 5 facets");
    }

    function test_facetAddresses_returnsAllFacets() public {
        pkg = _deployPkg();

        address[] memory facets = pkg.facetAddresses();

        assertEq(facets.length, 5, "Should return 5 facet addresses");
        assertEq(facets[0], address(vaultAwareFacet), "First facet should be vault aware");
        assertEq(facets[1], address(poolTokenFacet), "Second facet should be pool token");
        assertEq(facets[2], address(poolInfoFacet), "Third facet should be pool info");
        assertEq(facets[3], address(authFacet), "Fourth facet should be auth");
        assertEq(facets[4], address(constProdFacet), "Fifth facet should be const prod");
    }

    function test_facetInterfaces_returnsAllInterfaces() public {
        pkg = _deployPkg();

        bytes4[] memory interfaces = pkg.facetInterfaces();

        assertEq(interfaces.length, 11, "Should return 11 interfaces");

        // Verify expected interfaces are present
        assertEq(interfaces[0], type(IERC20).interfaceId, "Should include IERC20");
        assertEq(interfaces[1], type(IERC20Metadata).interfaceId, "Should include IERC20Metadata");
        assertEq(interfaces[5], type(IBalancerV3VaultAware).interfaceId, "Should include IBalancerV3VaultAware");
        assertEq(interfaces[6], type(IPoolInfo).interfaceId, "Should include IPoolInfo");
        assertEq(interfaces[7], type(IBasePool).interfaceId, "Should include IBasePool");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Facet Cuts Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_facetCuts_returnsFiveCuts() public {
        pkg = _deployPkg();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts.length, 5, "Should return 5 facet cuts");
    }

    function test_facetCuts_allActionsAreAdd() public {
        pkg = _deployPkg();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        for (uint256 i = 0; i < cuts.length; i++) {
            assertEq(
                uint8(cuts[i].action),
                uint8(IDiamond.FacetCutAction.Add),
                string.concat("Cut ", vm.toString(i), " should be Add action")
            );
        }
    }

    function test_facetCuts_allHaveFunctions() public {
        pkg = _deployPkg();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        for (uint256 i = 0; i < cuts.length; i++) {
            assertGt(
                cuts[i].functionSelectors.length,
                0,
                string.concat("Cut ", vm.toString(i), " should have functions")
            );
        }
    }

    function test_facetCuts_noSelectorCollisions() public {
        pkg = _deployPkg();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        // Collect all selectors
        uint256 totalSelectors = 0;
        for (uint256 i = 0; i < cuts.length; i++) {
            totalSelectors += cuts[i].functionSelectors.length;
        }

        bytes4[] memory allSelectors = new bytes4[](totalSelectors);
        uint256 index = 0;
        for (uint256 i = 0; i < cuts.length; i++) {
            for (uint256 j = 0; j < cuts[i].functionSelectors.length; j++) {
                allSelectors[index++] = cuts[i].functionSelectors[j];
            }
        }

        // Check for duplicates (O(n^2) but fine for small arrays)
        for (uint256 i = 0; i < allSelectors.length; i++) {
            for (uint256 j = i + 1; j < allSelectors.length; j++) {
                assertTrue(
                    allSelectors[i] != allSelectors[j],
                    string.concat(
                        "Selector collision detected: ",
                        vm.toString(bytes32(allSelectors[i]))
                    )
                );
            }
        }
    }

    function test_diamondConfig_returnsCutsAndInterfaces() public {
        pkg = _deployPkg();

        IDiamondFactoryPackage.DiamondConfig memory config = pkg.diamondConfig();

        assertEq(config.facetCuts.length, 5, "Should have 5 cuts");
        assertEq(config.interfaces.length, 11, "Should have 11 interfaces");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Salt Calculation Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_calcSalt_deterministicForSameTokens() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory args1 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertEq(salt1, salt2, "Same tokens should produce same salt");
    }

    function test_calcSalt_differentForDifferentTokens() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs1 = _createTwoTokenConfig();

        TokenConfig[] memory configs2 = new TokenConfig[](2);
        configs2[0] = _createTokenConfig(address(tokenC), TokenType.STANDARD, address(0), false);
        configs2[1] = _createTokenConfig(address(tokenD), TokenType.STANDARD, address(0), false);

        bytes memory args1 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs2,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertTrue(salt1 != salt2, "Different tokens should produce different salt");
    }

    function test_calcSalt_sortsTokensBeforeHashing() public {
        pkg = _deployPkg();

        // Create configs in different orders
        TokenConfig[] memory configs1 = new TokenConfig[](2);
        configs1[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);
        configs1[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);

        TokenConfig[] memory configs2 = new TokenConfig[](2);
        configs2[0] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);
        configs2[1] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);

        bytes memory args1 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs2,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        // After sorting, both should produce the same salt
        assertEq(salt1, salt2, "Token order should not affect salt after sorting");
    }

    function test_calcSalt_orderIndependent_withHeterogeneousTokenConfigFields() public {
        pkg = _deployPkg();

        // Same two token addresses, but with distinct per-token fields.
        // This would have produced *different* salts before the TokenConfigUtils._sort() fix,
        // because only token addresses were swapped and the other fields stayed in place.
        TokenConfig[] memory configsAB = new TokenConfig[](2);
        configsAB[0] = _createTokenConfig(address(tokenA), TokenType.WITH_RATE, address(0x1111), true);
        configsAB[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0x2222), false);

        TokenConfig[] memory configsBA = new TokenConfig[](2);
        configsBA[0] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0x2222), false);
        configsBA[1] = _createTokenConfig(address(tokenA), TokenType.WITH_RATE, address(0x1111), true);

        bytes memory argsAB = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configsAB,
                hooksContract: address(0)
            })
        );

        bytes memory argsBA = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configsBA,
                hooksContract: address(0)
            })
        );

        assertEq(pkg.calcSalt(argsAB), pkg.calcSalt(argsBA), "Salt should be order-independent even with distinct fields");
    }

    function test_calcSalt_revertsForWrongTokenCount() public {
        pkg = _deployPkg();

        // Create 3-token config (invalid for constant product pool)
        TokenConfig[] memory configs = new TokenConfig[](3);
        configs[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);
        configs[2] = _createTokenConfig(address(tokenC), TokenType.STANDARD, address(0), false);

        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                BalancerV3ConstantProductPoolDFPkg.InvalidTokensLength.selector,
                2, // max
                2, // min
                3  // provided
            )
        );
        pkg.calcSalt(args);
    }

    function test_calcSalt_revertsForSingleToken() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs = new TokenConfig[](1);
        configs[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);

        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                BalancerV3ConstantProductPoolDFPkg.InvalidTokensLength.selector,
                2, // max
                2, // min
                1  // provided
            )
        );
        pkg.calcSalt(args);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Process Args Tests                               */
    /* -------------------------------------------------------------------------- */

    function test_processArgs_sortsTokens() public {
        pkg = _deployPkg();

        // Create configs in reverse order (B, A)
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(address(tokenB), TokenType.WITH_RATE, address(0x123), true);
        configs[1] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);

        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        bytes memory processed = pkg.processArgs(args);

        IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs memory decodedArgs =
            abi.decode(processed, (IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs));

        // First token should be A (lower address)
        assertTrue(
            address(decodedArgs.tokenConfigs[0].token) < address(decodedArgs.tokenConfigs[1].token),
            "Tokens should be sorted by address"
        );
    }

    function test_processArgs_sortsAndPreservesAlignment() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0xBEEF), false);
        configs[1] = _createTokenConfig(address(tokenA), TokenType.WITH_RATE, address(0xCAFE), true);

        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs memory decodedArgs = abi.decode(
            pkg.processArgs(args),
            (IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs)
        );

        // After sorting, whichever token address comes first must keep *its* original fields.
        address first = address(decodedArgs.tokenConfigs[0].token);
        address second = address(decodedArgs.tokenConfigs[1].token);

        assertTrue(first < second, "Tokens should be sorted by address");

        if (first == address(tokenA)) {
            assertTrue(decodedArgs.tokenConfigs[0].tokenType == TokenType.WITH_RATE);
            assertEq(address(decodedArgs.tokenConfigs[0].rateProvider), address(0xCAFE));
            assertTrue(decodedArgs.tokenConfigs[0].paysYieldFees);
        } else {
            assertEq(first, address(tokenB));
            assertTrue(decodedArgs.tokenConfigs[0].tokenType == TokenType.STANDARD);
            assertEq(address(decodedArgs.tokenConfigs[0].rateProvider), address(0xBEEF));
            assertFalse(decodedArgs.tokenConfigs[0].paysYieldFees);
        }

        if (second == address(tokenA)) {
            assertTrue(decodedArgs.tokenConfigs[1].tokenType == TokenType.WITH_RATE);
            assertEq(address(decodedArgs.tokenConfigs[1].rateProvider), address(0xCAFE));
            assertTrue(decodedArgs.tokenConfigs[1].paysYieldFees);
        } else {
            assertEq(second, address(tokenB));
            assertTrue(decodedArgs.tokenConfigs[1].tokenType == TokenType.STANDARD);
            assertEq(address(decodedArgs.tokenConfigs[1].rateProvider), address(0xBEEF));
            assertFalse(decodedArgs.tokenConfigs[1].paysYieldFees);
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                           Update/PostDeploy Tests                          */
    /* -------------------------------------------------------------------------- */

    function test_updatePkg_returnsTrue() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs = _createTwoTokenConfig();
        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        bool result = pkg.updatePkg(makeAddr("proxy"), args);
        assertTrue(result, "updatePkg should return true");
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

    function testFuzz_calcSalt_anyValidTokens(address token1, address token2) public {
        vm.assume(token1 != address(0) && token2 != address(0));
        vm.assume(token1 != token2);

        // Mock the token metadata calls
        vm.mockCall(token1, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token1"));
        vm.mockCall(token2, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token2"));

        pkg = _deployPkg();

        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(token1, TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(token2, TokenType.STANDARD, address(0), false);

        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        bytes32 salt = pkg.calcSalt(args);
        assertTrue(salt != bytes32(0), "Salt should not be zero");
    }

    function testFuzz_calcSalt_orderIndependence(address token1, address token2) public {
        vm.assume(token1 != address(0) && token2 != address(0));
        vm.assume(token1 != token2);

        vm.mockCall(token1, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token1"));
        vm.mockCall(token2, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token2"));

        pkg = _deployPkg();

        TokenConfig[] memory configs1 = new TokenConfig[](2);
        configs1[0] = _createTokenConfig(token1, TokenType.STANDARD, address(0), false);
        configs1[1] = _createTokenConfig(token2, TokenType.STANDARD, address(0), false);

        TokenConfig[] memory configs2 = new TokenConfig[](2);
        configs2[0] = _createTokenConfig(token2, TokenType.STANDARD, address(0), false);
        configs2[1] = _createTokenConfig(token1, TokenType.STANDARD, address(0), false);

        bytes memory args1 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs2,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertEq(salt1, salt2, "Salt should be order-independent");
    }

    /* -------------------------------------------------------------------------- */
    /*                Heterogeneous TokenConfig Order-Independence Tests          */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Test that calcSalt produces same result with fully distinct per-token configs
     * @dev Tests all permutations of token ordering to ensure true order-independence
     *      with heterogeneous fields. This would have failed before the TokenConfigUtils._sort()
     *      fix if only token addresses were swapped (not full structs).
     */
    function test_calcSalt_orderIndependent_allPermutations_heterogeneousConfigs() public {
        pkg = _deployPkg();

        // Define completely distinct configs for each token
        // Token A: WITH_RATE, has rateProvider, pays yield fees
        // Token B: STANDARD, different rateProvider, no yield fees
        address rateProviderA = makeAddr("rateProviderA");
        address rateProviderB = makeAddr("rateProviderB");

        // Create both permutations (A,B) and (B,A)
        TokenConfig[] memory configsAB = new TokenConfig[](2);
        configsAB[0] = _createTokenConfig(address(tokenA), TokenType.WITH_RATE, rateProviderA, true);
        configsAB[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, rateProviderB, false);

        TokenConfig[] memory configsBA = new TokenConfig[](2);
        configsBA[0] = _createTokenConfig(address(tokenB), TokenType.STANDARD, rateProviderB, false);
        configsBA[1] = _createTokenConfig(address(tokenA), TokenType.WITH_RATE, rateProviderA, true);

        bytes memory argsAB = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configsAB,
                hooksContract: address(0)
            })
        );

        bytes memory argsBA = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configsBA,
                hooksContract: address(0)
            })
        );

        bytes32 saltAB = pkg.calcSalt(argsAB);
        bytes32 saltBA = pkg.calcSalt(argsBA);

        assertEq(saltAB, saltBA, "calcSalt must be order-independent with heterogeneous configs");
    }

    /**
     * @notice Test calcSalt with maximum config diversity (all fields differ)
     * @dev Covers the case where tokenType, rateProvider, and paysYieldFees are all distinct
     */
    function test_calcSalt_orderIndependent_maxDiversity() public {
        pkg = _deployPkg();

        // Use completely different addresses for rate providers
        address rateProviderHigh = address(0xffFfFFfFfFFfFfffFFFFfffFFffFFFfFfFFf1111);
        address rateProviderLow = address(0x0000000000000000000000000000000000001111);

        // Token with high address has one set of params
        // Token with low address has completely opposite params
        TokenConfig[] memory configs1 = new TokenConfig[](2);
        configs1[0] = _createTokenConfig(address(tokenA), TokenType.WITH_RATE, rateProviderHigh, true);
        configs1[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, rateProviderLow, false);

        TokenConfig[] memory configs2 = new TokenConfig[](2);
        configs2[0] = _createTokenConfig(address(tokenB), TokenType.STANDARD, rateProviderLow, false);
        configs2[1] = _createTokenConfig(address(tokenA), TokenType.WITH_RATE, rateProviderHigh, true);

        bytes memory args1 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs2,
                hooksContract: address(0)
            })
        );

        assertEq(pkg.calcSalt(args1), pkg.calcSalt(args2), "Salt must match with max diversity configs");
    }

    /**
     * @notice Test that DIFFERENT heterogeneous configs produce DIFFERENT salts
     * @dev Ensures the salt actually incorporates all TokenConfig fields, not just addresses
     */
    function test_calcSalt_differentConfigs_produceDifferentSalts() public {
        pkg = _deployPkg();

        // Same tokens, but different configs for tokenA
        TokenConfig[] memory configs1 = new TokenConfig[](2);
        configs1[0] = _createTokenConfig(address(tokenA), TokenType.WITH_RATE, address(0x1111), true);
        configs1[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);

        TokenConfig[] memory configs2 = new TokenConfig[](2);
        configs2[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false); // Different!
        configs2[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);

        bytes memory args1 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs2,
                hooksContract: address(0)
            })
        );

        assertTrue(
            pkg.calcSalt(args1) != pkg.calcSalt(args2),
            "Different tokenType configs should produce different salts"
        );
    }

    /**
     * @notice Fuzz test for order-independence with heterogeneous configs
     * @dev Randomly assigns tokenType, rateProvider, and paysYieldFees to each token
     */
    function testFuzz_calcSalt_orderIndependence_heterogeneous(
        address token1,
        address token2,
        uint8 tokenType1Seed,
        uint8 tokenType2Seed,
        address rateProvider1,
        address rateProvider2,
        bool paysYieldFees1,
        bool paysYieldFees2
    ) public {
        vm.assume(token1 != address(0) && token2 != address(0));
        vm.assume(token1 != token2);

        vm.mockCall(token1, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token1"));
        vm.mockCall(token2, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token2"));

        pkg = _deployPkg();

        // Map seeds to TokenType (STANDARD=0, WITH_RATE=1)
        TokenType type1 = tokenType1Seed % 2 == 0 ? TokenType.STANDARD : TokenType.WITH_RATE;
        TokenType type2 = tokenType2Seed % 2 == 0 ? TokenType.STANDARD : TokenType.WITH_RATE;

        // Create configs in order (1, 2)
        TokenConfig[] memory configs1 = new TokenConfig[](2);
        configs1[0] = _createTokenConfig(token1, type1, rateProvider1, paysYieldFees1);
        configs1[1] = _createTokenConfig(token2, type2, rateProvider2, paysYieldFees2);

        // Create configs in reversed order (2, 1)
        TokenConfig[] memory configs2 = new TokenConfig[](2);
        configs2[0] = _createTokenConfig(token2, type2, rateProvider2, paysYieldFees2);
        configs2[1] = _createTokenConfig(token1, type1, rateProvider1, paysYieldFees1);

        bytes memory args1 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs2,
                hooksContract: address(0)
            })
        );

        assertEq(
            pkg.calcSalt(args1),
            pkg.calcSalt(args2),
            "Salt must be order-independent with any heterogeneous config combination"
        );
    }

    /* -------------------------------------------------------------------------- */
    /*                  Heterogeneous ProcessArgs Alignment Tests                 */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Test processArgs preserves field alignment with known token addresses
     * @dev Uses tokens created in setUp() which have deterministic relative ordering
     */
    function test_processArgs_heterogeneous_preservesAlignment_knownTokens() public {
        pkg = _deployPkg();

        // Get actual token addresses to understand their sort order
        address addrA = address(tokenA);
        address addrB = address(tokenB);

        // Create configs in reverse sorted order to force a swap
        TokenConfig[] memory configs;
        address expectedFirst;
        address expectedSecond;

        if (addrA < addrB) {
            // A < B, so pass in (B, A) to force swap
            configs = new TokenConfig[](2);
            configs[0] = _createTokenConfig(addrB, TokenType.STANDARD, address(0xBBBB), false);
            configs[1] = _createTokenConfig(addrA, TokenType.WITH_RATE, address(0xAAAA), true);
            expectedFirst = addrA;
            expectedSecond = addrB;
        } else {
            // B < A, so pass in (A, B) to force swap
            configs = new TokenConfig[](2);
            configs[0] = _createTokenConfig(addrA, TokenType.WITH_RATE, address(0xAAAA), true);
            configs[1] = _createTokenConfig(addrB, TokenType.STANDARD, address(0xBBBB), false);
            expectedFirst = addrB;
            expectedSecond = addrA;
        }

        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs memory decoded = abi.decode(
            pkg.processArgs(args),
            (IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs)
        );

        // Verify tokens are sorted
        assertEq(address(decoded.tokenConfigs[0].token), expectedFirst, "First token incorrect");
        assertEq(address(decoded.tokenConfigs[1].token), expectedSecond, "Second token incorrect");

        // Verify fields are correctly aligned to their tokens
        if (expectedFirst == addrA) {
            // Token A should have WITH_RATE, 0xAAAA, true
            assertTrue(decoded.tokenConfigs[0].tokenType == TokenType.WITH_RATE, "TokenA type mismatch");
            assertEq(address(decoded.tokenConfigs[0].rateProvider), address(0xAAAA), "TokenA rateProvider mismatch");
            assertTrue(decoded.tokenConfigs[0].paysYieldFees, "TokenA paysYieldFees mismatch");
            // Token B should have STANDARD, 0xBBBB, false
            assertTrue(decoded.tokenConfigs[1].tokenType == TokenType.STANDARD, "TokenB type mismatch");
            assertEq(address(decoded.tokenConfigs[1].rateProvider), address(0xBBBB), "TokenB rateProvider mismatch");
            assertFalse(decoded.tokenConfigs[1].paysYieldFees, "TokenB paysYieldFees mismatch");
        } else {
            // Token B is first
            assertTrue(decoded.tokenConfigs[0].tokenType == TokenType.STANDARD, "TokenB type mismatch");
            assertEq(address(decoded.tokenConfigs[0].rateProvider), address(0xBBBB), "TokenB rateProvider mismatch");
            assertFalse(decoded.tokenConfigs[0].paysYieldFees, "TokenB paysYieldFees mismatch");
            // Token A is second
            assertTrue(decoded.tokenConfigs[1].tokenType == TokenType.WITH_RATE, "TokenA type mismatch");
            assertEq(address(decoded.tokenConfigs[1].rateProvider), address(0xAAAA), "TokenA rateProvider mismatch");
            assertTrue(decoded.tokenConfigs[1].paysYieldFees, "TokenA paysYieldFees mismatch");
        }
    }

    /**
     * @notice Fuzz test for processArgs alignment preservation
     * @dev Verifies that after sorting, each token's config fields stay with it
     */
    function testFuzz_processArgs_preservesAlignment_heterogeneous(
        address token1,
        address token2,
        uint8 tokenType1Seed,
        uint8 tokenType2Seed,
        address rateProvider1,
        address rateProvider2,
        bool paysYieldFees1,
        bool paysYieldFees2
    ) public {
        vm.assume(token1 != address(0) && token2 != address(0));
        vm.assume(token1 != token2);

        vm.mockCall(token1, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token1"));
        vm.mockCall(token2, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token2"));

        pkg = _deployPkg();

        TokenType type1 = tokenType1Seed % 2 == 0 ? TokenType.STANDARD : TokenType.WITH_RATE;
        TokenType type2 = tokenType2Seed % 2 == 0 ? TokenType.STANDARD : TokenType.WITH_RATE;

        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(token1, type1, rateProvider1, paysYieldFees1);
        configs[1] = _createTokenConfig(token2, type2, rateProvider2, paysYieldFees2);

        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs memory decoded = abi.decode(
            pkg.processArgs(args),
            (IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs)
        );

        // Verify sorted order
        assertTrue(
            address(decoded.tokenConfigs[0].token) < address(decoded.tokenConfigs[1].token),
            "Tokens must be sorted"
        );

        // Verify alignment: find which original config corresponds to each position
        for (uint256 i = 0; i < 2; i++) {
            address sortedToken = address(decoded.tokenConfigs[i].token);

            if (sortedToken == token1) {
                // This position should have token1's config
                assertTrue(decoded.tokenConfigs[i].tokenType == type1, "type1 alignment broken");
                assertEq(address(decoded.tokenConfigs[i].rateProvider), rateProvider1, "rateProvider1 alignment broken");
                assertEq(decoded.tokenConfigs[i].paysYieldFees, paysYieldFees1, "paysYieldFees1 alignment broken");
            } else {
                // This position should have token2's config
                assertEq(sortedToken, token2, "Unknown token in sorted configs");
                assertTrue(decoded.tokenConfigs[i].tokenType == type2, "type2 alignment broken");
                assertEq(address(decoded.tokenConfigs[i].rateProvider), rateProvider2, "rateProvider2 alignment broken");
                assertEq(decoded.tokenConfigs[i].paysYieldFees, paysYieldFees2, "paysYieldFees2 alignment broken");
            }
        }
    }

    /**
     * @notice Test that processArgs and calcSalt are consistent
     * @dev Verifies that calcSalt(args) == calcSalt(processArgs(args)) for heterogeneous configs
     */
    function testFuzz_processArgs_calcSalt_consistent(
        address token1,
        address token2,
        uint8 tokenType1Seed,
        address rateProvider1,
        bool paysYieldFees1
    ) public {
        vm.assume(token1 != address(0) && token2 != address(0));
        vm.assume(token1 != token2);

        vm.mockCall(token1, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token1"));
        vm.mockCall(token2, abi.encodeWithSelector(IERC20Metadata.name.selector), abi.encode("Token2"));

        pkg = _deployPkg();

        TokenType type1 = tokenType1Seed % 2 == 0 ? TokenType.STANDARD : TokenType.WITH_RATE;

        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(token1, type1, rateProvider1, paysYieldFees1);
        configs[1] = _createTokenConfig(token2, TokenType.STANDARD, address(0), false);

        bytes memory args = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        bytes32 saltBefore = pkg.calcSalt(args);
        bytes memory processedArgs = pkg.processArgs(args);
        bytes32 saltAfter = pkg.calcSalt(processedArgs);

        // calcSalt should be idempotent (sorting happens internally)
        assertEq(saltBefore, saltAfter, "calcSalt must be consistent before/after processArgs");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Helper Functions                                  */
    /* -------------------------------------------------------------------------- */

    function _deployPkg() internal returns (BalancerV3ConstantProductPoolDFPkg) {
        return new BalancerV3ConstantProductPoolDFPkg(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                betterBalancerV3PoolTokenFacet: IFacet(address(poolTokenFacet)),
                defaultPoolInfoFacet: IFacet(address(poolInfoFacet)),
                standardSwapFeePercentageBoundsFacet: IFacet(address(poolInfoFacet)), // Reuse for test
                unbalancedLiquidityInvariantRatioBoundsFacet: IFacet(address(poolInfoFacet)), // Reuse for test
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                balancerV3ConstProdPoolFacet: IFacet(address(constProdFacet)),
                balancerV3Vault: IVault(mockVault),
                diamondFactory: IDiamondPackageCallBackFactory(mockDiamondFactory),
                poolFeeManager: poolManager
            })
        );
    }

    function _createTwoTokenConfig() internal view returns (TokenConfig[] memory) {
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);
        return configs;
    }

    function _createTokenConfig(
        address token,
        TokenType tokenType,
        address rateProvider,
        bool paysYieldFees
    ) internal pure returns (TokenConfig memory) {
        return TokenConfig({
            token: IERC20(token),
            tokenType: tokenType,
            rateProvider: IRateProvider(rateProvider),
            paysYieldFees: paysYieldFees
        });
    }
}
