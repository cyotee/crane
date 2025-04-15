// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                 Balancer V3                                */
/* -------------------------------------------------------------------------- */

import { IProtocolFeeController } from "@balancer-labs/v3-interfaces/contracts/vault/IProtocolFeeController.sol";
import { HookFlags, FEE_SCALING_FACTOR, Rounding } from "@balancer-labs/v3-interfaces/contracts/vault/VaultTypes.sol";
import { IVaultExtension } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultExtension.sol";
import { IVaultAdmin } from "@balancer-labs/v3-interfaces/contracts/vault/IVaultAdmin.sol";
import { IVaultMock } from "@balancer-labs/v3-interfaces/contracts/test/IVaultMock.sol";
import { IBasePool } from "@balancer-labs/v3-interfaces/contracts/vault/IBasePool.sol";
import { IVault } from "@balancer-labs/v3-interfaces/contracts/vault/IVault.sol";
import {IVaultMock} from "@balancer-labs/v3-interfaces/contracts/test/IVaultMock.sol";

import { CastingHelpers } from "@balancer-labs/v3-solidity-utils/contracts/helpers/CastingHelpers.sol";
import { ArrayHelpers } from "@balancer-labs/v3-solidity-utils/contracts/test/ArrayHelpers.sol";
import { FixedPoint } from "@balancer-labs/v3-solidity-utils/contracts/math/FixedPoint.sol";

import { ERC4626TestToken } from "@balancer-labs/v3-solidity-utils/contracts/test/ERC4626TestToken.sol";
import { ERC20TestToken } from "@balancer-labs/v3-solidity-utils/contracts/test/ERC20TestToken.sol";
import { WETHTestToken } from "@balancer-labs/v3-solidity-utils/contracts/test/WETHTestToken.sol";

import { BasicAuthorizerMock } from "@balancer-labs/v3-vault/contracts/test/BasicAuthorizerMock.sol";
import { RateProviderMock } from "@balancer-labs/v3-vault/contracts/test/RateProviderMock.sol";
import { BatchRouterMock } from "@balancer-labs/v3-vault/contracts/test/BatchRouterMock.sol";
import { CompositeLiquidityRouterMock } from "@balancer-labs/v3-vault/contracts/test/CompositeLiquidityRouterMock.sol";
import { PoolFactoryMock } from "@balancer-labs/v3-vault/contracts/test/PoolFactoryMock.sol";
import { PoolHooksMock } from "@balancer-labs/v3-vault/contracts/test/PoolHooksMock.sol";
import { RouterMock } from "@balancer-labs/v3-vault/contracts/test/RouterMock.sol";
import { BufferRouterMock } from "@balancer-labs/v3-vault/contracts/test/BufferRouterMock.sol";

import { VaultContractsDeployer } from "@balancer-labs/v3-vault/test/foundry/utils/VaultContractsDeployer.sol";
import { Permit2Helpers } from "@balancer-labs/v3-vault/test/foundry/utils/Permit2Helpers.sol";

import {BaseTest} from "@balancer-labs/v3-solidity-utils/test/foundry/utils/BaseTest.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "../../../utils/vm/foundry/tools/betterconsole.sol";
import {Bytecode} from "../../../utils/Bytecode.sol";
import {Test_Crane} from "../../Test_Crane.sol";
import {BetterBalancerV3BaseTest} from "./BetterBalancerV3BaseTest.sol";
// import {Fixture_BalancerV3_Vault} from "../../../fixtures/protocols/Fixture_BalancerV3_Vault.sol"; 
import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {
    Create2CallBackFactory
} from "../../../factories/create2/callback/Create2CallBackFactory.sol";
import {IDiamondPackageCallBackFactory} from "../../../interfaces/IDiamondPackageCallBackFactory.sol";
import { TestBase_Permit2 } from "../protocols/TestBase_Permit2.sol";
import { ScriptBase_Crane_ERC20 } from "../../../script/ScriptBase_Crane_ERC20.sol";
import { ScriptBase_Crane_ERC4626 } from "../../../script/ScriptBase_Crane_ERC4626.sol";
import { BetterIERC20 } from "../../../interfaces/BetterIERC20.sol";


contract BetterBalancerV3VaultTest
is
    // Fixture_BalancerV3_Vault,
    BetterBalancerV3BaseTest,
    TestBase_Permit2
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

    // Pool limits.
    uint256 internal constant POOL_MINIMUM_TOTAL_SUPPLY = 1e6;
    uint256 internal constant PRODUCTION_MIN_TRADE_AMOUNT = 1e6;

    // ERC4626 buffer limits.
    uint256 internal constant BUFFER_MINIMUM_TOTAL_SUPPLY = 1e4;
    uint256 internal constant PRODUCTION_MIN_WRAP_AMOUNT = 1e3;

    // Applies to Weighted Pools.
    uint256 internal constant BASE_MIN_SWAP_FEE = 1e12; // 0.00001%
    uint256 internal constant BASE_MAX_SWAP_FEE = 10e16; // 10%

    // Default amount to use in tests for user operations.
    uint256 internal constant DEFAULT_AMOUNT = 1e3 * 1e18;
    // Default amount round down.
    uint256 internal constant DEFAULT_AMOUNT_ROUND_DOWN = DEFAULT_AMOUNT - 2;
    // Default amount of BPT to use in tests for user operations.
    uint256 internal constant DEFAULT_BPT_AMOUNT = 2e3 * 1e18;
    // Default amount of BPT round down.
    uint256 internal constant DEFAULT_BPT_AMOUNT_ROUND_DOWN = DEFAULT_BPT_AMOUNT - 2;
    // Default rate for the rate provider mock.
    uint256 internal constant DEFAULT_MOCK_RATE = 2e18;

    // Default swap fee percentage.
    uint256 internal constant DEFAULT_SWAP_FEE_PERCENTAGE = 1e16; // 1%
    // Default protocol swap fee percentage.
    uint64 internal constant DEFAULT_PROTOCOL_SWAP_FEE_PERCENTAGE = 50e16; // 50%

    // Main contract mocks.
    IVaultMock vault;
    IVaultExtension vaultExtension;
    IVaultAdmin vaultAdmin;
    RouterMock router;
    BatchRouterMock batchRouter;
    BufferRouterMock bufferRouter;
    RateProviderMock rateProvider;
    CompositeLiquidityRouterMock compositeLiquidityRouter;
    BasicAuthorizerMock authorizer;

    // Fee controller deployed with the Vault.
    IProtocolFeeController feeController;
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

    Create2CallBackFactory _factory;
    IDiamondPackageCallBackFactory _diamondPkgFactory;

    function setUp() public virtual
    override(
        BetterBalancerV3BaseTest,
        // Test_Crane,
        TestBase_Permit2
    ) {
        // console.log("BetterBalancerV3VaultTest.setUp():: Entering function.");
        // console.log("BetterBalancerV3VaultTest.setUp():: Setting up BetterBalancerV3BaseTest.");
        BetterBalancerV3BaseTest.setUp();
        // console.log("BetterBalancerV3VaultTest.setUp():: Setting up Test_Crane.");
        // Test_Crane.setUp();

        // console.log("BetterBalancerV3VaultTest.setUp():: Deploying main contracts.");
        _deployMainContracts();
        // console.log("BetterBalancerV3VaultTest.setUp():: Deployed main contracts.");
        // console.log("BetterBalancerV3VaultTest.setUp():: Calling onAfterDeployMainContracts().");
        onAfterDeployMainContracts();
        // console.log("BetterBalancerV3VaultTest.setUp():: Called onAfterDeployMainContracts().");
        // console.log("BetterBalancerV3VaultTest.setUp():: Approved for all users.");
        _approveForAllUsers();

        // console.log("BetterBalancerV3VaultTest.setUp():: Creating pool factory.");
        poolFactory = createPoolFactory();
        // console.log("BetterBalancerV3VaultTest.setUp():: Creating pool hooks contract.");
        poolHooksContract = createHook();
        // console.log("BetterBalancerV3VaultTest.setUp():: Creating pool.");
        (pool, poolArguments) = createPool();
        // console.log("BetterBalancerV3VaultTest.setUp():: Created pool.");

        // console.log("BetterBalancerV3VaultTest.setUp():: Checking that pool was created.");
        if (pool != address(0)) {
            // console.log("BetterBalancerV3VaultTest.setUp():: Approving pool for all tokens fopr all users.");
            approveForPool(IERC20(pool));
        }

        // Add initial liquidity
        // console.log("BetterBalancerV3VaultTest.setUp():: Adding initial liquidity.");
        initPool();
        // console.log("BetterBalancerV3VaultTest.setUp():: Added initial liquidity.");
        // console.log("BetterBalancerV3VaultTest.setUp():: Exiting function.");
    }

    function run() public virtual
    override(
        BetterBalancerV3BaseTest,
        TestBase_Permit2
    ) {
        // solhint-disable-next-line no-empty-blocks
    }

    function _deployMainContracts() private {
        // vault = deployVaultMock(
        //     vaultMockMinTradeAmount,
        //     vaultMockMinWrapAmount,
        //     vaultMockInitialProtocolSwapFeePercentage,
        //     vaultMockInitialProtocolYieldFeePercentage
        // );
        // console.log("BetterBalancerV3VaultTest.setUp():: Deploying vault.");
        vault = IVaultMock(
            address(
                balV3Vault(
                    // bytes32 salt,
                    _HARDCODED_SALT,
                    // address targetAddress,
                    Bytecode._create3AddressFromOf(address(balV3VaultFactory()), _HARDCODED_SALT),
                    // IProtocolFeeController protocolFeeController,
                    balV3ProtocolFeeController(),
                    // uint256 minTradeAmount,
                    vaultMockMinTradeAmount,
                    // uint256 minWrapAmount,
                    vaultMockMinWrapAmount,
                    // uint256 protocolSwapFeePercentage,
                    vaultMockInitialProtocolSwapFeePercentage,
                    // uint256 protocolYieldFeePercentage
                    vaultMockInitialProtocolYieldFeePercentage
                )
            )
        );
        // console.log("BetterBalancerV3VaultTest.setUp():: Deployed vault.");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling vault.");
        vm.label(address(vault), "vault");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled vault.");
        
        // console.log("BetterBalancerV3VaultTest.setUp():: Getting vault extension.");
        vaultExtension = IVaultExtension(vault.getVaultExtension());
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling vault extension.");
        vm.label(address(vaultExtension), "vaultExtension");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled vault extension.");
        
        // console.log("BetterBalancerV3VaultTest.setUp():: Getting vault admin.");
        vaultAdmin = IVaultAdmin(vault.getVaultAdmin());
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling vault admin.");
        vm.label(address(vaultAdmin), "vaultAdmin");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled vault admin.");

        // console.log("BetterBalancerV3VaultTest.setUp():: Getting authorizer.");
        authorizer = BasicAuthorizerMock(address(vault.getAuthorizer()));
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling authorizer.");
        vm.label(address(authorizer), "authorizer");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled authorizer.");

        // console.log("BetterBalancerV3VaultTest.setUp():: Deploying router mock.");
        router = deployRouterMock(IVault(address(vault)), weth, permit2());
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling router.");
        vm.label(address(router), "router");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled router.");

        // console.log("BetterBalancerV3VaultTest.setUp():: Deploying batch router mock.");
        batchRouter = deployBatchRouterMock(IVault(address(vault)), weth, permit2());
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling batch router.");
        vm.label(address(batchRouter), "batch router");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled batch router.");
        
        // console.log("BetterBalancerV3VaultTest.setUp():: Deploying composite liquidity router.");
        compositeLiquidityRouter = new CompositeLiquidityRouterMock(IVault(address(vault)), weth, permit2());
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling composite liquidity router.");
        vm.label(address(compositeLiquidityRouter), "composite liquidity router");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled composite liquidity router.");

        // console.log("BetterBalancerV3VaultTest.setUp():: Deploying buffer router mock.");
        bufferRouter = deployBufferRouterMock(IVault(address(vault)), weth, permit2());
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling buffer router.");
        vm.label(address(bufferRouter), "buffer router");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled buffer router.");

        // console.log("BetterBalancerV3VaultTest.setUp():: Getting fee controller.");
        feeController = vault.getProtocolFeeController();
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeling fee controller.");
        vm.label(address(feeController), "fee controller");
        // console.log("BetterBalancerV3VaultTest.setUp():: Labeled fee controller.");

        // console.log("BetterBalancerV3VaultTest.setUp():: Deployed main contracts.");
        // console.log("BetterBalancerV3VaultTest.setUp():: Exiting function.");
    }

    function onAfterDeployMainContracts() internal virtual {}

    function _approveForAllUsers() internal virtual {
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender();
            vm.stopPrank();
        }
    }

    function approveForSender() internal virtual {
        // console.log("BetterBalancerV3VaultTest.approveForSender():: Entering function.");
        for (uint256 i = 0; i < tokens.length; ++i) {
            tokens[i].approve(address(permit2()), type(uint256).max);
            permit2().approve(address(tokens[i]), address(router), type(uint160).max, type(uint48).max);
            permit2().approve(address(tokens[i]), address(bufferRouter), type(uint160).max, type(uint48).max);
            permit2().approve(address(tokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2().approve(address(tokens[i]), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);
        }

        for (uint256 i = 0; i < oddDecimalTokens.length; ++i) {
            oddDecimalTokens[i].approve(address(permit2()), type(uint256).max);
            permit2().approve(address(oddDecimalTokens[i]), address(router), type(uint160).max, type(uint48).max);
            permit2().approve(address(oddDecimalTokens[i]), address(bufferRouter), type(uint160).max, type(uint48).max);
            permit2().approve(address(oddDecimalTokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2().approve(
                address(oddDecimalTokens[i]),
                address(compositeLiquidityRouter),
                type(uint160).max,
                type(uint48).max
            );
        }

        for (uint256 i = 0; i < erc4626Tokens.length; ++i) {
            erc4626Tokens[i].approve(address(permit2()), type(uint256).max);
            permit2().approve(address(erc4626Tokens[i]), address(router), type(uint160).max, type(uint48).max);
            permit2().approve(address(erc4626Tokens[i]), address(bufferRouter), type(uint160).max, type(uint48).max);
            permit2().approve(address(erc4626Tokens[i]), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2().approve(
                address(erc4626Tokens[i]),
                address(compositeLiquidityRouter),
                type(uint160).max,
                type(uint48).max
            );

            // Approve deposits from sender.
            IERC20 underlying = IERC20(erc4626Tokens[i].asset());
            underlying.approve(address(erc4626Tokens[i]), type(uint160).max);
        }
        // console.log("BetterBalancerV3VaultTest.approveForSender():: Exiting function.");
    }

    function _approveForAllUsers(IERC20 token) internal virtual {
        for (uint256 i = 0; i < users.length; ++i) {
            address user = users[i];
            vm.startPrank(user);
            approveForSender(token);
            vm.stopPrank();
        }
    }

    function approveForSender(IERC20 token) internal virtual {
        token.approve(address(permit2()), type(uint256).max);
        permit2().approve(address(token), address(router), type(uint160).max, type(uint48).max);
        permit2().approve(address(token), address(bufferRouter), type(uint160).max, type(uint48).max);
        permit2().approve(address(token), address(batchRouter), type(uint160).max, type(uint48).max);
        permit2().approve(address(token), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);
    }

    function approveForPool(IERC20 bpt) internal virtual {
        // console.log("BetterBalancerV3VaultTest.approveForPool():: Entering function.");
        for (uint256 i = 0; i < users.length; ++i) {
            vm.startPrank(users[i]);

            bpt.approve(address(router), type(uint256).max);
            bpt.approve(address(bufferRouter), type(uint256).max);
            bpt.approve(address(batchRouter), type(uint256).max);
            bpt.approve(address(compositeLiquidityRouter), type(uint256).max);

            IERC20(bpt).approve(address(permit2()), type(uint256).max);
            permit2().approve(address(bpt), address(router), type(uint160).max, type(uint48).max);
            permit2().approve(address(bpt), address(bufferRouter), type(uint160).max, type(uint48).max);
            permit2().approve(address(bpt), address(batchRouter), type(uint160).max, type(uint48).max);
            permit2().approve(address(bpt), address(compositeLiquidityRouter), type(uint160).max, type(uint48).max);

            vm.stopPrank();
        }
        // console.log("BetterBalancerV3VaultTest.approveForPool():: Exiting function.");
    }

    function initPool() internal virtual {
        // console.log("BetterBalancerV3VaultTest.initPool():: Entering function.");
        vm.startPrank(lp);
        _initPool(pool, [poolInitAmount, poolInitAmount].toMemoryArray(), 0);
        vm.stopPrank();
        // console.log("BetterBalancerV3VaultTest.initPool():: Exiting function.");
    }

    function _initPool(
        address poolToInit,
        uint256[] memory amountsIn,
        uint256 minBptOut
    ) internal virtual returns (uint256 bptOut) {
        (IERC20[] memory tokens, , , ) = vault.getPoolTokenInfo(poolToInit);

        return router.initialize(poolToInit, tokens, amountsIn, minBptOut, false, bytes(""));
    }

    // function erc20Permit(
    //     string memory name,
    //     string memory symbol
    // ) public virtual
    // override(
    //     ScriptBase_Crane_ERC20,
    //     BetterBalancerV3BaseTest
    // ) returns (BetterIERC20 erc20_) {
    //     return BetterBalancerV3BaseTest.erc20Permit(
    //         name,
    //         symbol
    //     );
    // }

    // function erc4626(
    //     address underlying
    // ) public virtual
    // override(
    //     ScriptBase_Crane_ERC4626,
    //     BetterBalancerV3BaseTest
    // ) returns (IERC4626 erc4626_) {
    //     return BetterBalancerV3BaseTest.erc4626(underlying);
    // }

    function createPoolFactory() internal virtual returns (address) {
        // console.log("BetterBalancerV3VaultTest.createPoolFactory():: Entering function.");
        PoolFactoryMock factoryMock = PoolFactoryMock(address(vault.getPoolFactoryMock()));
        vm.label(address(factoryMock), "factory");
        // console.log("BetterBalancerV3VaultTest.createPoolFactory():: Exiting function.");
        return address(factoryMock);
    }

    function createPool() internal virtual returns (address, bytes memory) {
        // console.log("BetterBalancerV3VaultTest.createPool():: Entering function.");
        // console.log("BetterBalancerV3VaultTest.createPool():: Creating pool.");
        // console.log("BetterBalancerV3VaultTest.createPool():: Exiting function.");
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
        // console.log("BetterBalancerV3VaultTest.createHook():: Entering function.");
        // Sets all flags to false.
        HookFlags memory hookFlags;
        // console.log("BetterBalancerV3VaultTest.createHook():: Exiting function.");
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

    function createLiquidityBuffer(
        IERC4626 erc4626_,
        uint256 underlyingAmount,
        uint256 wrappedAmount,
        uint256 minIssuedShares
    ) public virtual returns (uint256 bufferShares) {
        return bufferShares = bufferRouter.initializeBuffer(
            erc4626_,
            underlyingAmount,
            wrappedAmount,
            minIssuedShares
        );
    }

    function createLiquidityBuffer(
        IERC4626 erc4626_,
        uint256 underlyingAmount,
        uint256 wrappedAmount
    ) public virtual returns (uint256 bufferShares) {
        return createLiquidityBuffer(
            erc4626_,
            underlyingAmount,
            wrappedAmount,
            0
        );
    }

    // ------------------------------ Helpers ------------------------------
    function setSwapFeePercentage(uint256 percentage) internal {
        // console.log("BetterBalancerV3VaultTest.setSwapFeePercentage():: Entering function.");
        _setSwapFeePercentage(pool, percentage);
        // console.log("BetterBalancerV3VaultTest.setSwapFeePercentage():: Exiting function.");
    }

    function _setSwapFeePercentage(address setPool, uint256 percentage) internal {
        vault.manualUnsafeSetStaticSwapFeePercentage(setPool, percentage);
    }

    function getBalances(address user) internal view returns (Balances memory balances) {
        return getBalances(user, Rounding.ROUND_DOWN);
    }

    function getBalances(address user, Rounding invariantRounding) internal view returns (Balances memory balances) {
        // console.log("BetterBalancerV3VaultTest.getBalances(address, Rounding):: Entering function.");
        balances.userBpt = IERC20(pool).balanceOf(user);
        balances.aliceBpt = IERC20(pool).balanceOf(alice);
        balances.bobBpt = IERC20(pool).balanceOf(bob);
        balances.hookBpt = IERC20(pool).balanceOf(poolHooksContract);
        balances.lpBpt = IERC20(pool).balanceOf(lp);

        balances.poolSupply = IERC20(pool).totalSupply();

        (IERC20[] memory tokens, , uint256[] memory poolBalances, uint256[] memory lastBalancesLiveScaled18) = vault
            .getPoolTokenInfo(pool);
        balances.poolTokens = poolBalances;
        uint256 numTokens = tokens.length;

        balances.poolInvariant = IBasePool(pool).computeInvariant(lastBalancesLiveScaled18, invariantRounding);
        balances.poolEth = pool.balance;

        _fillBalances(balances, user, tokens);

        balances.swapFeeAmounts = new uint256[](numTokens);
        balances.yieldFeeAmounts = new uint256[](numTokens);
        for (uint256 i = 0; i < numTokens; ++i) {
            balances.swapFeeAmounts[i] = vault.manualGetAggregateSwapFeeAmount(pool, tokens[i]);
            balances.yieldFeeAmounts[i] = vault.manualGetAggregateYieldFeeAmount(pool, tokens[i]);
        }
        // console.log("BetterBalancerV3VaultTest.getBalances(address, Rounding):: Exiting function.");
    }

    /// @dev A different function is needed to measure token balances when tracking tokens across multiple pools.
    function getBalances(address user, IERC20[] memory tokensToTrack) internal view returns (Balances memory balances) {
        // console.log("BetterBalancerV3VaultTest.getBalances(address, IERC20[]):: Entering function.");
        balances.userBpt = IERC20(pool).balanceOf(user);
        balances.aliceBpt = IERC20(pool).balanceOf(alice);
        balances.bobBpt = IERC20(pool).balanceOf(bob);
        balances.hookBpt = IERC20(pool).balanceOf(poolHooksContract);
        balances.lpBpt = IERC20(pool).balanceOf(lp);

        _fillBalances(balances, user, tokensToTrack);
        // console.log("BetterBalancerV3VaultTest.getBalances(address, IERC20[]):: Exiting function.");
    }

    function _fillBalances(Balances memory balances, address user, IERC20[] memory tokens) private view {
        uint256 numTokens = tokens.length;

        balances.userTokens = new uint256[](numTokens);
        balances.userEth = user.balance;
        balances.aliceTokens = new uint256[](numTokens);
        balances.aliceEth = alice.balance;
        balances.bobTokens = new uint256[](numTokens);
        balances.bobEth = bob.balance;
        balances.hookTokens = new uint256[](numTokens);
        balances.hookEth = poolHooksContract.balance;
        balances.lpTokens = new uint256[](numTokens);
        balances.lpEth = lp.balance;
        balances.vaultTokens = new uint256[](numTokens);
        balances.vaultEth = address(vault).balance;
        balances.vaultReserves = new uint256[](numTokens);

        for (uint256 i = 0; i < numTokens; ++i) {
            // Don't assume token ordering.
            balances.userTokens[i] = tokens[i].balanceOf(user);
            balances.aliceTokens[i] = tokens[i].balanceOf(alice);
            balances.bobTokens[i] = tokens[i].balanceOf(bob);
            balances.hookTokens[i] = tokens[i].balanceOf(poolHooksContract);
            balances.lpTokens[i] = tokens[i].balanceOf(lp);
            balances.vaultTokens[i] = tokens[i].balanceOf(address(vault));
            balances.vaultReserves[i] = vault.getReservesOf(tokens[i]);
        }
    }

    function getSalt(address addr) internal pure returns (bytes32) {
        // console.log("BetterBalancerV3VaultTest.getSalt():: Entering function.");
        bytes32 salt = bytes32(uint256(uint160(addr)));
        // console.log("BetterBalancerV3VaultTest.getSalt():: Exiting function.");
        return salt;
    }

    function _vaultPreviewDeposit(
        IERC4626 wrapper,
        uint256 amountInUnderlying
    ) internal returns (uint256 amountOutWrapped) {
        _prankStaticCall();
        return vault.previewDeposit(wrapper, amountInUnderlying);
    }

    function _vaultPreviewMint(
        IERC4626 wrapper,
        uint256 amountOutWrapped
    ) internal returns (uint256 amountInUnderlying) {
        _prankStaticCall();
        return vault.previewMint(wrapper, amountOutWrapped);
    }

    function _vaultPreviewRedeem(
        IERC4626 wrapper,
        uint256 amountInWrapped
    ) internal returns (uint256 amountOutUnderlying) {
        _prankStaticCall();
        return vault.previewRedeem(wrapper, amountInWrapped);
    }

    function _vaultPreviewWithdraw(
        IERC4626 wrapper,
        uint256 amountOutUnderlying
    ) internal returns (uint256 amountInWrapped) {
        _prankStaticCall();
        return vault.previewWithdraw(wrapper, amountOutUnderlying);
    }

    function _prankStaticCall() internal {
        // Prank address 0x0 for both msg.sender and tx.origin (to identify as a staticcall).
        vm.prank(address(0), address(0));
    }
    
}