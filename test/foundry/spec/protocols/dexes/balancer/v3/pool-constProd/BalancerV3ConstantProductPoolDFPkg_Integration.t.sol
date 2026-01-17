// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                OpenZeppelin                                */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC5267} from "@openzeppelin/contracts/interfaces/IERC5267.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {TokenConfig, TokenType, PoolRoleAccounts, LiquidityManagement} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {IBasePool} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import {IPoolInfo} from "@balancer-labs/v3-interfaces/contracts/pool-utils/IPoolInfo.sol";
import {ISwapFeePercentageBounds} from "@balancer-labs/v3-interfaces/contracts/vault/ISwapFeePercentageBounds.sol";
import {IUnbalancedLiquidityInvariantRatioBounds} from "@balancer-labs/v3-interfaces/contracts/vault/IUnbalancedLiquidityInvariantRatioBounds.sol";

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

    function getAuthorizer() external pure returns (address) {
        return address(0);
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

    function setUp() public override {
        // CraneTest.setUp() initializes create3Factory and diamondFactory via InitDevService
        CraneTest.setUp();

        // Deploy mock vault
        mockVault = new MockBalancerV3Vault();
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
        // Deploy real facets
        vaultAwareFacet = new BalancerV3VaultAwareFacet();
        poolTokenFacet = new BalancerV3PoolTokenFacet();
        authFacet = new BalancerV3AuthenticationFacet();
        constProdFacet = new BalancerV3ConstantProductPoolFacet();
        poolInfoFacet = new MockPoolInfoFacet();

        vm.label(address(vaultAwareFacet), "BalancerV3VaultAwareFacet");
        vm.label(address(poolTokenFacet), "BalancerV3PoolTokenFacet");
        vm.label(address(authFacet), "BalancerV3AuthenticationFacet");
        vm.label(address(constProdFacet), "BalancerV3ConstantProductPoolFacet");
        vm.label(address(poolInfoFacet), "MockPoolInfoFacet");
    }

    function _deployPkg() internal {
        pkg = new BalancerV3ConstantProductPoolDFPkg(
            IBalancerV3ConstantProductPoolStandardVaultPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                betterBalancerV3PoolTokenFacet: IFacet(address(poolTokenFacet)),
                defaultPoolInfoFacet: IFacet(address(poolInfoFacet)),
                standardSwapFeePercentageBoundsFacet: IFacet(address(poolInfoFacet)), // Not used in facetCuts
                unbalancedLiquidityInvariantRatioBoundsFacet: IFacet(address(poolInfoFacet)), // Not used in facetCuts
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                balancerV3ConstProdPoolFacet: IFacet(address(constProdFacet)),
                balancerV3Vault: IVault(address(mockVault)),
                diamondFactory: diamondFactory,
                poolFeeManager: poolManager
            })
        );
        vm.label(address(pkg), "BalancerV3ConstantProductPoolDFPkg");
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
