// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {Currency} from "@crane/contracts/protocols/dexes/uniswap/v4/types/Currency.sol";
import {Hooks} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/Hooks.sol";
import {MockERC20} from "@crane/contracts/test/mocks/MockERC20.sol";
import {MockV4FeeAdapter} from "../mocks/MockV4FeeAdapter.sol";
import {MockFluidDexT1} from "./mocks/MockFluidDexT1.sol";
import {MockFluidDexReservesResolver} from "./mocks/MockFluidDexReservesResolver.sol";
import {FluidDexT1Aggregator} from "@crane/contracts/protocols/dexes/uniswap/v4/hooks/public/aggregator-hooks/implementations/FluidDexT1/FluidDexT1Aggregator.sol";
import {
    FluidDexT1AggregatorFactory
} from "@crane/contracts/protocols/dexes/uniswap/v4/hooks/public/aggregator-hooks/implementations/FluidDexT1/FluidDexT1AggregatorFactory.sol";
import {
    IFluidDexResolver
} from "@crane/contracts/protocols/dexes/uniswap/v4/hooks/public/aggregator-hooks/implementations/FluidDexT1/interfaces/IFluidDexResolver.sol";
import {HookMiner} from "@crane/contracts/protocols/dexes/uniswap/v4/hooks/public/utils/HookMiner.sol";

contract FluidDexT1FactoryUnitTest is Test {
    IPoolManager public poolManager;
    MockV4FeeAdapter public feeAdapter;
    MockFluidDexT1 public mockPool;
    MockFluidDexReservesResolver public mockResolver;
    MockERC20 public token0;
    MockERC20 public token1;

    uint24 constant FEE = 3000; // 0.3%
    int24 constant TICK_SPACING = 60; // Default tick spacing for a 0.3% fee pool
    uint160 constant SQRT_PRICE_1_1 = 79228162514264337593543950336; // 1:1

    address public fluidLiquidity = makeAddr("fluidLiquidity");

    function setUp() public {
        poolManager =
            IPoolManager(vm.deployCode("contracts/protocols/dexes/uniswap/v4/PoolManager.sol:PoolManager", abi.encode(address(this))));
        mockPool = new MockFluidDexT1();
        mockResolver = new MockFluidDexReservesResolver();
        feeAdapter = new MockV4FeeAdapter(poolManager, address(this));

        token0 = new MockERC20("Token0", "TK0", 18);
        token1 = new MockERC20("Token1", "TK1", 18);
        if (address(token0) > address(token1)) (token0, token1) = (token1, token0);

        mockResolver.setDexTokens(address(token0), address(token1));
        mockPool.setTokens(address(token0), address(token1));
    }

    function test_factory_createPool() public {
        FluidDexT1AggregatorFactory factory = new FluidDexT1AggregatorFactory(
            poolManager, mockResolver, IFluidDexResolver(address(mockResolver)), fluidLiquidity
        );

        MockERC20 tkA = new MockERC20("A", "A", 18);
        MockERC20 tkB = new MockERC20("B", "B", 18);
        if (address(tkA) > address(tkB)) (tkA, tkB) = (tkB, tkA);

        MockFluidDexT1 pool2 = new MockFluidDexT1();
        mockResolver.setDexTokens(address(tkA), address(tkB));

        bytes memory args = abi.encode(
            address(poolManager), address(pool2), address(mockResolver), address(mockResolver), fluidLiquidity
        );
        (, bytes32 factorySalt) = HookMiner.find(
            address(factory),
            uint160(
                Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG | Hooks.BEFORE_INITIALIZE_FLAG
                    | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
            ),
            type(FluidDexT1Aggregator).creationCode,
            args
        );

        address hookAddr = factory.createPool(
            factorySalt,
            pool2,
            Currency.wrap(address(tkA)),
            Currency.wrap(address(tkB)),
            FEE,
            TICK_SPACING,
            SQRT_PRICE_1_1
        );
        assertTrue(hookAddr != address(0));
    }

    function test_factory_computeAddress_matchesDeployedAddress() public {
        FluidDexT1AggregatorFactory factory = new FluidDexT1AggregatorFactory(
            poolManager, mockResolver, IFluidDexResolver(address(mockResolver)), fluidLiquidity
        );

        bytes memory args = abi.encode(
            address(poolManager), address(mockPool), address(mockResolver), address(mockResolver), fluidLiquidity
        );
        (, bytes32 factorySalt) = HookMiner.find(
            address(factory),
            uint160(
                Hooks.BEFORE_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG | Hooks.BEFORE_INITIALIZE_FLAG
                    | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
            ),
            type(FluidDexT1Aggregator).creationCode,
            args
        );

        address computed = factory.computeAddress(factorySalt, mockPool);
        address deployed = factory.createPool(
            factorySalt,
            mockPool,
            Currency.wrap(address(token0)),
            Currency.wrap(address(token1)),
            FEE,
            TICK_SPACING,
            SQRT_PRICE_1_1
        );

        assertEq(computed, deployed);
    }
}
