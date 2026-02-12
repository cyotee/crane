// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                OpenZeppelin                                */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {IERC5267} from "@crane/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {TokenConfig, TokenType, PoolRoleAccounts, LiquidityManagement} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {IBasePool} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePool.sol";
import {IPoolInfo} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-utils/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {IUnbalancedLiquidityInvariantRatioBounds} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamond} from "@crane/contracts/interfaces/IDiamond.sol";
import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IERC165} from "@crane/contracts/interfaces/IERC165.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondFactoryPackage} from "@crane/contracts/interfaces/IDiamondFactoryPackage.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IAuthorizer} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IAuthorizer.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {IBalancerPoolToken} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IBalancerPoolToken.sol";
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";

/* -------------------------------------------------------------------------- */
/*                              Real Facet Imports                            */
/* -------------------------------------------------------------------------- */

import {BalancerV3VaultAwareFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol";
import {BalancerV3PoolTokenFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol";
import {BalancerV3AuthenticationFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationFacet.sol";
import {BalancerV3ConstantProductPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                   DFPkg                                    */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3ConstantProductPoolDFPkg,
    IBalancerV3ConstantProductPoolStandardVaultPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-constProd/BalancerV3ConstantProductPoolDFPkg.sol";

/* -------------------------------------------------------------------------- */
/*                              Storage Constants                             */
/* -------------------------------------------------------------------------- */

// Storage slot for BalancerV3VaultAwareRepo
bytes32 constant BALANCER_V3_VAULT_AWARE_SLOT = keccak256("protocols.dexes.balancer.v3.vault.aware");

/* -------------------------------------------------------------------------- */
/*                              Mock Implementations                          */
/* -------------------------------------------------------------------------- */

/**
 * @title MockERC20
 * @notice Simple ERC20 mock for testing pool deployment.
 */
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

/**
 * @title MockPoolInfoFacet
 * @notice Mock facet that simulates IPoolInfo selectors for testing.
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
 * @title MockBalancerV3Vault
 * @notice Minimal mock of Balancer V3 Vault for testing pool registration.
 */
contract MockBalancerV3Vault {
    using PoolRoleAccountsHelper for PoolRoleAccounts;
    using LiquidityManagementHelper for LiquidityManagement;

    event PoolRegistered(
        address indexed pool,
        address indexed poolFactory,
        TokenConfig[] tokenConfig,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        bool protocolFeeExempt,
        address poolHooksContract
    );

    bool public poolRegistered;
    address public lastRegisteredPool;
    address public lastPoolFactory;
    uint256 public lastSwapFeePercentage;
    address public lastPoolHooksContract;

    // Store registered token addresses for verification
    address[] private _registeredTokens;
    mapping(address => TokenType) private _registeredTokenTypes;
    mapping(address => address) private _registeredRateProviders;
    mapping(address => bool) private _registeredPaysYieldFees;

    function registerPool(
        address pool,
        TokenConfig[] memory tokenConfig,
        uint256 swapFeePercentage,
        uint32 pauseWindowEndTime,
        bool protocolFeeExempt,
        PoolRoleAccounts memory, // roleAccounts - ignored
        address poolHooksContract,
        LiquidityManagement memory // liquidityManagement - ignored
    ) external {
        poolRegistered = true;
        lastRegisteredPool = pool;
        lastPoolFactory = msg.sender;
        lastSwapFeePercentage = swapFeePercentage;
        lastPoolHooksContract = poolHooksContract;

        // Store token configs for later verification
        delete _registeredTokens;
        for (uint256 i = 0; i < tokenConfig.length; i++) {
            address token = address(tokenConfig[i].token);
            _registeredTokens.push(token);
            _registeredTokenTypes[token] = tokenConfig[i].tokenType;
            _registeredRateProviders[token] = address(tokenConfig[i].rateProvider);
            _registeredPaysYieldFees[token] = tokenConfig[i].paysYieldFees;
        }

        emit PoolRegistered(
            pool,
            msg.sender,
            tokenConfig,
            swapFeePercentage,
            pauseWindowEndTime,
            protocolFeeExempt,
            poolHooksContract
        );
    }

    function registeredTokenCount() external view returns (uint256) {
        return _registeredTokens.length;
    }

    function registeredTokenAt(uint256 index) external view returns (address) {
        return _registeredTokens[index];
    }

    function registeredTokenType(address token) external view returns (TokenType) {
        return _registeredTokenTypes[token];
    }

    function registeredRateProvider(address token) external view returns (address) {
        return _registeredRateProviders[token];
    }

    function registeredPaysYieldFees(address token) external view returns (bool) {
        return _registeredPaysYieldFees[token];
    }

    address public mockAuthorizer;

    constructor(address authorizer_) {
        mockAuthorizer = authorizer_;
    }

    function getAuthorizer() external view returns (IAuthorizer) {
        return IAuthorizer(mockAuthorizer);
    }
}

// Helper libraries to work around memory struct issues
library PoolRoleAccountsHelper {}
library LiquidityManagementHelper {}

/**
 * @title BalancerV3ConstantProductPoolDFPkg_Integration_Test
 * @notice Integration tests for BalancerV3ConstantProductPoolDFPkg that deploy via the real factory stack.
 * @dev Tests verify:
 *  - US-CRANE-061.1: Full deployment via InitDevService factory stack
 *  - US-CRANE-061.2: initAccount initializes ERC20/EIP712/pool state
 *  - US-CRANE-061.3: postDeploy performs Balancer Vault registration
 */
contract BalancerV3ConstantProductPoolDFPkg_Integration_Test is CraneTest {
    using BetterEfficientHashLib for bytes;

    BalancerV3ConstantProductPoolDFPkg internal pkg;

    // Real facets
    BalancerV3VaultAwareFacet internal vaultAwareFacet;
    BalancerV3PoolTokenFacet internal poolTokenFacet;
    BalancerV3AuthenticationFacet internal authFacet;
    BalancerV3ConstantProductPoolFacet internal constProdFacet;
    MockPoolInfoFacet internal poolInfoFacet;

    // Mock vault
    MockBalancerV3Vault internal mockVault;

    // Mock tokens
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    // Addresses
    address internal poolManager;
    address internal mockAuthorizer;

    function setUp() public override {
        // CraneTest.setUp() initializes create3Factory and diamondFactory via InitDevService
        CraneTest.setUp();

        // Deploy mock vault with mock authorizer
        mockAuthorizer = makeAddr("mockAuthorizer");
        mockVault = new MockBalancerV3Vault(mockAuthorizer);
        vm.label(address(mockVault), "MockBalancerV3Vault");

        // Deploy mock tokens with deterministic addresses for sorting
        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        vm.label(address(tokenA), "TokenA");
        vm.label(address(tokenB), "TokenB");

        // Set pool manager
        poolManager = makeAddr("poolManager");

        // Deploy real facets via Create3Factory for deterministic addresses
        _deployRealFacets();

        // Deploy the DFPkg with real facets and real factory
        _deployPkg();
    }

    function _deployRealFacets() internal {
        // Deploy real facets via Create3Factory for deterministic addresses
        vaultAwareFacet = BalancerV3VaultAwareFacet(address(
            create3Factory.deployFacet(
                type(BalancerV3VaultAwareFacet).creationCode,
                abi.encode(type(BalancerV3VaultAwareFacet).name)._hash()
            )
        ));
        vm.label(address(vaultAwareFacet), type(BalancerV3VaultAwareFacet).name);

        poolTokenFacet = BalancerV3PoolTokenFacet(address(
            create3Factory.deployFacet(
                type(BalancerV3PoolTokenFacet).creationCode,
                abi.encode(type(BalancerV3PoolTokenFacet).name)._hash()
            )
        ));
        vm.label(address(poolTokenFacet), type(BalancerV3PoolTokenFacet).name);

        authFacet = BalancerV3AuthenticationFacet(address(
            create3Factory.deployFacet(
                type(BalancerV3AuthenticationFacet).creationCode,
                abi.encode(type(BalancerV3AuthenticationFacet).name)._hash()
            )
        ));
        vm.label(address(authFacet), type(BalancerV3AuthenticationFacet).name);

        constProdFacet = BalancerV3ConstantProductPoolFacet(address(
            create3Factory.deployFacet(
                type(BalancerV3ConstantProductPoolFacet).creationCode,
                abi.encode(type(BalancerV3ConstantProductPoolFacet).name)._hash()
            )
        ));
        vm.label(address(constProdFacet), type(BalancerV3ConstantProductPoolFacet).name);

        poolInfoFacet = MockPoolInfoFacet(address(
            create3Factory.deployFacet(
                type(MockPoolInfoFacet).creationCode,
                abi.encode(type(MockPoolInfoFacet).name)._hash()
            )
        ));
        vm.label(address(poolInfoFacet), type(MockPoolInfoFacet).name);
    }

    function _deployPkg() internal {
        pkg = BalancerV3ConstantProductPoolDFPkg(address(
            create3Factory.deployPackageWithArgs(
                type(BalancerV3ConstantProductPoolDFPkg).creationCode,
                abi.encode(
                    IBalancerV3ConstantProductPoolStandardVaultPkg.PkgInit({
                        balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                        betterBalancerV3PoolTokenFacet: IFacet(address(poolTokenFacet)),
                        defaultPoolInfoFacet: IFacet(address(poolInfoFacet)),
                        standardSwapFeePercentageBoundsFacet: IFacet(address(poolInfoFacet)),
                        unbalancedLiquidityInvariantRatioBoundsFacet: IFacet(address(poolInfoFacet)),
                        balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                        balancerV3ConstProdPoolFacet: IFacet(address(constProdFacet)),
                        balancerV3Vault: IVault(address(mockVault)),
                        diamondFactory: diamondFactory,
                        poolFeeManager: poolManager
                    })
                ),
                abi.encode(type(BalancerV3ConstantProductPoolDFPkg).name)._hash()
            )
        ));
        vm.label(address(pkg), type(BalancerV3ConstantProductPoolDFPkg).name);
    }

    /* -------------------------------------------------------------------------- */
    /*                US-CRANE-061.1: Full Deployment via Factory Stack           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that the package deploys correctly via the real factory stack.
     * @dev Verifies InitDevService.initEnv() creates working factories.
     */
    function test_factoryStack_isInitialized() public view {
        assertNotEq(address(create3Factory), address(0), "Create3Factory should be initialized");
        assertNotEq(address(diamondFactory), address(0), "DiamondFactory should be initialized");
    }

    /**
     * @notice Tests that a proxy can be deployed via the real DiamondPackageCallBackFactory.
     */
    function test_deployProxy_viaRealFactory() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        // Deploy proxy via the real factory
        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        assertNotEq(proxy, address(0), "Proxy should be deployed");
        vm.label(proxy, "DeployedProxy");
    }

    /**
     * @notice Tests that the deployed proxy has expected facets via DiamondLoupe.
     */
    function test_deployedProxy_hasExpectedFacets() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // Query facets via DiamondLoupe
        IDiamondLoupe loupe = IDiamondLoupe(proxy);
        IDiamondLoupe.Facet[] memory facets = loupe.facets();

        // Should have: ERC165, DiamondLoupe, ERC8109, PostDeployHook (from factory) + 5 from package
        // The exact count depends on the factory's default facets
        assertGt(facets.length, 0, "Proxy should have facets");

        // Verify some expected facet addresses are present
        bool hasVaultAwareFacet = false;
        bool hasConstProdFacet = false;

        for (uint256 i = 0; i < facets.length; i++) {
            if (facets[i].facetAddress == address(vaultAwareFacet)) {
                hasVaultAwareFacet = true;
            }
            if (facets[i].facetAddress == address(constProdFacet)) {
                hasConstProdFacet = true;
            }
        }

        assertTrue(hasVaultAwareFacet, "Proxy should have VaultAwareFacet");
        assertTrue(hasConstProdFacet, "Proxy should have ConstProdFacet");
    }

    /**
     * @notice Tests that the proxy has expected selectors from the DFPkg.
     */
    function test_deployedProxy_hasExpectedSelectors() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);
        IDiamondLoupe loupe = IDiamondLoupe(proxy);

        // Check key selectors are mapped
        address facetForComputeInvariant = loupe.facetAddress(IBasePool.computeInvariant.selector);
        address facetForOnSwap = loupe.facetAddress(IBasePool.onSwap.selector);
        address facetForBalV3Vault = loupe.facetAddress(IBalancerV3VaultAware.balV3Vault.selector);

        assertEq(facetForComputeInvariant, address(constProdFacet), "computeInvariant should map to ConstProdFacet");
        assertEq(facetForOnSwap, address(constProdFacet), "onSwap should map to ConstProdFacet");
        assertEq(facetForBalV3Vault, address(vaultAwareFacet), "balV3Vault should map to VaultAwareFacet");
    }

    /**
     * @notice Tests ERC-165 support on the deployed proxy.
     */
    function test_deployedProxy_supportsERC165() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);
        IERC165 erc165 = IERC165(proxy);

        assertTrue(erc165.supportsInterface(type(IERC165).interfaceId), "Should support ERC165");
        assertTrue(erc165.supportsInterface(type(IDiamondLoupe).interfaceId), "Should support DiamondLoupe");
    }

    /* -------------------------------------------------------------------------- */
    /*                US-CRANE-061.2: Verify initAccount Initialization           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that initAccount initializes ERC20 metadata correctly.
     */
    function test_initAccount_initializesERC20Metadata() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // Query ERC20 metadata via the proxy
        IERC20Metadata token = IERC20Metadata(proxy);

        // Name should be constructed from token names
        string memory expectedNamePrefix = "BV3ConstProd of (";
        string memory actualName = token.name();

        assertTrue(
            bytes(actualName).length > bytes(expectedNamePrefix).length,
            "Name should be non-empty and constructed"
        );

        // Symbol should be "BPT"
        assertEq(token.symbol(), "BPT", "Symbol should be BPT");

        // Decimals should be 18
        assertEq(token.decimals(), 18, "Decimals should be 18");
    }

    /**
     * @notice Tests that initAccount initializes EIP712 domain correctly.
     */
    function test_initAccount_initializesEIP712Domain() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // Query EIP712 domain via IERC5267
        IERC5267 eip5267 = IERC5267(proxy);
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = eip5267.eip712Domain();

        // Verify domain is initialized
        assertTrue(bytes(name).length > 0, "EIP712 name should be set");
        assertEq(version, "1", "EIP712 version should be '1'");
        assertEq(chainId, block.chainid, "Chain ID should match");
        assertEq(verifyingContract, proxy, "Verifying contract should be proxy");
    }

    /**
     * @notice Tests that DOMAIN_SEPARATOR is valid after initialization.
     */
    function test_initAccount_domainSeparatorIsValid() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // Query DOMAIN_SEPARATOR
        bytes32 domainSeparator = IERC20Permit(proxy).DOMAIN_SEPARATOR();

        assertTrue(domainSeparator != bytes32(0), "DOMAIN_SEPARATOR should be non-zero");
    }

    /* -------------------------------------------------------------------------- */
    /*                US-CRANE-061.3: Verify postDeploy Vault Registration        */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that postDeploy is called and triggers vault registration.
     * @dev The mock vault records registration calls for verification.
     */
    function test_postDeploy_triggersVaultRegistration() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        // Deploy should trigger postDeploy which calls vault registration
        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // Verify the mock vault recorded the registration
        assertTrue(mockVault.poolRegistered(), "Pool should be registered with vault");
        assertEq(mockVault.lastRegisteredPool(), proxy, "Registered pool should match proxy");
    }

    /**
     * @notice Tests that updatePkg is called and records token configs.
     */
    function test_updatePkg_recordsTokenConfigs() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        // updatePkg is called before postDeploy
        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // postDeploy retrieves token configs from storage - if registration happened, configs were stored
        assertTrue(mockVault.poolRegistered(), "If postDeploy worked, updatePkg must have stored configs");
    }

    /* -------------------------------------------------------------------------- */
    /*                          Deterministic Address Tests                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that calcAddress produces the correct deployed address.
     */
    function test_calcAddress_matchesDeployedAddress() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        // Predict the address using calcAddress
        address predicted = diamondFactory.calcAddress(pkg, pkgArgs);

        // Deploy
        address actual = diamondFactory.deploy(pkg, pkgArgs);

        assertEq(actual, predicted, "Deployed address should match predicted");
    }

    /**
     * @notice Tests that token order does not affect the deployed address.
     */
    function test_tokenOrderIndependence_produceSameAddress() public {
        // Create configs in different orders
        TokenConfig[] memory configsAB = new TokenConfig[](2);
        configsAB[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);
        configsAB[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);

        TokenConfig[] memory configsBA = new TokenConfig[](2);
        configsBA[0] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);
        configsBA[1] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);

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

        assertEq(saltAB, saltBA, "Salt should be order-independent");
    }

    /* -------------------------------------------------------------------------- */
    /*        US-CRANE-119.1: Vault-Aware Proxy Storage Verification              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that the proxy's vault-aware storage returns the correct vault address.
     * @dev initAccount() now initializes BalancerV3VaultAwareRepo on the proxy,
     *  so balV3Vault() returns the configured vault reference.
     */
    function test_vaultAwareStorage_proxyReturnsCorrectVault() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        IVault proxyVault = IBalancerV3VaultAware(proxy).balV3Vault();
        assertEq(address(proxyVault), address(mockVault), "Proxy balV3Vault() should return the configured vault");
    }

    /**
     * @notice Tests that getVault() on the proxy also returns the correct vault.
     */
    function test_vaultAwareStorage_proxyGetVaultReturnsCorrectVault() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        IVault proxyVault = IBalancerV3VaultAware(proxy).getVault();
        assertEq(address(proxyVault), address(mockVault), "Proxy getVault() should return the configured vault");
    }

    /**
     * @notice Tests that getAuthorizer() on the proxy delegates to the vault and returns correctly.
     */
    function test_vaultAwareStorage_proxyGetAuthorizerReturnsCorrectAuthorizer() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        IAuthorizer authorizer = IBalancerV3VaultAware(proxy).getAuthorizer();
        assertEq(address(authorizer), mockAuthorizer, "Proxy getAuthorizer() should return the vault's authorizer");
    }

    /**
     * @notice Tests that the DFPkg itself holds the correct vault reference.
     * @dev The vault is stored as an immutable on the DFPkg contract.
     */
    function test_vaultAwareStorage_pkgHoldsVaultRef() public view {
        assertEq(address(pkg.BALANCER_V3_VAULT()), address(mockVault), "DFPkg should hold mock vault reference");
    }

    /**
     * @notice Tests that postDeploy successfully uses the vault reference from the DFPkg
     *  to register the pool, confirming the vault-aware storage on the DFPkg is correct.
     */
    function test_vaultAwareStorage_postDeployUsesVaultFromPkg() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // The fact that postDeploy called registerPool on the mock vault proves
        // the vault-aware storage on the DFPkg is correctly initialized
        assertTrue(mockVault.poolRegistered(), "Pool should be registered");
        assertEq(mockVault.lastRegisteredPool(), proxy, "Registered pool should be the proxy");
        // The lastPoolFactory is the DFPkg (caller of registerPool)
        assertEq(mockVault.lastPoolFactory(), address(pkg), "Pool factory should be the DFPkg");
    }

    /* -------------------------------------------------------------------------- */
    /*        US-CRANE-119.2: Pool State Assertions                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that pool swap fee percentage bounds are correctly stored in proxy storage.
     * @dev Reads directly from BalancerV3PoolRepo storage since swap fee bound facets
     *  are not installed on this DFPkg's proxy.
     */
    function test_poolState_swapFeeBoundsInitialized() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // BalancerV3PoolRepo.Storage layout:
        //   slot+0: minimumInvariantRatio
        //   slot+1: maximumInvariantRatio
        //   slot+2: minimumSwapFeePercentage
        //   slot+3: maximumSwapFeePercentage
        bytes32 baseSlot = keccak256("protocols.dexes.balancer.v3.pool.common");
        uint256 minSwapFee = uint256(vm.load(proxy, bytes32(uint256(baseSlot) + 2)));
        uint256 maxSwapFee = uint256(vm.load(proxy, bytes32(uint256(baseSlot) + 3)));

        assertEq(minSwapFee, 1e12, "Min swap fee should be 0.0001% (1e12)");
        assertEq(maxSwapFee, 0.1e18, "Max swap fee should be 10% (0.1e18)");
    }

    /**
     * @notice Tests that pool invariant ratio bounds are correctly stored in proxy storage.
     * @dev Reads directly from BalancerV3PoolRepo storage since invariant ratio bound facets
     *  are not installed on this DFPkg's proxy.
     */
    function test_poolState_invariantRatioBoundsInitialized() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        bytes32 baseSlot = keccak256("protocols.dexes.balancer.v3.pool.common");
        uint256 minRatio = uint256(vm.load(proxy, baseSlot));
        uint256 maxRatio = uint256(vm.load(proxy, bytes32(uint256(baseSlot) + 1)));

        assertEq(minRatio, 70e16, "Min invariant ratio should be 70% (70e16)");
        assertEq(maxRatio, 300e16, "Max invariant ratio should be 300% (300e16)");
    }

    /**
     * @notice Tests that pool token list is correctly stored in proxy storage via BalancerV3PoolRepo.
     * @dev Reads the pool repo token set from the proxy's storage using vm.load to verify
     *  that initAccount() correctly populated the token addresses.
     */
    function test_poolState_tokenListStoredCorrectly() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // Read token count from BalancerV3PoolRepo storage on the proxy.
        // Storage layout: Storage struct has 4 uint256 fields before the AddressSet tokens field.
        // AddressSet struct: { mapping(address => uint256) indexes, address[] values }
        //   - indexes mapping occupies slot offset +4
        //   - values array length at slot offset +5
        //   - values array data at keccak256(abi.encode(offset+5))
        bytes32 baseSlot = keccak256("protocols.dexes.balancer.v3.pool.common");
        bytes32 valuesLenSlot = bytes32(uint256(baseSlot) + 5);
        uint256 tokenCount = uint256(vm.load(proxy, valuesLenSlot));

        assertEq(tokenCount, 2, "Pool should have 2 tokens stored");

        // Read individual token addresses from dynamic array storage
        bytes32 arrayDataSlot = keccak256(abi.encode(valuesLenSlot));
        address storedToken0 = address(uint160(uint256(vm.load(proxy, arrayDataSlot))));
        address storedToken1 = address(uint160(uint256(vm.load(proxy, bytes32(uint256(arrayDataSlot) + 1)))));

        // Determine expected sorted order
        address lower = address(tokenA) < address(tokenB) ? address(tokenA) : address(tokenB);
        address higher = address(tokenA) < address(tokenB) ? address(tokenB) : address(tokenA);

        assertEq(storedToken0, lower, "First stored token should be lower address");
        assertEq(storedToken1, higher, "Second stored token should be higher address");
    }

    /* -------------------------------------------------------------------------- */
    /*                      Token Config Sorting & Recording                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Tests that token configs stored in the factory repo are sorted by address.
     */
    function test_tokenConfigs_areSortedInFactoryRepo() public {
        // Create configs in reverse order (higher address first)
        address lower;
        address higher;
        if (address(tokenA) < address(tokenB)) {
            lower = address(tokenA);
            higher = address(tokenB);
        } else {
            lower = address(tokenB);
            higher = address(tokenA);
        }

        // Deliberately pass higher address first
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(higher, TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(lower, TokenType.STANDARD, address(0), false);

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // Verify configs stored in factory repo are sorted (lower address first)
        TokenConfig[] memory storedConfigs = pkg.tokenConfigs(proxy);
        assertEq(storedConfigs.length, 2, "Should have 2 token configs");
        assertTrue(
            address(storedConfigs[0].token) < address(storedConfigs[1].token),
            "Token configs should be sorted by address (ascending)"
        );
        assertEq(address(storedConfigs[0].token), lower, "First token should be lower address");
        assertEq(address(storedConfigs[1].token), higher, "Second token should be higher address");
    }

    /**
     * @notice Tests that heterogeneous token configs preserve field alignment through sorting.
     * @dev When tokens are reordered by address, their associated TokenType, rateProvider,
     *  and paysYieldFees fields must follow them.
     */
    function test_tokenConfigs_preserveFieldAlignment() public {
        address lower;
        address higher;
        if (address(tokenA) < address(tokenB)) {
            lower = address(tokenA);
            higher = address(tokenB);
        } else {
            lower = address(tokenB);
            higher = address(tokenA);
        }

        address mockRateProvider = makeAddr("rateProvider");

        // Deliberately pass higher address first with distinct config
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(higher, TokenType.WITH_RATE, mockRateProvider, true);
        configs[1] = _createTokenConfig(lower, TokenType.STANDARD, address(0), false);

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        // After sorting, lower address should be first with its original config
        TokenConfig[] memory storedConfigs = pkg.tokenConfigs(proxy);
        assertEq(address(storedConfigs[0].token), lower, "First should be lower address");
        assertEq(uint8(storedConfigs[0].tokenType), uint8(TokenType.STANDARD), "Lower token should be STANDARD");
        assertEq(address(storedConfigs[0].rateProvider), address(0), "Lower token should have no rate provider");
        assertFalse(storedConfigs[0].paysYieldFees, "Lower token should not pay yield fees");

        assertEq(address(storedConfigs[1].token), higher, "Second should be higher address");
        assertEq(uint8(storedConfigs[1].tokenType), uint8(TokenType.WITH_RATE), "Higher token should be WITH_RATE");
        assertEq(address(storedConfigs[1].rateProvider), mockRateProvider, "Higher token should have rate provider");
        assertTrue(storedConfigs[1].paysYieldFees, "Higher token should pay yield fees");
    }

    /**
     * @notice Tests that the vault receives the sorted token configs during registration.
     */
    function test_tokenConfigs_vaultReceivesSortedConfigs() public {
        address lower;
        address higher;
        if (address(tokenA) < address(tokenB)) {
            lower = address(tokenA);
            higher = address(tokenB);
        } else {
            lower = address(tokenB);
            higher = address(tokenA);
        }

        // Pass in reverse order
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(higher, TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(lower, TokenType.STANDARD, address(0), false);

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        diamondFactory.deploy(pkg, pkgArgs);

        // Verify the mock vault received 2 sorted tokens
        assertEq(mockVault.registeredTokenCount(), 2, "Vault should have 2 tokens");
        assertEq(mockVault.registeredTokenAt(0), lower, "First vault token should be lower address");
        assertEq(mockVault.registeredTokenAt(1), higher, "Second vault token should be higher address");
    }

    /**
     * @notice Tests that the pool is registered in the DFPkg's factory pool set.
     */
    function test_postDeploy_registersPoolInFactory() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        assertTrue(pkg.isPoolFromFactory(proxy), "Proxy should be registered as a pool from this factory");
        assertEq(pkg.getPoolCount(), 1, "Factory should have 1 pool");
    }

    /**
     * @notice Tests that the vault receives correct swap fee percentage during registration.
     */
    function test_postDeploy_vaultReceivesCorrectSwapFee() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        diamondFactory.deploy(pkg, pkgArgs);

        assertEq(mockVault.lastSwapFeePercentage(), 5e16, "Swap fee should be 5%");
    }

    /**
     * @notice Tests that deploying with the same args twice returns the same address (idempotent).
     */
    function test_deploy_isIdempotent() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgArgs({
                tokenConfigs: configs,
                hooksContract: address(0)
            })
        );

        address first = diamondFactory.deploy(pkg, pkgArgs);
        address second = diamondFactory.deploy(pkg, pkgArgs);

        assertEq(first, second, "Deploying same args twice should return same address");
    }

    /* -------------------------------------------------------------------------- */
    /*                           Helper Functions                                  */
    /* -------------------------------------------------------------------------- */

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
