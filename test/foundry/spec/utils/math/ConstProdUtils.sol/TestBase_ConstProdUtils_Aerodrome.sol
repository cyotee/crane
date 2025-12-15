// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/// forge-lint: disable-next-line(unaliased-plain-import)
import "forge-std/Test.sol";
import {TestBase_Aerodrome} from "contracts/protocols/dexes/aerodrome/v1/test/bases/TestBase_Aerodrome.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {Pool} from "contracts/protocols/dexes/aerodrome/v1/Pool.sol";

contract TestBase_ConstProdUtils_Aerodrome is TestBase_Aerodrome {
    // Aerodrome test tokens
    ERC20PermitMintableStub aeroTokenA;
    ERC20PermitMintableStub aeroTokenB;

    // Aerodrome pool
    Pool aeroPool;

    uint256 constant INITIAL_LIQUIDITY = 10000e18;
    uint256 constant TEST_AMOUNT = 1000e18;

    function setUp() public virtual override {
        TestBase_Aerodrome.setUp();
        _createAerodromeTokens();
        _createAerodromePool();
    }

    function _createAerodromeTokens() internal {
        aeroTokenA = new ERC20PermitMintableStub("AerodromeTokenA", "AEROA", 18, address(this), 0);
        vm.label(address(aeroTokenA), "AerodromeTokenA");

        aeroTokenB = new ERC20PermitMintableStub("AerodromeTokenB", "AEROB", 18, address(this), 0);
        vm.label(address(aeroTokenB), "AerodromeTokenB");
    }

    function _createAerodromePool() internal {
        address poolAddr = factory.createPool(address(aeroTokenA), address(aeroTokenB), false);
        aeroPool = Pool(poolAddr);
        vm.label(poolAddr, "AerodromePool");
    }

    function _initializeAerodromeBalancedPool() internal {
        aeroTokenA.mint(address(this), INITIAL_LIQUIDITY);
        aeroTokenB.mint(address(this), INITIAL_LIQUIDITY);
        aeroTokenA.approve(address(router), INITIAL_LIQUIDITY);
        aeroTokenB.approve(address(router), INITIAL_LIQUIDITY);

        // Use the Aerodrome Router to add liquidity
        router.addLiquidity(address(aeroTokenA), address(aeroTokenB), false, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY, 1, 1, address(this), block.timestamp);
    }

    function _initializeAerodromeUnbalancedPool() internal {
        aeroTokenA.mint(address(this), INITIAL_LIQUIDITY);
        aeroTokenB.mint(address(this), INITIAL_LIQUIDITY / 10);
        aeroTokenA.approve(address(router), INITIAL_LIQUIDITY);
        aeroTokenB.approve(address(router), INITIAL_LIQUIDITY / 10);

        router.addLiquidity(address(aeroTokenA), address(aeroTokenB), false, INITIAL_LIQUIDITY, INITIAL_LIQUIDITY / 10, 1, 1, address(this), block.timestamp);
    }
}
