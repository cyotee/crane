// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {BasicAuthorizerMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/BasicAuthorizerMock.sol";
import {BatchRouterMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/BatchRouterMock.sol";
import {CompositeLiquidityRouterMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/CompositeLiquidityRouterMock.sol";
import {RouterMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/RouterMock.sol";
import {BufferRouterMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/BufferRouterMock.sol";
import {RateProviderMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/RateProviderMock.sol";
import {PoolFactoryMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/PoolFactoryMock.sol";
import {PoolHooksMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/PoolHooksMock.sol";
// import { HookFlags, FEE_SCALING_FACTOR, Rounding } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";
import { IProtocolFeeController } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IProtocolFeeController.sol";
import { IVaultExtension } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultExtension.sol";
import { IVaultAdmin } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVaultAdmin.sol";
import {IVaultMock} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/IVaultMock.sol";
import { IBasePool } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IBasePool.sol";
import { IVault } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {
    HookFlags,

    FEE_SCALING_FACTOR,
    Rounding,
    TokenConfig,
    TokenType
} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/VaultTypes.sol";

import {ICreate3Factory} from "@crane/contracts/interfaces/ICreate3Factory.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {IRateProvider} from "@crane/contracts/interfaces/protocols/dexes/balancer/v3/IRateProvider.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IERC4626RateProviderFacetDFPkg, ERC4626RateProviderFacetDFPkg} from "@crane/contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFacetDFPkg.sol";
import {BaseTest} from "@crane/contracts/protocols/dexes/balancer/v3/test/utils/BaseTest.sol";
import {TestBase_BalancerV3} from "@crane/contracts/protocols/dexes/balancer/v3/test/bases/TestBase_BalancerV3.sol";
import {InitDevService} from "@crane/contracts/InitDevService.sol";
import {ERC4626RateProviderFactoryService} from "@crane/contracts/protocols/dexes/balancer/v3/rateProviders/ERC4626RateProviderFactoryService.sol";
import {TestBase_Permit2} from "@crane/contracts/protocols/utils/permit2/test/bases/TestBase_Permit2.sol";
import {CraneTest} from "@crane/contracts/test/CraneTest.sol";
import {VaultContractsDeployer} from "@crane/contracts/protocols/dexes/balancer/v3/test/utils/VaultContractsDeployer.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import { CastingHelpers } from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/CastingHelpers.sol";
import {ArrayHelpers} from "@crane/contracts/protocols/dexes/balancer/v3/test/mocks/ArrayHelpers.sol";
import { FixedPoint } from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/math/FixedPoint.sol";


contract TestBase_BalancerV3Vault is
    TestBase_BalancerV3,
    // BaseVaultTest
    TestBase_Permit2,
    CraneTest,
    VaultContractsDeployer
{
    using CastingHelpers for address[];
    using FixedPoint for uint256;
    using ArrayHelpers for *;

    struct Balances {
        uint256[] userTokens;
        uint256 userEth;
        uint256 userBpt;
        uint256[] aliceTokens;
        uint256 aliceEth;
        uint256 aliceBpt;
        uint256[] bobTokens;
        uint256 bobEth;
        uint256 bobBpt;
        uint256[] hookTokens;
        uint256 hookEth;
        uint256 hookBpt;
        uint256[] lpTokens;
        uint256 lpEth;
        uint256 lpBpt;
        uint256[] vaultTokens;
        uint256 vaultEth;
        uint256[] vaultReserves;
        uint256[] poolTokens;
        uint256 poolEth;
        uint256 poolSupply;
        uint256 poolInvariant;
        uint256[] swapFeeAmounts;
        uint256[] yieldFeeAmounts;
    }

    // string PREPAID_BATCH_ROUTER_VERSION = "PrepaidBatchRouter v1";
    // // Pool limits.
    // uint256 internal constant POOL_MINIMUM_TOTAL_SUPPLY = 1e6;
    // uint256 internal constant PRODUCTION_MIN_TRADE_AMOUNT = 1e6;

    // // ERC4626 buffer limits.
    // uint256 internal constant BUFFER_MINIMUM_TOTAL_SUPPLY = 1e4;
    // uint256 internal constant PRODUCTION_MIN_WRAP_AMOUNT = 1e3;

    // // Applies to Weighted Pools.
    // uint256 internal constant BASE_MIN_SWAP_FEE = 1e12; // 0.00001%
    // uint256 internal constant BASE_MAX_SWAP_FEE = 10e16; // 10%

    // // Default amount to use in tests for user operations.
    // uint256 internal constant DEFAULT_AMOUNT = 1e3 * 1e18;
    // // Default amount round down.
    // uint256 internal constant DEFAULT_AMOUNT_ROUND_DOWN = DEFAULT_AMOUNT - 2;
    // // Default amount of BPT to use in tests for user operations.
    // uint256 internal constant DEFAULT_BPT_AMOUNT = 2e3 * 1e18;
    // // Default amount of BPT round down.
    // uint256 internal constant DEFAULT_BPT_AMOUNT_ROUND_DOWN = DEFAULT_BPT_AMOUNT - 2;
    // // Default rate for the rate provider mock.
    // uint256 internal constant DEFAULT_MOCK_RATE = 2e18;

    // // Default swap fee percentage.
    // uint256 internal constant DEFAULT_SWAP_FEE_PERCENTAGE = 1e16; // 1%
    // // Default protocol swap fee percentage.
    // uint64 internal constant DEFAULT_PROTOCOL_SWAP_FEE_PERCENTAGE = 50e16; // 50%

    // ICreate3Factory create3Factory;
    // IDiamondPackageCallBackFactory diamondPackageFactory;

    // Main contract mocks.
    IVaultMock internal vault;
    IVaultExtension internal vaultExtension;
    IVaultAdmin internal vaultAdmin;
    RouterMock internal router;
    BatchRouterMock internal batchRouter;
    BatchRouterMock internal prepaidBatchRouter;
    BufferRouterMock internal bufferRouter;
    RateProviderMock internal rateProvider;
    BasicAuthorizerMock internal authorizer;
    CompositeLiquidityRouterMock internal compositeLiquidityRouter;
    CompositeLiquidityRouterMock internal prepaidCompositeLiquidityRouter;

    // Fee controller deployed with the Vault.
    IProtocolFeeController internal feeController;
    // Pool for tests.
    address internal pool;
    // Arguments used to build pool. Used to check deployment address.
    bytes internal poolArguments;
    // Pool Hooks.
    address internal poolHooksContract;
    // Pool factory.
    address internal poolFactory;

    // Amount to use to init the mock pool.
    uint256 internal poolInitAmount = 1e3 * 1e18;

    // VaultMock can override min trade amount; tests shall use 0 by default to simplify fuzz tests.
    // Min trade amount is meant to be an extra protection against unknown rounding errors; the Vault should still work
    // without it, so it can be zeroed out in general.
    // Change this value before calling `setUp` to test under real conditions.
    uint256 vaultMockMinTradeAmount = 0;

    // VaultMock can override min wrap amount; tests shall use 1 by default to simplify fuzz tests but trigger minimum
    // wrap amount errors. Min wrap amount is meant to be an extra protection against unknown rounding errors; the
    // Vault should still work without it, so it can be zeroed out in general.
    // Change this value before calling `setUp` to test under real conditions.
    uint256 vaultMockMinWrapAmount = 1;

    // These are passed into the Protocol Fee Controller (keep zero for now to avoid breaking tests).
    uint256 vaultMockInitialProtocolSwapFeePercentage = 0;
    uint256 vaultMockInitialProtocolYieldFeePercentage = 0;


    IERC4626RateProviderFacetDFPkg erc4626RateProviderDFPkg;
    IRateProvider waDAIRateProvider;
    IRateProvider waWETHRateProvider;
    IRateProvider waUSDRateProvider;

    function setUp() public virtual
    override(
        CraneTest,
        TestBase_Permit2,
        TestBase_BalancerV3
    ) {
        TestBase_BalancerV3.setUp();
        TestBase_Permit2.setUp();  // Initialize permit2 before deploying contracts
        _deployMainContracts();
        onAfterDeployMainContracts();
        _approveForAllUsers();

        // poolFactory = createPoolFactory();
        // poolHooksContract = createHook();
        // (pool, poolArguments) = createPool();

        // if (pool != address(0)) {
        //     approveForPool(IERC20(pool));
        // }

        // Add initial liquidity
        // initPool();
    }

    function _deployMainContracts() internal {
        vault = deployVaultMock(
            vaultMockMinTradeAmount,
            vaultMockMinWrapAmount,
            vaultMockInitialProtocolSwapFeePercentage,
            vaultMockInitialProtocolYieldFeePercentage
        );

        vm.label(address(vault), "vault");
        vaultExtension = IVaultExtension(vault.getVaultExtension());
        vm.label(address(vaultExtension), "vaultExtension");
        vaultAdmin = IVaultAdmin(vault.getVaultAdmin());
        vm.label(address(vaultAdmin), "vaultAdmin");
        authorizer = BasicAuthorizerMock(address(vault.getAuthorizer()));
        vm.label(address(authorizer), "authorizer");
        router = deployRouterMock(IVault(address(vault)), weth, permit2);
        vm.label(address(router), "router");
        batchRouter = deployBatchRouterMock(IVault(address(vault)), weth, permit2);
        vm.label(address(batchRouter), "batch router");
        prepaidBatchRouter = deployBatchRouterMock(IVault(address(vault)), weth, IPermit2(address(0)));
        vm.label(address(prepaidBatchRouter), "prepaid batch router");
        compositeLiquidityRouter = deployCompositeLiquidityRouterMock(IVault(address(vault)), weth, permit2);
        vm.label(address(compositeLiquidityRouter), "composite liquidity router");
        prepaidCompositeLiquidityRouter = deployCompositeLiquidityRouterMock(
            IVault(address(vault)),
            weth,
            IPermit2(address(0))
        );
        bufferRouter = deployBufferRouterMock(IVault(address(vault)), weth, permit2);
        vm.label(address(bufferRouter), "buffer router");
        feeController = vault.getProtocolFeeController();
        vm.label(address(feeController), "fee controller");
    }

    function _approveForAllUsers() private {
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender();
            vm.stopPrank();
        }
    }

    function approveForSender() internal virtual {
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(address(permit2), type(uint256).max);
            permit2.approve(address(tokens[i]), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(tokens[i]), address(bufferRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(tokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(tokens[i]), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);
        }

        for (uint256 i = 0; i < oddDecimalTokens.length; ++i) {
            oddDecimalTokens[i].approve(address(permit2), type(uint256).max);
            permit2.approve(address(oddDecimalTokens[i]), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(oddDecimalTokens[i]), address(bufferRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(oddDecimalTokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2.approve(
                address(oddDecimalTokens[i]),
                address(compositeLiquidityRouter),
                type(uint160).max,
                type(uint48).max
            );
        }

        for (uint256 i = 0; i < erc4626Tokens.length; ++i) {
            erc4626Tokens[i].approve(address(permit2), type(uint256).max);
            permit2.approve(address(erc4626Tokens[i]), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(erc4626Tokens[i]), address(bufferRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(erc4626Tokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2.approve(
                address(erc4626Tokens[i]),
                address(compositeLiquidityRouter),
                type(uint160).max,
                type(uint48).max
            );

            // Approve deposits from sender.
            IERC20 underlying = IERC20(erc4626Tokens[i].asset());
            underlying.approve(address(erc4626Tokens[i]), type(uint160).max);
        }
    }

    function approveForPool(IERC20 bpt) internal virtual {
        for (uint256 i = 0; i < users.length; ++i) {
            vm.startPrank(users[i]);

            bpt.approve(address(router), type(uint256).max);
            bpt.approve(address(bufferRouter), type(uint256).max);
            bpt.approve(address(batchRouter), type(uint256).max);
            bpt.approve(address(compositeLiquidityRouter), type(uint256).max);

            IERC20(bpt).approve(address(permit2), type(uint256).max);
            permit2.approve(address(bpt), address(router), type(uint160).max, type(uint48).max);
            permit2.approve(address(bpt), address(bufferRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(bpt), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2.approve(address(bpt), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);

            vm.stopPrank();
        }
    }

    function initPool() internal virtual {
        vm.startPrank(lp);
        _initPool(pool, [poolInitAmount, poolInitAmount].toMemoryArray(), 0);
        vm.stopPrank();
    }

    function _initPool(
        address poolToInit,
        uint256[] memory amountsIn,
        uint256 minBptOut
    ) internal virtual returns (uint256 bptOut) {
        (IERC20[] memory tokens, , , ) = vault.getPoolTokenInfo(poolToInit);

        return router.initialize(poolToInit, tokens, amountsIn, minBptOut, false, bytes(""));
    }

    function createPool() internal virtual returns (address, bytes memory) {
        return _createPool([address(dai), address(usdc)].toMemoryArray(), "pool");
    }

    function _createPool(
        address[] memory tokens,
        string memory label
    ) internal virtual returns (address newPool, bytes memory poolArgs) {
        string memory name = "ERC20 Pool";
        string memory symbol = "ERC20POOL";

        newPool = PoolFactoryMock(poolFactory).createPool(name, symbol);
        vm.label(newPool, label);

        PoolFactoryMock(poolFactory).registerTestPool(
            newPool,
            vault.buildTokenConfig(tokens.asIERC20()),
            poolHooksContract,
            lp
        );

        poolArgs = abi.encode(vault, name, symbol);
    }

    function createHook() internal virtual returns (address) {
        // Sets all flags to false.
        HookFlags memory hookFlags;
        return _createHook(hookFlags);
    }

    function _createHook(HookFlags memory hookFlags) internal virtual returns (address) {
        PoolHooksMock newHook = deployPoolHooksMock(IVault(address(vault)));
        // Allow pools built with factoryMock to use the poolHooksMock.
        newHook.allowFactory(poolFactory);
        // Configure pool hook flags.
        newHook.setHookFlags(hookFlags);
        vm.label(address(newHook), "pool hooks");
        return address(newHook);
    }

    function onAfterDeployMainContracts() internal virtual {
        // (create3Factory, diamondPackageFactory) = InitDevService.initEnv(address(this));
        CraneTest.setUp();
        erc4626RateProviderDFPkg = ERC4626RateProviderFactoryService.initER4626RateProvicerDFPkg(create3Factory);
    }

    /* -------------------------------------------------------------------------- */
    /*                           Initialization Options                           */
    /* -------------------------------------------------------------------------- */

    function deployERC4626RateProvider(IERC4626 asset) public virtual returns (IRateProvider) {
        return erc4626RateProviderDFPkg.deployRateProvider(asset);
    }

    function standardTokenConfig(IERC20 token) public virtual returns (TokenConfig memory) {
        return TokenConfig({
            token: token,
            tokenType: TokenType.STANDARD,
            rateProvider: IRateProvider(address(0)),
            paysYieldFees: false
        });
    }

    function erc4626TokenConfig(IERC4626 token, IRateProvider rateProvider_, bool paysYieldFees) public virtual returns (TokenConfig memory) {
        return TokenConfig({
            token: IERC20(address(token)),
            tokenType: TokenType.WITH_RATE,
            rateProvider: rateProvider_,
            paysYieldFees: paysYieldFees
        });
    }

    function erc4626TokenConfig(IERC4626 token, bool paysYieldFees) public virtual returns (TokenConfig memory) {
        IRateProvider rateProvider_ = deployERC4626RateProvider(token);
        return erc4626TokenConfig(token, rateProvider_, paysYieldFees);
    }

    function erc4626TokenConfig(IERC4626 token) public virtual returns (TokenConfig memory) {
        IRateProvider rateProvider_ = deployERC4626RateProvider(token);
        return erc4626TokenConfig(token, rateProvider_, false);
    }

    /* ---------------------------------------------------------------------- */
    /*                            Approval Helpers                            */
    /* ---------------------------------------------------------------------- */

    function _approveSpenderForAllUsers(address spender) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveSpenderForAllUsers():: Entering function."));
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender(spender);
            vm.stopPrank();
        }
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveSpenderForAllUsers():: Exiting function."));
    }

    function approveForSender(address spender) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Entering function."));
        // console.log("BetterBalancerV3VaultTest.approveForSender():: Entering function.");
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(spender, type(uint256).max);
            permit2.approve(address(tokens[i]), address(spender), type(uint160).max, type(uint48).max);
        }

        for (uint256 i = 0; i < oddDecimalTokens.length; ++i) {
            oddDecimalTokens[i].approve(spender, type(uint256).max);
            permit2.approve(address(oddDecimalTokens[i]), spender, type(uint160).max, type(uint48).max);
        }

        for (uint256 i = 0; i < erc4626Tokens.length; ++i) {
            erc4626Tokens[i].approve(spender, type(uint256).max);
            permit2.approve(address(erc4626Tokens[i]), address(spender), type(uint160).max, type(uint48).max);
        }
        // console.log("BetterBalancerV3VaultTest.approveForSender():: Exiting function.");
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Exiting function."));
    }

    function _approveForAllUsers(IERC20 token) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveForAllUsers():: Entering function."));
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender(token);
            vm.stopPrank();
        }
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveForAllUsers():: Exiting function."));
    }

    function approveForSender(IERC20 token) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Entering function."));
        token.approve(address(permit2), type(uint256).max);
        permit2.approve(address(token), address(router), type(uint160).max, type(uint48).max);
        permit2.approve(address(token), address(bufferRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(token), address(batchRouter), type(uint160).max, type(uint48).max);
        permit2.approve(address(token), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Exiting function."));
    }

    function _approveSpenderForAllUsers(address spender, IERC20 token) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveSpenderForAllUsers():: Entering function."));
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender(spender, token);
            vm.stopPrank();
        }
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, "._approveSpenderForAllUsers():: Exiting function."));
    }

    function approveForSender(address spender, IERC20 token) internal virtual {
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Entering function."));
        token.approve(spender, type(uint256).max);
        permit2.approve(address(token), address(spender), type(uint160).max, type(uint48).max);
        // permit2.approve(address(token), address(bufferRouter), type(uint160).max, type(uint48).max);
        // permit2.approve(address(token), address(batchRouter), type(uint160).max, type(uint48).max);
        // permit2.approve(address(token), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);
        // console.log(string.concat(type(BetterBalancerV3VaultTest).name, ".approveForSender():: Exiting function."));
    }

    function mintPoolTokens(address[] memory poolsTokens, uint256[] memory tokenInitAmounts)
        public
        virtual
        returns (uint256[] memory updatedTokenInitAmounts)
    {
        // console.log(
        //     string.concat(
        //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name, ".mintPoolTokens():: Entering function."
        //     )
        // );
        updatedTokenInitAmounts = new uint256[](tokenInitAmounts.length);
        for (uint256 cursor = 0; cursor < poolsTokens.length; cursor++) {
            // console.log(
            //     string.concat(
            //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
            //         ".mintPoolTokens():: Minting ",
            //         IERC20(poolsTokens[cursor]).name(),
            //         " tokens."
            //     )
            // );
            if (address(poolsTokens[cursor]) == address(dai)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting DAI tokens."
                //     )
                // );
                dai.mint(lp, tokenInitAmounts[cursor]);
                // updatedTokenInitAmounts[cursor] = tokenInitAmounts[cursor];
                updatedTokenInitAmounts[cursor] = dai.balanceOf(lp);
            } else if (address(poolsTokens[cursor]) == address(usdc)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting USDC tokens."
                //     )
                // );
                usdc.mint(lp, tokenInitAmounts[cursor]);
                // updatedTokenInitAmounts[cursor] = tokenInitAmounts[cursor];
                updatedTokenInitAmounts[cursor] = usdc.balanceOf(lp);
            } else if (address(poolsTokens[cursor]) == address(weth)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting WETH tokens."
                //     )
                // );
                deal(lp, tokenInitAmounts[cursor]);
                // deal(lp, type(uint256).max);
                vm.startPrank(lp);
                weth.deposit{value: tokenInitAmounts[cursor]}();
                // weth.deposit{ value: tokenInitAmounts[cursor] }();
                // payable(address(weth)).transfer(tokenInitAmounts[cursor]);
                vm.stopPrank();
                // updatedTokenInitAmounts[cursor] = tokenInitAmounts[cursor];
                updatedTokenInitAmounts[cursor] = weth.balanceOf(lp);
            } else if (address(poolsTokens[cursor]) == address(waDAI)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting waDAI tokens."
                //     )
                // );
                dai.mint(lp, tokenInitAmounts[cursor]);
                vm.startPrank(lp);
                updatedTokenInitAmounts[cursor] = waDAI.deposit(tokenInitAmounts[cursor], lp);
                vm.stopPrank();
            } else if (address(poolsTokens[cursor]) == address(waUSDC)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting waUSDC tokens."
                //     )
                // );
                usdc.mint(lp, tokenInitAmounts[cursor]);
                vm.startPrank(lp);
                updatedTokenInitAmounts[cursor] = waUSDC.deposit(tokenInitAmounts[cursor], lp);
                vm.stopPrank();
            } else if (address(poolsTokens[cursor]) == address(waWETH)) {
                // console.log(
                //     string.concat(
                //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name,
                //         ".mintPoolTokens():: Minting waWETH tokens."
                //     )
                // );
                deal(lp, tokenInitAmounts[cursor]);
                vm.startPrank(lp);
                weth.deposit{value: tokenInitAmounts[cursor]}();
                updatedTokenInitAmounts[cursor] = waWETH.deposit(tokenInitAmounts[cursor], lp);
                vm.stopPrank();
            }
        }
        // console.log(
        //     string.concat(
        //         type(TestBase_Indexedex_BalancerV3_ConstantProductPool).name, ".mintPoolTokens():: Exiting function."
        //     )
        // );
    }

}
