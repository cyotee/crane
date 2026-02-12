// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
import {TestBase_Aerodrome} from "@crane/contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol";
import {ERC20PermitMintableStub} from "@crane/contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Pool.sol";
import {Aero} from "@crane/contracts/protocols/dexes/aerodrome/v1/stubs/Aero.sol";

contract TestBase_Aerodrome_Pools is TestBase_Aerodrome {
    // Aerodrome test tokens - Balanced (Volatile)
    ERC20PermitMintableStub aeroBalancedTokenA;
    ERC20PermitMintableStub aeroBalancedTokenB;

    // Aerodrome test tokens - Unbalanced (Volatile)
    ERC20PermitMintableStub aeroUnbalancedTokenA;
    ERC20PermitMintableStub aeroUnbalancedTokenB;

    // Aerodrome test tokens - Extreme Unbalanced (Volatile)
    ERC20PermitMintableStub aeroExtremeTokenA;
    ERC20PermitMintableStub aeroExtremeTokenB;

    // Aerodrome test tokens - Stable pools
    ERC20PermitMintableStub aeroStableTokenA;
    ERC20PermitMintableStub aeroStableTokenB;

    // Aerodrome volatile pools
    Pool aeroBalancedPool;
    Pool aeroUnbalancedPool;
    Pool aeroExtremeUnbalancedPool;

    // Aerodrome stable pools
    Pool aeroStablePool;

    // Standard test amounts
    uint256 constant INITIAL_LIQUIDITY = 10000e18;
    uint256 constant TEST_AMOUNT = 1000e18;

    // Unbalanced pool ratios
    uint256 constant UNBALANCED_RATIO_A = 10000e18; // 10,000 tokens
    uint256 constant UNBALANCED_RATIO_B = 1000e18; // 1,000 tokens (10:1 ratio)
    uint256 constant UNBALANCED_RATIO_C = 100e18; // 100 tokens (100:1 ratio)

    function setUp() public virtual override {

        TestBase_Aerodrome.setUp();
        _createAerodromeTokens();
        _createAerodromePools();
    }

    function _createAerodromeTokens() internal {
        aeroBalancedTokenA = new ERC20PermitMintableStub("AerodromeBalancedTokenA", "AEROBALA", 18, address(this), 0);
        vm.label(address(aeroBalancedTokenA), "AerodromeBalancedTokenA");

        aeroBalancedTokenB = new ERC20PermitMintableStub("AerodromeBalancedTokenB", "AEROBALB", 18, address(this), 0);
        vm.label(address(aeroBalancedTokenB), "AerodromeBalancedTokenB");

        aeroUnbalancedTokenA = new ERC20PermitMintableStub("AerodromeUnbalancedTokenA", "AEROUNA", 18, address(this), 0);
        vm.label(address(aeroUnbalancedTokenA), "AerodromeUnbalancedTokenA");

        aeroUnbalancedTokenB = new ERC20PermitMintableStub("AerodromeUnbalancedTokenB", "AEROUNB", 18, address(this), 0);
        vm.label(address(aeroUnbalancedTokenB), "AerodromeUnbalancedTokenB");

        aeroExtremeTokenA = new ERC20PermitMintableStub("AerodromeExtremeTokenA", "AEROEXA", 18, address(this), 0);
        vm.label(address(aeroExtremeTokenA), "AerodromeExtremeTokenA");

        aeroExtremeTokenB = new ERC20PermitMintableStub("AerodromeExtremeTokenB", "AEROEXB", 18, address(this), 0);
        vm.label(address(aeroExtremeTokenB), "AerodromeExtremeTokenB");

        // Stable pool tokens (simulating stablecoins with same decimals)
        aeroStableTokenA = new ERC20PermitMintableStub("AerodromeStableTokenA", "AEROSTA", 18, address(this), 0);
        vm.label(address(aeroStableTokenA), "AerodromeStableTokenA");

        aeroStableTokenB = new ERC20PermitMintableStub("AerodromeStableTokenB", "AEROSTB", 18, address(this), 0);
        vm.label(address(aeroStableTokenB), "AerodromeStableTokenB");
    }

    function _createAerodromePools() internal {
        // Volatile pools (stable: false)
        address poolAddr1 = aerodromePoolFactory.createPool(address(aeroBalancedTokenA), address(aeroBalancedTokenB), false);
        aeroBalancedPool = Pool(poolAddr1);
        vm.label(poolAddr1, string.concat("AerodromeBalancedPool - ", aeroBalancedTokenA.symbol(), " / ", aeroBalancedTokenB.symbol()));

        address poolAddr2 = aerodromePoolFactory.createPool(address(aeroUnbalancedTokenA), address(aeroUnbalancedTokenB), false);
        aeroUnbalancedPool = Pool(poolAddr2);
        vm.label(poolAddr2, string.concat("AerodromeUnbalancedPool - ", aeroUnbalancedTokenA.symbol(), " / ", aeroUnbalancedTokenB.symbol()));

        address poolAddr3 = aerodromePoolFactory.createPool(address(aeroExtremeTokenA), address(aeroExtremeTokenB), false);
        aeroExtremeUnbalancedPool = Pool(poolAddr3);
        vm.label(poolAddr3, string.concat("AerodromeExtremeUnbalancedPool - ", aeroExtremeTokenA.symbol(), " / ", aeroExtremeTokenB.symbol()));

        // Stable pool (stable: true)
        address poolAddr4 = aerodromePoolFactory.createPool(address(aeroStableTokenA), address(aeroStableTokenB), true);
        aeroStablePool = Pool(poolAddr4);
        vm.label(poolAddr4, string.concat("AerodromeStablePool - ", aeroStableTokenA.symbol(), " / ", aeroStableTokenB.symbol()));
    }

    function _initializeAerodromeBalancedPools() internal {
        aeroBalancedTokenA.mint(address(this), INITIAL_LIQUIDITY);
        aeroBalancedTokenA.approve(address(aerodromeRouter), INITIAL_LIQUIDITY);
        aeroBalancedTokenB.mint(address(this), INITIAL_LIQUIDITY);
        aeroBalancedTokenB.approve(address(aerodromeRouter), INITIAL_LIQUIDITY);

        aerodromeRouter.addLiquidity(address(aeroBalancedTokenA), address(aeroBalancedTokenB), false, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY, 1, 1, address(this), block.timestamp);
    }

    function _initializeAerodromeUnbalancedPools() internal {
        aeroUnbalancedTokenA.mint(address(this), UNBALANCED_RATIO_A);
        aeroUnbalancedTokenA.approve(address(aerodromeRouter), UNBALANCED_RATIO_A);
        aeroUnbalancedTokenB.mint(address(this), UNBALANCED_RATIO_B);
        aeroUnbalancedTokenB.approve(address(aerodromeRouter), UNBALANCED_RATIO_B);

        aerodromeRouter.addLiquidity(address(aeroUnbalancedTokenA), address(aeroUnbalancedTokenB), false, UNBALANCED_RATIO_A, UNBALANCED_RATIO_B, 1, 1, address(this), block.timestamp);
    }

    function _initializeAerodromeExtremeUnbalancedPools() internal {
        aeroExtremeTokenA.mint(address(this), UNBALANCED_RATIO_A);
        aeroExtremeTokenA.approve(address(aerodromeRouter), UNBALANCED_RATIO_A);
        aeroExtremeTokenB.mint(address(this), UNBALANCED_RATIO_C);
        aeroExtremeTokenB.approve(address(aerodromeRouter), UNBALANCED_RATIO_C);

        aerodromeRouter.addLiquidity(address(aeroExtremeTokenA), address(aeroExtremeTokenB), false, UNBALANCED_RATIO_A, UNBALANCED_RATIO_C, 1, 1, address(this), block.timestamp);
    }

    function _executeAerodromeTradesToGenerateFees(ERC20PermitMintableStub tokenA, ERC20PermitMintableStub tokenB) internal {
        uint256 swapAmountA = 100e18;
        tokenA.mint(address(this), swapAmountA);
        tokenA.approve(address(aerodromeRouter), swapAmountA);

        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route({from: address(tokenA), to: address(tokenB), stable: false, factory: address(aerodromePoolFactory)});

        aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            0,
            routes,
            address(this),
            block.timestamp + 300
        );

        uint256 balanceB = tokenB.balanceOf(address(this));
        if (balanceB > 0) {
            tokenB.approve(address(aerodromeRouter), balanceB);
            IRouter.Route[] memory routesRev = new IRouter.Route[](1);
            routesRev[0] = IRouter.Route({from: address(tokenB), to: address(tokenA), stable: false, factory: address(aerodromePoolFactory)});
            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balanceB,
                0,
                routesRev,
                address(this),
                block.timestamp + 300
            );
        }

        uint256 balanceA = tokenA.balanceOf(address(this));
        if (balanceA > 0) {
            tokenA.approve(address(aerodromeRouter), balanceA);
            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balanceA,
                0,
                routes,
                address(this),
                block.timestamp + 300
            );
        }
    }

    /// @notice Initialize stable pool with 1:1 ratio (like stablecoins)
    function _initializeAerodromeStablePool() internal {
        aeroStableTokenA.mint(address(this), INITIAL_LIQUIDITY);
        aeroStableTokenA.approve(address(aerodromeRouter), INITIAL_LIQUIDITY);
        aeroStableTokenB.mint(address(this), INITIAL_LIQUIDITY);
        aeroStableTokenB.approve(address(aerodromeRouter), INITIAL_LIQUIDITY);

        // Note: stable pools require equal value deposits (1:1 for same-decimals tokens)
        aerodromeRouter.addLiquidity(
            address(aeroStableTokenA),
            address(aeroStableTokenB),
            true, // stable: true
            INITIAL_LIQUIDITY,
            INITIAL_LIQUIDITY,
            1,
            1,
            address(this),
            block.timestamp
        );
    }

    /// @notice Execute trades on a stable pool to generate fees
    function _executeAerodromeStableTradesToGenerateFees() internal {
        uint256 swapAmountA = 100e18;
        aeroStableTokenA.mint(address(this), swapAmountA);
        aeroStableTokenA.approve(address(aerodromeRouter), swapAmountA);

        IRouter.Route[] memory routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route({
            from: address(aeroStableTokenA),
            to: address(aeroStableTokenB),
            stable: true, // stable pool
            factory: address(aerodromePoolFactory)
        });

        aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            0,
            routes,
            address(this),
            block.timestamp + 300
        );

        uint256 balanceB = aeroStableTokenB.balanceOf(address(this));
        if (balanceB > 0) {
            aeroStableTokenB.approve(address(aerodromeRouter), balanceB);
            IRouter.Route[] memory routesRev = new IRouter.Route[](1);
            routesRev[0] = IRouter.Route({
                from: address(aeroStableTokenB),
                to: address(aeroStableTokenA),
                stable: true,
                factory: address(aerodromePoolFactory)
            });
            aerodromeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                balanceB,
                0,
                routesRev,
                address(this),
                block.timestamp + 300
            );
        }
    }

}
