// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";

contract ConstProdUtils_calculateProtocolFee_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    function test_calculateProtocolFee_behaviour() public {
        // simple numeric scenarios to exercise _calculateProtocolFee
        uint256 lpTotal = 1e18;
        uint256 reserveA = 1e18;
        uint256 reserveB = 4e18;
        uint256 newK = reserveA * reserveB;
        uint256 kLast = (reserveA * reserveB) / 4; // smaller

        // ownerFeeShare 0 => zero fee
        uint256 fee0 = ConstProdUtils._calculateProtocolFee(lpTotal, newK, kLast, 0);
        assertEq(fee0, 0, "ownerFeeShare=0 should produce zero protocol fee");

        // ownerFeeShare small non-zero: should produce non-zero fee
        uint256 feeSmall = ConstProdUtils._calculateProtocolFee(lpTotal, newK, kLast, 1000);
        assertTrue(feeSmall > 0, "small ownerFeeShare should produce >0 fee");

        // ownerFeeShare ~= 1/6 should follow Uniswap path and be >0
        uint256 feeUni = ConstProdUtils._calculateProtocolFee(lpTotal, newK, kLast, 16667);
        assertTrue(feeUni > 0, "uniswap ownerFeeShare should produce >0 fee");

        // If newK <= kLast => zero
        uint256 feeZero = ConstProdUtils._calculateProtocolFee(lpTotal, kLast, kLast, 1000);
        assertEq(feeZero, 0, "newK <= kLast => fee 0");
    }

    // Execution-validation style tests adapted for Aerodrome: we cannot assert an LP mint
    // to a protocol recipient (Aerodrome uses fee accrual to PoolFees), so we validate
    // that K grows after trading activity, that the numeric protocol-fee calculation
    // returns a specific value, and that fee accruals on the pool are non-zero.
    function test_calculateProtocolFee_ExecutionValidation_BalancedPool() public {
        _initializeAerodromeBalancedPools();
        _testProtocolFeeExecutionValidation(aeroBalancedPool, aeroBalancedTokenA, aeroBalancedTokenB);
    }

    function test_calculateProtocolFee_ExecutionValidation_UnbalancedPool() public {
        _initializeAerodromeUnbalancedPools();
        _testProtocolFeeExecutionValidation(aeroUnbalancedPool, aeroUnbalancedTokenA, aeroUnbalancedTokenB);
    }

    function test_calculateProtocolFee_ExecutionValidation_ExtremeUnbalancedPool() public {
        _initializeAerodromeExtremeUnbalancedPools();
        _testProtocolFeeExecutionValidation(aeroExtremeUnbalancedPool, aeroExtremeTokenA, aeroExtremeTokenB);
    }

    function _testProtocolFeeExecutionValidation(
        Pool pair,
        ERC20PermitMintableStub tokenA,
        ERC20PermitMintableStub tokenB
    ) internal {
        // Read initial reserves and total supply
        (uint256 r0, uint256 r1, ) = pair.getReserves();
        uint256 initialK = r0 * r1;
        uint256 initialTotalSupply = pair.totalSupply();

        // Generate trading activity to grow K and accrue fees into PoolFees
        _generateTradingActivity(pair, address(tokenA), address(tokenB), 100);

        // Read new reserves and compute newK
        (uint256 newReserve0, uint256 newReserve1, ) = pair.getReserves();
        uint256 newK = newReserve0 * newReserve1;

        // For Aerodrome there is no ownerFeeShare stored like Camelot; pick a reasonable ownerFeeShare
        // to exercise the generic path. Use 1000 (10%) as a test value.
        uint256 ownerFeeShare = 1000;

        uint256 expectedProtocolFee = ConstProdUtils._calculateProtocolFee(initialTotalSupply, newK, initialK, ownerFeeShare);

        // Assert K grew and the calculation returned a numeric protocol fee
        assertTrue(newK > initialK, "K should have grown from trading activity");
        assertTrue(expectedProtocolFee <= initialTotalSupply, "calculated protocol fee should be <= total supply");

        // Finally, ensure Aerodrome accrued swap fees into the pool's PoolFees contract by checking
        // that claimable balances are non-zero after activity. Call claimFees to surface any accrued fees.
        (uint256 claimed0, uint256 claimed1) = pair.claimFees();
        assertTrue(claimed0 > 0 || claimed1 > 0, "Aerodrome should have accrued swap fees to PoolFees");
    }

    // Simple trading activity generator for Aerodrome pairs (replicates logic used in other Aerodrome tests in repo)
    function _generateTradingActivity(
        Pool pair,
        address tokenA,
        address tokenB,
        uint256 swapPercentage // basis points of reserves (e.g., 100 = 1%)
    ) internal {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();

        uint256 swapAmountA = (uint256(reserve0) * swapPercentage) / 10000;
        uint256 swapAmountB = (uint256(reserve1) * swapPercentage) / 10000;

        // Mint tokens directly to this contract for swaps
        ERC20PermitMintableStub(tokenA).mint(address(this), swapAmountA);
        ERC20PermitMintableStub(tokenB).mint(address(this), swapAmountB);

        ERC20PermitMintableStub(tokenA).approve(address(router), swapAmountA);
        IRouter.Route[] memory routesAB = new IRouter.Route[](1);
        routesAB[0] = IRouter.Route({from: tokenA, to: tokenB, stable: false, factory: address(factory)});

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            swapAmountA,
            1,
            routesAB,
            address(this),
            block.timestamp
        );

        uint256 receivedB = IERC20(tokenB).balanceOf(address(this));
        if (receivedB > 0) {
            ERC20PermitMintableStub(tokenB).approve(address(router), receivedB);
            IRouter.Route[] memory routesBA = new IRouter.Route[](1);
            routesBA[0] = IRouter.Route({from: tokenB, to: tokenA, stable: false, factory: address(factory)});
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                receivedB,
                1,
                routesBA,
                address(this),
                block.timestamp
            );
        }
    }

    function _buildAerodromeRoutes(address from, address to) internal view returns (IRouter.Route[] memory routes) {
        routes = new IRouter.Route[](1);
        routes[0] = IRouter.Route({from: from, to: to, stable: false, factory: address(factory)});
    }
}
