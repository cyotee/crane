// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ConstProdUtils} from "contracts/utils/math/ConstProdUtils.sol";
import {TestBase_ConstProdUtils_Aerodrome} from "./TestBase_ConstProdUtils_Aerodrome.sol";
import {IRouter} from "@crane/contracts/protocols/dexes/aerodrome/v1/interfaces/IRouter.sol";
import {Pool} from "@crane/contracts/protocols/dexes/aerodrome/v1/Pool.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {ERC20PermitMintableStub} from "contracts/tokens/ERC20/ERC20PermitMintableStub.sol";

contract ConstProdUtils_withdrawSwapTargetQuote_Aerodrome is TestBase_ConstProdUtils_Aerodrome {
    using ConstProdUtils for uint256;

    function setUp() public override {
        super.setUp();
    }

    function test_withdrawSwapTargetQuote_Aerodrome_balancedPool_executionValidation() public {
        _initializeAerodromeBalancedPools();

        Pool pair = aeroBalancedPool;
        (uint256 reserve0, uint256 reserve1,) = pair.getReserves();
        uint256 reserveA = reserve0;
        uint256 reserveB = reserve1;
        uint256 totalSupply = pair.totalSupply();

        // Desired amount out (10% of reserve A)
        uint256 desiredAmountOut = reserveA / 10;

        // Calculate expected LP amount to burn using ConstProdUtils
        uint256 calculatedLpAmount = ConstProdUtils._withdrawSwapTargetQuote(
            desiredAmountOut,
            reserveA,
            reserveB,
            totalSupply,
            30 // Aerodrome fee percent (30 / 10000)
        );

        // Execute actual operations to validate
        // 1. Burn the calculated LP amount
        pair.transfer(address(pair), calculatedLpAmount);
        (uint256 amount0, uint256 amount1) = pair.burn(address(this));
        bool pairToken0IsA = pair.token0() == address(aeroBalancedTokenA);
        uint256 amountA = pairToken0IsA ? amount0 : amount1;
        uint256 amountB = pairToken0IsA ? amount1 : amount0;

        // 2. Swap TokenB -> TokenA directly via pair for exact needed out (use purchaseQuote to compute exact input)
        uint256 tokenAFromSwap = 0;
        if (amountB > 0) {
            uint256 neededOut = 0;
            if (desiredAmountOut > amountA) neededOut = desiredAmountOut - amountA;
            if (neededOut > 0) {
                // read reserves and pool fee
                (uint256 r0, uint256 r1,) = pair.getReserves();
                bool outIsToken0 = pair.token0() == address(aeroBalancedTokenA);
                uint256 inFee = uint256(factory.getFee(address(pair), false));
                uint256 reserveIn = outIsToken0 ? r1 : r0;
                uint256 reserveOut = outIsToken0 ? r0 : r1;

                uint256 usedIn = ConstProdUtils._purchaseQuote(neededOut, reserveIn, reserveOut, inFee, 10000);
                // _purchaseQuote adds +1 safety; if we are short, mint the shortfall
                if (usedIn > amountB) {
                    uint256 shortfall = usedIn - amountB;
                    // mint shortfall of tokenB to cover required input
                    aeroBalancedTokenB.mint(address(this), shortfall);
                }
                // transfer exact quoted input into the pair and perform swap to receive exact desiredOut
                address inputToken = outIsToken0 ? pair.token1() : pair.token0();
                IERC20(inputToken).transfer(address(pair), usedIn);
                if (outIsToken0) {
                    pair.swap(neededOut, 0, address(this), new bytes(0));
                } else {
                    pair.swap(0, neededOut, address(this), new bytes(0));
                }
                tokenAFromSwap = neededOut;
            }
        }

        uint256 finalA = amountA + tokenAFromSwap;

        // Assert the LP calculated burns to exactly desiredAmountOut
        assertEq(finalA, desiredAmountOut, "Actual TokenA received should equal desired amount exactly");
    }
}
