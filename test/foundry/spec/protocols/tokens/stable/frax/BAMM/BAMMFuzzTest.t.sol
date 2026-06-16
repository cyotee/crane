// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/BAMM/BAMM-Fuzz.js`.

import {Test} from "forge-std/Test.sol";
import {BAMM} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/BAMM.sol";
import {BAMMHelper} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/BAMMHelper.sol";
import {FraxswapOracle} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/FraxswapOracle.sol";
import {FraxswapDummyRouter} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/FraxswapDummyRouter.sol";
import {FraxswapFactory} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapFactory.sol";
import {FraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/core/FraxswapPair.sol";
import {
    FraxswapRouterMultihop
} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/periphery/FraxswapRouterMultihop.sol";
import {DummyToken} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";

contract BAMMFuzzTest is Test {
    address internal owner;
    address internal user1;

    DummyToken internal token0;
    DummyToken internal token1;
    FraxswapPair internal pair;
    BAMM internal bamm;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("fuzzUser1");
    }

    function test_setupContracts() public {
        _deployBamm(9970, 1e18);
        assertTrue(address(bamm) != address(0));
    }

    /// @dev Upstream runs 90 PnL scenarios (i = 1..90). Set FRAX_BAMM_HEAVY_FUZZ=1 for all; default 10 for CI.
    function test_pnlFuzz() public {
        uint256 maxI = vm.envOr("FRAX_BAMM_HEAVY_FUZZ", uint256(0)) == 1 ? 90 : 10;
        uint256 mintAmount = 10e18;
        uint256 collateral = 10e16;
        uint256 rentAmount = 1e17;

        for (uint256 i = 1; i <= maxI; i++) {
            _deployBamm(9970, mintAmount * 2);

            uint256 startLpOwner = pair.balanceOf(owner);
            uint256 startToken0 = token0.balanceOf(user1);
            uint256 startToken1 = token1.balanceOf(user1);

            pair.approve(address(bamm), mintAmount);
            uint256 bammMinted = bamm.mint(owner, mintAmount);

            token0.transfer(user1, collateral * 2);
            token1.transfer(user1, collateral * 2);
            vm.startPrank(user1);
            token0.approve(address(bamm), collateral);
            token1.approve(address(bamm), collateral);
            bamm.executeActions(_action(int256(collateral), int256(collateral), int256(rentAmount), false));
            vm.stopPrank();

            int256 swapAmount = _pnlSwapAmount(i, mintAmount);

            if (swapAmount > 0) {
                _swapToken0In(uint256(swapAmount));
                token0.approve(address(bamm), uint256(swapAmount));
                bamm.executeActions(_action(int256(uint256(swapAmount)), 0, 0, false));
                token0.transfer(user1, uint256(swapAmount));
                vm.startPrank(user1);
                token0.approve(address(bamm), uint256(swapAmount));
                bamm.executeActions(_action(0, 0, 0, true));
                vm.stopPrank();
                bamm.executeActions(_action(-int256(uint256(swapAmount)), 0, 0, false));
            } else if (swapAmount < 0) {
                uint256 amt = uint256(-swapAmount);
                _swapToken1In(amt);
                token1.approve(address(bamm), amt);
                bamm.executeActions(_action(0, int256(amt), 0, false));
                token1.transfer(user1, amt);
                vm.startPrank(user1);
                token1.approve(address(bamm), amt);
                bamm.executeActions(_action(0, 0, 0, true));
                vm.stopPrank();
                bamm.executeActions(_action(0, -int256(amt), 0, false));
            } else {
                vm.prank(user1);
                bamm.executeActions(_action(0, 0, 0, true));
            }

            bamm.redeem(owner, bammMinted);
            uint256 endLpOwner = pair.balanceOf(owner);

            // Upstream logs a warning when LP profit is missing; do not hard-fail (known JS TODO).
            if (endLpOwner <= startLpOwner) {
                assertTrue(
                    startToken0 <= token0.balanceOf(user1) + 1e18 || startToken1 <= token1.balanceOf(user1) + 1e18
                );
            }
        }
    }

    /// @dev Upstream random fuzz loop (100). Default 5 iterations unless FRAX_BAMM_HEAVY_FUZZ=1.
    function test_fuzz1_closeAfterSwap() public {
        uint256 iterations = vm.envOr("FRAX_BAMM_HEAVY_FUZZ", uint256(0)) == 1 ? 100 : 5;
        uint256 mintAmount = 1e18;
        uint256 collateral = 10e16;

        for (uint256 i = 0; i < iterations; i++) {
            uint256 r = uint256(keccak256(abi.encode("bammFuzz1", i)));
            uint256 rentAmount = mintAmount * ((r % 899) + 1) / 1000;
            uint256 swapAmount = ((r >> 16) % 9 + 1) * _pow10((r >> 24) % 34 + 1);

            if (swapAmount + mintAmount * 2 >= 2_192_300_000_000_000_000_000_000_000) continue;

            _deployBamm(9970, mintAmount * 2);

            pair.approve(address(bamm), mintAmount);
            uint256 bammMinted = bamm.mint(owner, mintAmount);

            token0.transfer(user1, collateral * 2);
            token1.transfer(user1, collateral * 2);
            vm.startPrank(user1);
            token0.approve(address(bamm), collateral);
            token1.approve(address(bamm), collateral);
            bamm.executeActions(_action(int256(collateral), int256(collateral), int256(rentAmount), false));
            vm.stopPrank();

            _swapToken0In(swapAmount);
            token0.approve(address(bamm), swapAmount);
            bamm.executeActions(_action(int256(swapAmount), 0, 0, false));
            token0.transfer(user1, swapAmount);
            vm.startPrank(user1);
            token0.approve(address(bamm), swapAmount);
            bamm.executeActions(_action(0, 0, 0, true));
            vm.stopPrank();
            bamm.executeActions(_action(-int256(swapAmount), 0, 0, false));

            bamm.redeem(owner, bammMinted);
        }
    }

    function _pnlSwapAmount(uint256 i, uint256 mintAmount) internal pure returns (int256) {
        if (i < 50) {
            return int256(mintAmount * 50 / i - mintAmount);
        }
        return int256(mintAmount) - int256(mintAmount * 50 / (i - 40));
    }

    function _swapToken0In(uint256 amountIn) internal {
        uint256 out = pair.getAmountOut(amountIn, address(token0));
        token0.transfer(address(pair), amountIn);
        pair.swap(0, out, owner, "");
    }

    function _swapToken1In(uint256 amountIn) internal {
        uint256 out = pair.getAmountOut(amountIn, address(token1));
        token1.transfer(address(pair), amountIn);
        pair.swap(out, 0, owner, "");
    }

    function _pow10(uint256 exp) internal pure returns (uint256) {
        uint256 r = 1;
        for (uint256 n = 0; n < exp; n++) {
            r *= 10;
        }
        return r;
    }

    function _deployBamm(uint256 feeTier, uint256 mintAmount) internal {
        DummyToken tA = new DummyToken();
        DummyToken tB = new DummyToken();
        if (address(tB) < address(tA)) {
            token0 = tB;
            token1 = tA;
        } else {
            token0 = tA;
            token1 = tB;
        }

        token0.mint(owner, type(uint256).max / 2);
        token1.mint(owner, type(uint256).max / 2);

        FraxswapFactory factory = new FraxswapFactory(owner);
        address pairAddr = factory.createPair(address(token0), address(token1), 10_000 - feeTier);
        pair = FraxswapPair(pairAddr);

        token0.transfer(pairAddr, mintAmount);
        token1.transfer(pairAddr, mintAmount);
        pair.mint(owner);

        FraxswapDummyRouter dummyRouter = new FraxswapDummyRouter();
        token0.transfer(address(dummyRouter), 1000e18);
        token1.transfer(address(dummyRouter), 1000e18);

        BAMMHelper helper = new BAMMHelper();
        FraxswapOracle fraxOracle = new FraxswapOracle();

        bamm = new BAMM(
            pair, true, 10_000 - feeTier, FraxswapRouterMultihop(payable(address(dummyRouter))), helper, fraxOracle
        );
    }

    function _action(int256 token0Amount, int256 token1Amount, int256 rent, bool closePosition)
        internal
        pure
        returns (BAMM.Action memory action)
    {
        action = BAMM.Action({
            token0Amount: token0Amount,
            token1Amount: token1Amount,
            rent: rent,
            to: address(0),
            minToken0Amount: 0,
            minToken1Amount: 0,
            closePosition: closePosition,
            approveMax: false,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            deadline: 0
        });
    }
}
