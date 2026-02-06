// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/* -------------------------------------------------------------------------- */
/*                                OpenZeppelin                                */
/* -------------------------------------------------------------------------- */

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20Events} from "@crane/contracts/interfaces/IERC20Events.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import {TokenConfig, TokenType, PoolRoleAccounts, LiquidityManagement} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRateProvider} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/helpers/IRateProvider.sol";

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
import {BalancerV3Gyro2CLPPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/2clp/BalancerV3Gyro2CLPPoolFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                   DFPkg                                    */
/* -------------------------------------------------------------------------- */

import {
    BalancerV3Gyro2CLPPoolDFPkg,
    IBalancerV3Gyro2CLPPoolDFPkg
} from "@crane/contracts/protocols/dexes/balancer/v3/pool-gyro/2clp/BalancerV3Gyro2CLPPoolDFPkg.sol";

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
 * @title BalancerV3Gyro2CLPPoolDFPkg_Integration_Test
 * @notice Integration test for 2-CLP pool DFPkg deployment + vault registration.
 * @dev Tests the complete deployment flow including:
 * - Pool proxy deployment via Diamond Factory
 * - Vault registration via postDeploy callback
 * - Facet selector mapping verification
 */
contract BalancerV3Gyro2CLPPoolDFPkg_Integration_Test is CraneTest {
    BalancerV3Gyro2CLPPoolDFPkg internal pkg;

    // Real facets
    BalancerV3VaultAwareFacet internal vaultAwareFacet;
    BalancerV3PoolTokenFacet internal poolTokenFacet;
    BalancerV3AuthenticationFacet internal authFacet;
    BalancerV3Gyro2CLPPoolFacet internal twoCLPFacet;
    MockPoolInfoFacet internal poolInfoFacet;

    // Mock vault
    MockBalancerV3Vault internal mockVault;

    // Mock tokens
    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal poolManager;

    // 2-CLP parameters
    // sqrtAlpha and sqrtBeta define the price bounds
    // For a price range of [0.9, 1.1], sqrtAlpha ≈ 0.9487, sqrtBeta ≈ 1.0488
    uint256 constant SQRT_ALPHA = 0.9487e18;  // sqrt(0.9)
    uint256 constant SQRT_BETA = 1.0488e18;   // sqrt(1.1)

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
        twoCLPFacet = new BalancerV3Gyro2CLPPoolFacet();
        poolInfoFacet = new MockPoolInfoFacet();

        vm.label(address(vaultAwareFacet), "BalancerV3VaultAwareFacet");
        vm.label(address(poolTokenFacet), "BalancerV3PoolTokenFacet");
        vm.label(address(authFacet), "BalancerV3AuthenticationFacet");
        vm.label(address(twoCLPFacet), "BalancerV3Gyro2CLPPoolFacet");
        vm.label(address(poolInfoFacet), "MockPoolInfoFacet");
    }

    function _deployPkg() internal {
        pkg = new BalancerV3Gyro2CLPPoolDFPkg(
            IBalancerV3Gyro2CLPPoolDFPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                betterBalancerV3PoolTokenFacet: IFacet(address(poolTokenFacet)),
                defaultPoolInfoFacet: IFacet(address(poolInfoFacet)),
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                balancerV3Gyro2CLPPoolFacet: IFacet(address(twoCLPFacet)),
                balancerV3Vault: IVault(address(mockVault)),
                diamondFactory: diamondFactory,
                poolFeeManager: poolManager
            })
        );
        vm.label(address(pkg), "BalancerV3Gyro2CLPPoolDFPkg");
    }

    function test_postDeploy_triggersVaultRegistration() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3Gyro2CLPPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                sqrtAlpha: SQRT_ALPHA,
                sqrtBeta: SQRT_BETA,
                hooksContract: address(0)
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);

        assertTrue(mockVault.poolRegistered(), "Pool should be registered with vault");
        assertEq(mockVault.lastRegisteredPool(), proxy, "Registered pool should match proxy");
    }

    function test_deployedProxy_hasVaultAwareFacetSelectors() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        bytes memory pkgArgs = abi.encode(
            IBalancerV3Gyro2CLPPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                sqrtAlpha: SQRT_ALPHA,
                sqrtBeta: SQRT_BETA,
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
        assertEq(pkg.packageName(), "BalancerV3Gyro2CLPPoolDFPkg");
    }

    function test_facetCuts_length() public view {
        assertEq(pkg.facetCuts().length, 5, "Should have 5 facet cuts");
    }

    function test_calcSalt_revertOnInvalidSqrtParams() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();

        // sqrtAlpha >= sqrtBeta should revert
        bytes memory invalidArgs = abi.encode(
            IBalancerV3Gyro2CLPPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                sqrtAlpha: SQRT_BETA, // Wrong: alpha >= beta
                sqrtBeta: SQRT_ALPHA,
                hooksContract: address(0)
            })
        );

        vm.expectRevert(BalancerV3Gyro2CLPPoolDFPkg.SqrtParamsWrong.selector);
        pkg.calcSalt(invalidArgs);
    }

    function test_calcSalt_revertOnInvalidTokensLength() public {
        TokenConfig[] memory configs = new TokenConfig[](3); // Wrong: should be 2
        configs[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);
        configs[2] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);

        bytes memory invalidArgs = abi.encode(
            IBalancerV3Gyro2CLPPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                sqrtAlpha: SQRT_ALPHA,
                sqrtBeta: SQRT_BETA,
                hooksContract: address(0)
            })
        );

        vm.expectRevert(abi.encodeWithSelector(
            BalancerV3Gyro2CLPPoolDFPkg.InvalidTokensLength.selector,
            2, // required
            3  // provided
        ));
        pkg.calcSalt(invalidArgs);
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
