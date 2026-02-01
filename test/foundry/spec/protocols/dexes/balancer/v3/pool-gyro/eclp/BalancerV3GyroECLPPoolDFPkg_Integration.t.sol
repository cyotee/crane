// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                OpenZeppelin                                */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {TokenConfig, TokenType, PoolRoleAccounts, LiquidityManagement} from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@balancer-labs/v3-interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";
import {IGyroECLPPool} from "@balancer-labs/v3-interfaces/contracts/pool-gyro/IGyroECLPPool.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IDiamondLoupe} from "@crane/contracts/interfaces/IDiamondLoupe.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {IBalancerV3VaultAware} from "@crane/contracts/interfaces/IBalancerV3VaultAware.sol";
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";

/* -------------------------------------------------------------------------- */
/*                              Real Facet Imports                            */
/* -------------------------------------------------------------------------- */

import {BalancerV3VaultAwareFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3VaultAwareFacet.sol";
import {BalancerV3PoolTokenFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BetterBalancerV3PoolTokenFacet.sol";
import {BalancerV3AuthenticationFacet} from "@crane/contracts/protocols/dexes/balancer/v3/vault/BalancerV3AuthenticationFacet.sol";
import {BalancerV3GyroECLPPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                   DFPkg                                    */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3GyroECLPPoolDFPkg,
    IBalancerV3GyroECLPPoolDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/eclp/BalancerV3GyroECLPPoolDFPkg.sol";

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
}

/**
 * @title MockPoolInfoFacet
 * @notice Minimal IFacet for IPoolInfo compatibility.
 */
contract MockPoolInfoFacet is IFacet {
    function facetName() external pure returns (string memory) {
        return "MockPoolInfoFacet";
    }

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](0);
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = bytes4(keccak256("mockPoolInfo()"));
    }

    function facetMetadata() external pure returns (string memory, bytes4[] memory, bytes4[] memory) {
        bytes4[] memory interfaces = new bytes4[](0);

        bytes4[] memory funcs = new bytes4[](1);
        funcs[0] = bytes4(keccak256("mockPoolInfo()"));

        return ("MockPoolInfoFacet", interfaces, funcs);
    }
}

/**
 * @title MockBalancerV3Vault
 * @notice Minimal mock of Balancer V3 Vault for testing pool registration.
 */
contract MockBalancerV3Vault {
    bool public poolRegistered;
    address public lastRegisteredPool;

    function registerPool(
        address pool,
        TokenConfig[] memory,
        uint256,
        uint32,
        bool,
        PoolRoleAccounts memory,
        address,
        LiquidityManagement memory
    ) external {
        poolRegistered = true;
        lastRegisteredPool = pool;
    }

    function getAuthorizer() external pure returns (address) {
        return address(0);
    }
}

/**
 * @title BalancerV3GyroECLPPoolDFPkg_Integration_Test
 * @notice Integration test for ECLP pool DFPkg deployment + vault registration.
 * @dev Tests the complete deployment flow including:
 * - Pool proxy deployment via Diamond Factory
 * - Vault registration via postDeploy callback
 * - Facet selector mapping verification
 */
contract BalancerV3GyroECLPPoolDFPkg_Integration_Test is CraneTest {
    BalancerV3GyroECLPPoolDFPkg internal pkg;

    // Real facets
    BalancerV3VaultAwareFacet internal vaultAwareFacet;
    BalancerV3PoolTokenFacet internal poolTokenFacet;
    BalancerV3AuthenticationFacet internal authFacet;
    BalancerV3GyroECLPPoolFacet internal eclpFacet;
    MockPoolInfoFacet internal poolInfoFacet;

    // Mock vault
    MockBalancerV3Vault internal mockVault;

    // Mock tokens
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal poolManager;

    // ECLP parameters (upstream-tested set; see GyroECLPMath.t.sol)
    int256 constant ALPHA = 3100000000000000000000;
    int256 constant BETA = 4400000000000000000000;
    int256 constant C = 266047486094289;
    int256 constant S = 999999964609366945;
    int256 constant LAMBDA = 20000000000000000000000;

    function setUp() public override {
        CraneTest.setUp();

        mockVault = new MockBalancerV3Vault();
        vm.label(address(mockVault), "MockBalancerV3Vault");

        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        vm.label(address(tokenA), "TokenA");
        vm.label(address(tokenB), "TokenB");

        poolManager = makeAddr("poolManager");

        _deployRealFacets();
        _deployPkg();
    }

    function _deployRealFacets() internal {
        vaultAwareFacet = new BalancerV3VaultAwareFacet();
        poolTokenFacet = new BalancerV3PoolTokenFacet();
        authFacet = new BalancerV3AuthenticationFacet();
        eclpFacet = new BalancerV3GyroECLPPoolFacet();
        poolInfoFacet = new MockPoolInfoFacet();

        vm.label(address(vaultAwareFacet), "BalancerV3VaultAwareFacet");
        vm.label(address(poolTokenFacet), "BalancerV3PoolTokenFacet");
        vm.label(address(authFacet), "BalancerV3AuthenticationFacet");
        vm.label(address(eclpFacet), "BalancerV3GyroECLPPoolFacet");
        vm.label(address(poolInfoFacet), "MockPoolInfoFacet");
    }

    function _deployPkg() internal {
        pkg = new BalancerV3GyroECLPPoolDFPkg(
            IBalancerV3GyroECLPPoolDFPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                betterBalancerV3PoolTokenFacet: IFacet(address(poolTokenFacet)),
                defaultPoolInfoFacet: IFacet(address(poolInfoFacet)),
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                balancerV3GyroECLPPoolFacet: IFacet(address(eclpFacet)),
                balancerV3Vault: IVault(address(mockVault)),
                diamondFactory: diamondFactory,
                poolFeeManager: poolManager
            })
        );
        vm.label(address(pkg), "BalancerV3GyroECLPPoolDFPkg");
    }

    function _createECLPParams() internal pure returns (IGyroECLPPool.EclpParams memory) {
        return IGyroECLPPool.EclpParams({
            alpha: ALPHA,
            beta: BETA,
            c: C,
            s: S,
            lambda: LAMBDA
        });
    }

    function _createDerivedECLPParams() internal pure returns (IGyroECLPPool.DerivedEclpParams memory) {
        // Use upstream-tested values to satisfy GyroECLPMath validation.
        // Source: balancer-v3-monorepo/pkg/pool-gyro/test/foundry/GyroECLPMath.t.sol
        return IGyroECLPPool.DerivedEclpParams({
            tauAlpha: IGyroECLPPool.Vector2({
                x: -74906290317688162800819482607385924041,
                y: 66249888081733516165500078448108672943
            }),
            tauBeta: IGyroECLPPool.Vector2({
                x: 61281617359500229793875202705993079582,
                y: 79022549780450643715972436171311055791
            }),
            u: 36232449191667733617897641246115478,
            v: 79022548876385493056482320848126240168,
            w: 3398134415414370285204934569561736,
            z: -74906280678135799137829029450497780483,
            dSq: 99999999999999999958780685745704854600
        });
    }

    function test_calcSalt_revertOnInvalidDerivedParams() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();
        IGyroECLPPool.EclpParams memory eclpParams = _createECLPParams();

        IGyroECLPPool.DerivedEclpParams memory derivedParams = _createDerivedECLPParams();
        derivedParams.tauBeta.x = derivedParams.tauAlpha.x; // violates DerivedTauXWrong()

        bytes memory invalidArgs = abi.encode(
            IBalancerV3GyroECLPPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                eclpParams: eclpParams,
                derivedEclpParams: derivedParams,
                hooksContract: address(0)
            })
        );

        vm.expectRevert();
        pkg.calcSalt(invalidArgs);
    }

    function test_calcAddress_isTokenOrderIndependent() public {
        TokenConfig[] memory configsAB = _createTokenConfigPair(address(tokenA), address(tokenB));
        TokenConfig[] memory configsBA = _createTokenConfigPair(address(tokenB), address(tokenA));

        IGyroECLPPool.EclpParams memory eclpParams = _createECLPParams();
        IGyroECLPPool.DerivedEclpParams memory derivedParams = _createDerivedECLPParams();

        bytes memory pkgArgsAB = abi.encode(
            IBalancerV3GyroECLPPoolDFPkg.PkgArgs({
                tokenConfigs: configsAB,
                eclpParams: eclpParams,
                derivedEclpParams: derivedParams,
                hooksContract: address(0)
            })
        );

        bytes memory pkgArgsBA = abi.encode(
            IBalancerV3GyroECLPPoolDFPkg.PkgArgs({
                tokenConfigs: configsBA,
                eclpParams: eclpParams,
                derivedEclpParams: derivedParams,
                hooksContract: address(0)
            })
        );

        address expectedAB = diamondFactory.calcAddress(pkg, pkgArgsAB);
        address expectedBA = diamondFactory.calcAddress(pkg, pkgArgsBA);

        assertEq(expectedAB, expectedBA, "calcAddress should be token-order independent");
    }

    function test_postDeploy_triggersVaultRegistration() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();
        IGyroECLPPool.EclpParams memory eclpParams = _createECLPParams();
        IGyroECLPPool.DerivedEclpParams memory derivedParams = _createDerivedECLPParams();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3GyroECLPPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                eclpParams: eclpParams,
                derivedEclpParams: derivedParams,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        assertTrue(mockVault.poolRegistered(), "Pool should be registered with vault");
        assertEq(mockVault.lastRegisteredPool(), proxy, "Registered pool should match proxy");
    }

    function test_deployedProxy_hasVaultAwareFacetSelectors() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();
        IGyroECLPPool.EclpParams memory eclpParams = _createECLPParams();
        IGyroECLPPool.DerivedEclpParams memory derivedParams = _createDerivedECLPParams();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3GyroECLPPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                eclpParams: eclpParams,
                derivedEclpParams: derivedParams,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);
        IDiamondLoupe loupe = IDiamondLoupe(proxy);

        assertEq(
            loupe.facetAddress(IBalancerV3VaultAware.balV3Vault.selector),
            address(vaultAwareFacet),
            "balV3Vault selector should map to VaultAwareFacet"
        );
    }

    function test_packageName() public view {
        assertEq(pkg.packageName(), "BalancerV3GyroECLPPoolDFPkg");
    }

    function test_facetCuts_length() public view {
        assertEq(pkg.facetCuts().length, 5, "Should have 5 facet cuts");
    }

    function _createTwoTokenConfig() internal view returns (TokenConfig[] memory) {
        return _createTokenConfigPair(address(tokenA), address(tokenB));
    }

    function _createTokenConfigPair(address token0, address token1) internal pure returns (TokenConfig[] memory) {
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(token0, TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(token1, TokenType.STANDARD, address(0), false);
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
