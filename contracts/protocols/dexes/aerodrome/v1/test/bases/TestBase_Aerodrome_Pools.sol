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
    // Aerodrome test tokens - Balanced
    ERC20PermitMintableStub aeroBalancedTokenA;
    ERC20PermitMintableStub aeroBalancedTokenB;

    // Aerodrome test tokens - Unbalanced
    ERC20PermitMintableStub aeroUnbalancedTokenA;
    ERC20PermitMintableStub aeroUnbalancedTokenB;

    // Aerodrome test tokens - Extreme Unbalanced
    ERC20PermitMintableStub aeroExtremeTokenA;
    ERC20PermitMintableStub aeroExtremeTokenB;

    // Aerodrome pools
    Pool aeroBalancedPool;
    Pool aeroUnbalancedPool;
    Pool aeroExtremeUnbalancedPool;

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
    }

    function _createAerodromePools() internal {
        address poolAddr1 = aerodromePoolFactory.createPool(address(aeroBalancedTokenA), address(aeroBalancedTokenB), false);
        aeroBalancedPool = Pool(poolAddr1);
        vm.label(poolAddr1, string.concat("AerodromeBalancedPool - ", aeroBalancedTokenA.symbol(), " / ", aeroBalancedTokenB.symbol()));

        address poolAddr2 = aerodromePoolFactory.createPool(address(aeroUnbalancedTokenA), address(aeroUnbalancedTokenB), false);
        aeroUnbalancedPool = Pool(poolAddr2);
        vm.label(poolAddr2, string.concat("AerodromeUnbalancedPool - ", aeroUnbalancedTokenA.symbol(), " / ", aeroUnbalancedTokenB.symbol()));

        address poolAddr3 = aerodromePoolFactory.createPool(address(aeroExtremeTokenA), address(aeroExtremeTokenB), false);
        aeroExtremeUnbalancedPool = Pool(poolAddr3);
        vm.label(poolAddr3, string.concat("AerodromeExtremeUnbalancedPool - ", aeroExtremeTokenA.symbol(), " / ", aeroExtremeTokenB.symbol()));
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

}
