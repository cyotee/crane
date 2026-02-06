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
import {IHooks} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IHooks.sol";
import {IPoolInfo} from "@crane/contracts/external/balancer/v3/interfaces/contracts/pool-utils/IPoolInfo.sol";

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
import {CowPoolFacet} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolFacet.sol";

/* -------------------------------------------------------------------------- */
/*                                   DFPkg                                    */
/* -------------------------------------------------------------------------- */

import {CowPoolDFPkg, ICowPoolDFPkg} from "@crane/contracts/protocols/dexes/balancer/v3/pools/cow/CowPoolDFPkg.sol";

/* -------------------------------------------------------------------------- */
/*                              Mock Implementations                          */
/* -------------------------------------------------------------------------- */

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
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

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
 * @notice Minimal IFacet to satisfy the DFPkg pool-info cut.
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
 * @notice Mock vault that enforces hook onRegister() success.
 */
contract MockBalancerV3Vault {
    bool public poolRegistered;
    address public lastRegisteredPool;
    address public lastPoolFactory;

    function registerPool(
        address pool,
        TokenConfig[] memory tokenConfig,
        uint256,
        uint32,
        bool,
        PoolRoleAccounts memory,
        address poolHooksContract,
        LiquidityManagement memory liquidityManagement
    ) external {
        bool ok = IHooks(poolHooksContract).onRegister(msg.sender, pool, tokenConfig, liquidityManagement);
        require(ok, "onRegister failed");

        poolRegistered = true;
        lastRegisteredPool = pool;
        lastPoolFactory = msg.sender;
    }

    function getAuthorizer() external pure returns (address) {
        return address(0);
    }
}

contract CowPoolDFPkg_Integration_Test is CraneTest {
    CowPoolDFPkg internal pkg;

    BalancerV3VaultAwareFacet internal vaultAwareFacet;
    BalancerV3PoolTokenFacet internal poolTokenFacet;
    BalancerV3AuthenticationFacet internal authFacet;
    CowPoolFacet internal cowPoolFacet;
    MockPoolInfoFacet internal poolInfoFacet;

    MockBalancerV3Vault internal mockVault;

    MockERC20 internal tokenA;
    MockERC20 internal tokenB;

    address internal poolManager;
    address internal trustedCowRouter;

    function setUp() public override {
        CraneTest.setUp();

        mockVault = new MockBalancerV3Vault();
        vm.label(address(mockVault), "MockBalancerV3Vault");

        tokenA = new MockERC20("Token A", "TKNA", 18);
        tokenB = new MockERC20("Token B", "TKNB", 18);
        vm.label(address(tokenA), "TokenA");
        vm.label(address(tokenB), "TokenB");

        poolManager = makeAddr("poolManager");
        trustedCowRouter = makeAddr("trustedCowRouter");

        _deployRealFacets();
        _deployPkg();
    }

    function _deployRealFacets() internal {
        vaultAwareFacet = new BalancerV3VaultAwareFacet();
        poolTokenFacet = new BalancerV3PoolTokenFacet();
        authFacet = new BalancerV3AuthenticationFacet();
        cowPoolFacet = new CowPoolFacet();
        poolInfoFacet = new MockPoolInfoFacet();

        vm.label(address(vaultAwareFacet), "BalancerV3VaultAwareFacet");
        vm.label(address(poolTokenFacet), "BalancerV3PoolTokenFacet");
        vm.label(address(authFacet), "BalancerV3AuthenticationFacet");
        vm.label(address(cowPoolFacet), "CowPoolFacet");
        vm.label(address(poolInfoFacet), "MockPoolInfoFacet");
    }

    function _deployPkg() internal {
        pkg = new CowPoolDFPkg(
            ICowPoolDFPkg.PkgInit({
                balancerV3VaultAwareFacet: IFacet(address(vaultAwareFacet)),
                betterBalancerV3PoolTokenFacet: IFacet(address(poolTokenFacet)),
                defaultPoolInfoFacet: IFacet(address(poolInfoFacet)),
                balancerV3AuthenticationFacet: IFacet(address(authFacet)),
                cowPoolFacet: IFacet(address(cowPoolFacet)),
                balancerV3Vault: IVault(address(mockVault)),
                diamondFactory: diamondFactory,
                poolFeeManager: poolManager,
                trustedCowRouter: trustedCowRouter
            })
        );
        vm.label(address(pkg), "CowPoolDFPkg");
    }

    function test_postDeploy_triggersVaultRegistration_andOnRegisterPasses() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();
        uint256[] memory weights = _create5050Weights();

        bytes memory pkgArgs = abi.encode(
            ICowPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);
        vm.label(proxy, "CowPoolProxy");

        assertTrue(mockVault.poolRegistered(), "Pool should be registered");
        assertEq(mockVault.lastRegisteredPool(), proxy, "Registered pool should match proxy");
        assertEq(mockVault.lastPoolFactory(), address(pkg), "Vault should see DFPkg as factory");
    }

    function test_initAccount_setsCowPoolFactory_toDFPkg() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();
        uint256[] memory weights = _create5050Weights();

        bytes memory pkgArgs = abi.encode(
            ICowPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights
            })
        );

        address proxy = diamondFactory.deploy(pkg, pkgArgs);
        bool ok = IHooks(proxy).onRegister(
            address(pkg),
            proxy,
            configs,
            LiquidityManagement({
                disableUnbalancedLiquidity: true,
                enableAddLiquidityCustom: false,
                enableRemoveLiquidityCustom: false,
                enableDonation: true
            })
        );
        assertTrue(ok, "onRegister should accept DFPkg factory");
    }

    function test_deployedProxy_hasVaultAwareFacetSelector() public {
        TokenConfig[] memory configs = _createTwoTokenConfig();
        uint256[] memory weights = _create5050Weights();

        bytes memory pkgArgs = abi.encode(
            ICowPoolDFPkg.PkgArgs({
                tokenConfigs: configs,
                normalizedWeights: weights
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

    function _createTwoTokenConfig() internal view returns (TokenConfig[] memory) {
        TokenConfig[] memory configs = new TokenConfig[](2);
        configs[0] = _createTokenConfig(address(tokenA), TokenType.STANDARD, address(0), false);
        configs[1] = _createTokenConfig(address(tokenB), TokenType.STANDARD, address(0), false);
        return configs;
    }

    function _create5050Weights() internal pure returns (uint256[] memory weights) {
        weights = new uint256[](2);
        weights[0] = 0.5e18;
        weights[1] = 0.5e18;
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
