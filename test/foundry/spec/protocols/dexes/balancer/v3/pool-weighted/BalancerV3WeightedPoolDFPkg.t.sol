// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";
import {TokenConfig, TokenType} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {IBasePool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePool.sol";
import {IPoolInfo} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-utils/IPoolInfo.sol";
import {FixedPoint} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
import {IBalancerV3WeightedPool} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerV3WeightedPool.sol";
import {
    BalancerV3WeightedPoolDFPkg,
    IBalancerV3WeightedPoolDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-weighted/BalancerV3WeightedPoolDFPkg.sol";

// Mock ERC20 for testing
contract MockERC20 is IERC20, IERC20Events, IERC20Metadata {
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
 * @title BalancerV3WeightedPoolDFPkg_Test
 * @notice Tests for BalancerV3WeightedPoolDFPkg Diamond Factory Package.
 * @dev Tests verify:
 *  - Full diamond deployment via DFPkg
 *  - Token/weight ordering alignment after sorting (Finding 1 regression test)
 *  - Max token count validation (Finding 2)
 *  - Package metadata correctness
 *  - Salt calculation determinism
 */
contract BalancerV3WeightedPoolDFPkg_Test is Test {
    BalancerV3WeightedPoolDFPkg internal pkg;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;
    MockERC20 internal tokenC;
    MockERC20 internal tokenD;

    // Mock facets with unique selectors
    MockFacet internal vaultAwareFacet;
    MockFacet internal poolTokenFacet;
    MockFacet internal poolInfoFacet;
    MockFacet internal authFacet;
    MockFacet internal weightedPoolFacet;

    address internal mockVault;
    address internal mockDiamondFactory;
    address internal poolManager;

    uint256 constant WEIGHT_80 = 0.8e18;
    uint256 constant WEIGHT_20 = 0.2e18;
    uint256 constant WEIGHT_50 = 0.5e18;

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

        bytes4[] memory weightedPoolFuncs = new bytes4[](4);
        weightedPoolFuncs[0] = IBasePool.computeInvariant.selector;
        weightedPoolFuncs[1] = IBasePool.computeBalance.selector;
        weightedPoolFuncs[2] = IBasePool.onSwap.selector;
        weightedPoolFuncs[3] = IBalancerV3WeightedPool.getNormalizedWeights.selector;
        bytes4[] memory weightedPoolInterfaces = new bytes4[](2);
        weightedPoolInterfaces[0] = type(IBasePool).interfaceId;
        weightedPoolInterfaces[1] = type(IBalancerV3WeightedPool).interfaceId;
        weightedPoolFacet = new MockFacet("WeightedPoolFacet", weightedPoolFuncs, weightedPoolInterfaces);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Package Metadata Tests                           */
    /* -------------------------------------------------------------------------- */

    function test_packageName_returnsCorrectName() public {
        pkg = _deployPkg();

        string memory name = pkg.packageName();
        assertEq(name, "BalancerV3WeightedPoolDFPkg", "Package name should match");
    }

    function test_packageMetadata_returnsAllData() public {
        pkg = _deployPkg();

        (string memory name, bytes4[] memory interfaces, address[] memory facets) = pkg.packageMetadata();

        assertEq(name, "BalancerV3WeightedPoolDFPkg", "Name should match");
        assertEq(interfaces.length, 12, "Should have 12 interfaces");
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
        assertEq(facets[4], address(weightedPoolFacet), "Fifth facet should be weighted pool");
    }

    /* -------------------------------------------------------------------------- */
    /*                            Facet Cuts Tests                                */
    /* -------------------------------------------------------------------------- */

    function test_facetCuts_returnsFiveCuts() public {
        pkg = _deployPkg();

        IDiamond.FacetCut[] memory cuts = pkg.facetCuts();

        assertEq(cuts.length, 5, "Should return 5 facet cuts");
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

    /* -------------------------------------------------------------------------- */
    /*                Token/Weight Ordering Tests (Finding 1 & 4 regression)       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verifies that unsorted token inputs have their weights reordered to match.
     * @dev This is a critical regression test for Finding 1 (Critical bug fix).
     */
    function test_processArgs_sortsWeightsAlongsideTokens() public {
        pkg = _deployPkg();

        // Create configs in reverse order: tokenB (20%), tokenA (80%)
        // After sorting, tokenA should come first, so weights should be [80%, 20%]
        TokenConfig[] memory configs = new TokenConfig[](2);

        // Ensure tokenB address > tokenA address for test validity
        address addrA = address(tokenA);
        address addrB = address(tokenB);

        // If tokenA > tokenB, swap the test setup
        if (addrA > addrB) {
            configs[0] = _createTokenConfig(addrA, TokenType.STANDARD, address(0), false);
            configs[1] = _createTokenConfig(addrB, TokenType.STANDARD, address(0), false);
        } else {
            configs[0] = _createTokenConfig(addrB, TokenType.STANDARD, address(0), false);
            configs[1] = _createTokenConfig(addrA, TokenType.STANDARD, address(0), false);
        }

        uint256[] memory weights = new uint256[](2);
        weights[0] = WEIGHT_20; // 20% for first token (which will be sorted to second position)
        weights[1] = WEIGHT_80; // 80% for second token (which will be sorted to first position)

        bytes memory args = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights,
                hooksContract: address(0)
            })
        );

        bytes memory processed = pkg.processArgs(args);

        IBalancerV3WeightedPoolDFPkg.PkgArgs memory decodedArgs =
            abi.decode(processed, (IBalancerV3WeightedPoolDFPkg.PkgArgs));

        // Verify tokens are sorted
        assertTrue(
            address(decodedArgs.tokenConfigs[0].token) < address(decodedArgs.tokenConfigs[1].token),
            "Tokens should be sorted by address"
        );

        // CRITICAL: Verify weights were reordered to match sorted tokens
        // The 80% weight should now be at index 0 (with the lower address token)
        // The 20% weight should now be at index 1 (with the higher address token)
        assertEq(decodedArgs.normalizedWeights[0], WEIGHT_80, "First weight should be 80% after sorting");
        assertEq(decodedArgs.normalizedWeights[1], WEIGHT_20, "Second weight should be 20% after sorting");
    }

    function test_calcSalt_weightsOrderIndependent() public {
        pkg = _deployPkg();

        address addrA = address(tokenA);
        address addrB = address(tokenB);

        // Determine which is lower/higher
        address lower = addrA < addrB ? addrA : addrB;
        address higher = addrA < addrB ? addrB : addrA;

        // Config 1: lower first with 80%, higher second with 20%
        TokenConfig[] memory configs1 = new TokenConfig[](2);
        configs1[0] = _createTokenConfig(lower, TokenType.STANDARD, address(0), false);
        configs1[1] = _createTokenConfig(higher, TokenType.STANDARD, address(0), false);

        uint256[] memory weights1 = new uint256[](2);
        weights1[0] = WEIGHT_80;
        weights1[1] = WEIGHT_20;

        // Config 2: higher first with 20%, lower second with 80% (reversed)
        TokenConfig[] memory configs2 = new TokenConfig[](2);
        configs2[0] = _createTokenConfig(higher, TokenType.STANDARD, address(0), false);
        configs2[1] = _createTokenConfig(lower, TokenType.STANDARD, address(0), false);

        uint256[] memory weights2 = new uint256[](2);
        weights2[0] = WEIGHT_20;
        weights2[1] = WEIGHT_80;

        bytes memory args1 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs1,
                normalizedWeights: weights1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs2,
                normalizedWeights: weights2,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        // After sorting both token+weight pairs, they should produce the same salt
        assertEq(salt1, salt2, "Salt should be order-independent when weights follow tokens");
    }

    function test_processArgs_threeTokenPool_weightsAligned() public {
        pkg = _deployPkg();

        // Create a 3-token pool with unsorted inputs
        address[] memory addrs = new address[](3);
        addrs[0] = address(tokenA);
        addrs[1] = address(tokenB);
        addrs[2] = address(tokenC);

        // Sort addresses to know expected order
        for (uint256 i = 0; i < 3; i++) {
            for (uint256 j = i + 1; j < 3; j++) {
                if (addrs[i] > addrs[j]) {
                    address temp = addrs[i];
                    addrs[i] = addrs[j];
                    addrs[j] = temp;
                }
            }
        }

        // Create input with reversed order and distinct weights
        TokenConfig[] memory configs = new TokenConfig[](3);
        configs[0] = _createTokenConfig(addrs[2], TokenType.STANDARD, address(0), false); // highest addr
        configs[1] = _createTokenConfig(addrs[1], TokenType.STANDARD, address(0), false); // middle addr
        configs[2] = _createTokenConfig(addrs[0], TokenType.STANDARD, address(0), false); // lowest addr

        // Weights: 10%, 30%, 60% - sum to 100%
        uint256[] memory weights = new uint256[](3);
        weights[0] = 0.1e18;  // for highest addr
        weights[1] = 0.3e18;  // for middle addr
        weights[2] = 0.6e18;  // for lowest addr

        bytes memory args = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights,
                hooksContract: address(0)
            })
        );

        bytes memory processed = pkg.processArgs(args);

        IBalancerV3WeightedPoolDFPkg.PkgArgs memory decodedArgs =
            abi.decode(processed, (IBalancerV3WeightedPoolDFPkg.PkgArgs));

        // Verify tokens are sorted (ascending by address)
        assertTrue(
            address(decodedArgs.tokenConfigs[0].token) < address(decodedArgs.tokenConfigs[1].token),
            "Token 0 < Token 1"
        );
        assertTrue(
            address(decodedArgs.tokenConfigs[1].token) < address(decodedArgs.tokenConfigs[2].token),
            "Token 1 < Token 2"
        );

        // After sorting: lowest addr first (with 60%), middle addr second (with 30%), highest addr third (with 10%)
        assertEq(decodedArgs.normalizedWeights[0], 0.6e18, "Lowest addr should have 60% weight");
        assertEq(decodedArgs.normalizedWeights[1], 0.3e18, "Middle addr should have 30% weight");
        assertEq(decodedArgs.normalizedWeights[2], 0.1e18, "Highest addr should have 10% weight");
    }

    /* -------------------------------------------------------------------------- */
    /*                       Token Count Validation Tests (Finding 2)              */
    /* -------------------------------------------------------------------------- */

    function test_calcSalt_revertsForSingleToken() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs = new TokenConfig[](1);
        configs[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);

        uint256[] memory weights = new uint256[](1);
        weights[0] = FixedPoint.ONE;

        bytes memory args = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights,
                hooksContract: address(0)
            })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                BalancerV3WeightedPoolDFPkg.InvalidTokensLength.selector,
                8, // max
                2, // min
                1  // provided
            )
        );
        pkg.calcSalt(args);
    }

    function test_calcSalt_revertsForTooManyTokens() public {
        pkg = _deployPkg();

        // Create 9-token config (exceeds max of 8)
        TokenConfig[] memory configs = new TokenConfig[](9);
        uint256[] memory weights = new uint256[](9);

        for (uint256 i = 0; i < 9; i++) {
            configs[i] = _createTokenConfig(address(uint160(i + 1)), TokenType.STANDARD, address(0), false);
            weights[i] = FixedPoint.ONE / 9;
        }
        // Adjust last weight to ensure sum is exactly ONE
        weights[8] = FixedPoint.ONE - (FixedPoint.ONE / 9 * 8);

        bytes memory args = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights,
                hooksContract: address(0)
            })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                BalancerV3WeightedPoolDFPkg.InvalidTokensLength.selector,
                8, // max
                2, // min
                9  // provided
            )
        );
        pkg.calcSalt(args);
    }

    function test_calcSalt_acceptsEightTokens() public {
        pkg = _deployPkg();

        // Create 8-token config (max allowed)
        TokenConfig[] memory configs = new TokenConfig[](8);
        uint256[] memory weights = new uint256[](8);

        for (uint256 i = 0; i < 8; i++) {
            configs[i] = _createTokenConfig(address(uint160(i + 100)), TokenType.STANDARD, address(0), false);
            weights[i] = FixedPoint.ONE / 8;
        }
        // Adjust last weight to ensure sum is exactly ONE
        weights[7] = FixedPoint.ONE - (FixedPoint.ONE / 8 * 7);

        bytes memory args = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights,
                hooksContract: address(0)
            })
        );

        // Should not revert
        bytes32 salt = pkg.calcSalt(args);
        assertTrue(salt != bytes32(0), "Salt should not be zero for valid 8-token config");
    }

    function test_calcSalt_revertsForWeightsTokensMismatch() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);

        // Only 1 weight for 2 tokens
        uint256[] memory weights = new uint256[](1);
        weights[0] = FixedPoint.ONE;

        bytes memory args = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights,
                hooksContract: address(0)
            })
        );

        vm.expectRevert(
            abi.encodeWithSelector(
                BalancerV3WeightedPoolDFPkg.WeightsTokensMismatch.selector,
                2, // tokens
                1  // weights
            )
        );
        pkg.calcSalt(args);
    }

    /* -------------------------------------------------------------------------- */
    /*                          Salt Calculation Tests                             */
    /* -------------------------------------------------------------------------- */

    function test_calcSalt_deterministicForSameInputs() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs = _createTwoTokenConfig();
        uint256[] memory weights = _create8020Weights();

        bytes memory args1 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertEq(salt1, salt2, "Same inputs should produce same salt");
    }

    function test_calcSalt_differentForDifferentTokens() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs1 = _createTwoTokenConfig();
        uint256[] memory weights1 = _create8020Weights();

        TokenConfig[] memory configs2 = new TokenConfig[](2);
        configs2[0] = _createTokenConfig(address(tokenC), TokenType.STANDARD, address(0), false);
        configs2[1] = _createTokenConfig(address(tokenD), TokenType.STANDARD, address(0), false);
        uint256[] memory weights2 = _create8020Weights();

        bytes memory args1 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs1,
                normalizedWeights: weights1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs2,
                normalizedWeights: weights2,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertTrue(salt1 != salt2, "Different tokens should produce different salt");
    }

    function test_calcSalt_differentForDifferentWeights() public {
        pkg = _deployPkg();

        TokenConfig[] memory configs = _createTwoTokenConfig();

        uint256[] memory weights1 = _create8020Weights();
        uint256[] memory weights2 = _create5050Weights();

        bytes memory args1 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights2,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertTrue(salt1 != salt2, "Different weights should produce different salt");
    }

    /* -------------------------------------------------------------------------- */
    /*                               Fuzz Tests                                   */
    /* -------------------------------------------------------------------------- */

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

        // Weights follow tokens: token1 gets 80%, token2 gets 20%
        uint256[] memory weights1 = new uint256[](2);
        weights1[0] = WEIGHT_80;
        weights1[1] = WEIGHT_20;

        // Reversed: token2 first with 20%, token1 second with 80%
        uint256[] memory weights2 = new uint256[](2);
        weights2[0] = WEIGHT_20;
        weights2[1] = WEIGHT_80;

        bytes memory args1 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs1,
                normalizedWeights: weights1,
                hooksContract: address(0)
            })
        );

        bytes memory args2 = abi.encode(
            IBalancerV3WeightedPoolDFPkg.PkgArgs({
                tokenConfigs: configs2,
                normalizedWeights: weights2,
                hooksContract: address(0)
            })
        );

        bytes32 salt1 = pkg.calcSalt(args1);
        bytes32 salt2 = pkg.calcSalt(args2);

        assertEq(salt1, salt2, "Salt should be order-independent when weights follow their tokens");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Helper Functions                                  */
    /* -------------------------------------------------------------------------- */

    function _deployPkg() internal returns (BalancerV3WeightedPoolDFPkg) {
        return new BalancerV3WeightedPoolDFPkg(
            IBalancerV3WeightedPoolDFPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                betterBalancerV3PoolTokenFacet: IFacet(address(poolTokenFacet)),
                defaultPoolInfoFacet: IFacet(address(poolInfoFacet)),
                standardSwapFeePercentageBoundsFacet: IFacet(address(poolInfoFacet)), // Reuse for test
                unbalancedLiquidityInvariantRatioBoundsFacet: IFacet(address(poolInfoFacet)), // Reuse for test
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                balancerV3WeightedPoolFacet: IFacet(address(weightedPoolFacet)),
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

    function _create8020Weights() internal pure returns (uint256[] memory) {
        uint256[] memory weights = new uint256[](2);
        weights[0] = WEIGHT_80;
        weights[1] = WEIGHT_20;
        return weights;
    }

    function _create5050Weights() internal pure returns (uint256[] memory) {
        uint256[] memory weights = new uint256[](2);
        weights[0] = WEIGHT_50;
        weights[1] = WEIGHT_50;
        return weights;
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
