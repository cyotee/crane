// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/BAMM/BAMM.js` (mint/redeem/vault/rent/swap/liquidate).

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
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

contract BAMMTest is Test {
    uint256 internal constant POOL_FEE = 30; // 10000 - 9970

    address internal owner;
    address internal user1;
    address internal user2;

    DummyToken internal token0;
    DummyToken internal token1;
    FraxswapPair internal pair;
    BAMM internal bamm;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        _deployBamm(9970, 100e18);
    }

    function test_setupContracts() public view {
        assertTrue(address(bamm) != address(0));
        assertTrue(address(pair) != address(0));
    }

    function test_mint() public {
        uint256 beforeBal = pair.balanceOf(owner);

        pair.approve(address(bamm), 100e18);
        bamm.mint(owner, 1e18);
        assertEq(bamm.balanceOf(owner), 1e18);
        assertEq(pair.balanceOf(owner), beforeBal - 1e18);

        pair.approve(address(bamm), 100e18);
        bamm.mint(owner, 1e18);
        assertEq(bamm.balanceOf(owner), 2e18);
        assertEq(pair.balanceOf(owner), beforeBal - 2e18);
    }

    function test_redeem() public {
        uint256 beforeBal = pair.balanceOf(owner);

        pair.approve(address(bamm), 100e18);
        bamm.mint(owner, 2e18);
        bamm.redeem(owner, 1e18);
        assertEq(bamm.balanceOf(owner), 1e18);
        assertEq(pair.balanceOf(owner), beforeBal - 1e18);
        assertEq(pair.balanceOf(address(bamm)), 1e18);

        bamm.redeem(owner, 1e18);
        assertEq(bamm.balanceOf(owner), 0);
        assertEq(pair.balanceOf(owner), beforeBal);
        assertEq(pair.balanceOf(address(bamm)), 0);
    }

    function test_redeem_failureChecks() public {
        uint256 beforeBal = pair.balanceOf(owner);

        pair.approve(address(bamm), 100e18);
        bamm.mint(owner, 1e18);

        vm.prank(user1);
        vm.expectRevert();
        bamm.redeem(owner, 1e18);

        pair.transfer(user1, 1e18);
        vm.startPrank(user1);
        pair.approve(address(bamm), 100e18);
        bamm.mint(user1, 1e18);
        vm.expectRevert();
        bamm.redeem(user1, 2e18);
        vm.stopPrank();

        assertEq(pair.balanceOf(address(bamm)), 2e18);

        vm.prank(user1);
        bamm.redeem(user1, 1e18);
        bamm.redeem(owner, 1e18);
        assertEq(pair.balanceOf(address(bamm)), 0);
        // Owner transferred 1 LP to user1 before the dual mint/redeem cycle.
        assertEq(pair.balanceOf(owner), beforeBal - 1e18);
        assertEq(pair.balanceOf(user1), 1e18);
    }

    function test_deposit() public {
        token0.transfer(user1, 1000e18);
        token1.transfer(user1, 1000e18);

        vm.startPrank(user1);
        token0.approve(address(bamm), 100e18);
        assertEq(token0.balanceOf(address(bamm)), 0);
        bamm.executeActions(_action(1e18, 0));
        assertEq(token0.balanceOf(address(bamm)), 1e18);

        (int256 v0, int256 v1, int256 rented) = bamm.userVaults(user1);
        assertEq(v0, 1e18);
        assertEq(v1, 0);
        assertEq(rented, 0);

        token1.approve(address(bamm), 100e18);
        bamm.executeActions(_action(0, 1e18));
        assertEq(token1.balanceOf(address(bamm)), 1e18);

        (v0, v1, rented) = bamm.userVaults(user1);
        assertEq(v0, 1e18);
        assertEq(v1, 1e18);
        assertEq(rented, 0);
        vm.stopPrank();
    }

    function test_withdraw() public {
        token0.transfer(user1, 1000e18);
        token1.transfer(user1, 1000e18);

        vm.startPrank(user1);
        uint256 bal0Before = token0.balanceOf(user1);
        uint256 bal1Before = token1.balanceOf(user1);

        token0.approve(address(bamm), 100e18);
        bamm.executeActions(_action(1e18, 0));
        token1.approve(address(bamm), 100e18);
        bamm.executeActions(_action(0, 1e18));

        bamm.executeActions(_action(-1e18, 0));
        assertEq(token0.balanceOf(address(bamm)), 0);
        assertEq(token0.balanceOf(user1), bal0Before);

        (int256 v0, int256 v1, int256 rented) = bamm.userVaults(user1);
        assertEq(v0, 0);
        assertEq(v1, 1e18);
        assertEq(rented, 0);

        bamm.executeActions(_action(0, -1e18));
        assertEq(token1.balanceOf(address(bamm)), 0);
        assertEq(token1.balanceOf(user1), bal1Before);

        (v0, v1, rented) = bamm.userVaults(user1);
        assertEq(v0, 0);
        assertEq(v1, 0);
        assertEq(rented, 0);
        vm.stopPrank();
    }

    function test_withdraw_failureChecks() public {
        token0.transfer(user1, 1000e18);
        token1.transfer(user1, 1000e18);

        vm.startPrank(user1);
        token0.approve(address(bamm), 100e18);
        bamm.executeActions(_action(1e18, 0));
        token1.approve(address(bamm), 100e18);
        bamm.executeActions(_action(0, 1e18));

        vm.expectRevert();
        bamm.executeActions(_action(-2e18, 0));
        vm.expectRevert();
        bamm.executeActions(_action(0, -2e18));
        vm.stopPrank();

        token0.approve(address(bamm), 100e18);
        bamm.executeActions(_action(10e18, 0));
        token1.approve(address(bamm), 100e18);
        bamm.executeActions(_action(0, 10e18));

        vm.startPrank(user1);
        vm.expectRevert("Negative positions not allowed");
        bamm.executeActions(_action(-2e18, 0));
        vm.expectRevert("Negative positions not allowed");
        bamm.executeActions(_action(0, -2e18));
        bamm.executeActions(_action(-1e18, -1e18));
        vm.stopPrank();
    }

    function test_rent() public {
        _mintBammLp(10e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token0.approve(address(bamm), 100e18);
        bamm.executeActions(_action(1e18, 0));
        bamm.executeActions(_actionRent(1e18));
        vm.stopPrank();

        assertEq(token0.balanceOf(address(bamm)), 2e18);
        assertEq(token1.balanceOf(address(bamm)), 1e18);
        (int256 v0, int256 v1, int256 rented) = bamm.userVaults(user1);
        assertEq(v0, 2e18);
        assertEq(v1, 1e18);
        assertEq(rented, 1e18);

        vm.prank(user1);
        bamm.executeActions(_actionRent(1e18));
        (v0, v1, rented) = bamm.userVaults(user1);
        assertApproxEqAbs(uint256(v0), 3e18, 1e12);
        assertApproxEqAbs(uint256(v1), 2e18, 1e12);
        assertEq(rented, 2e18);
    }

    function test_rent_failureChecks() public {
        _mintBammLp(10e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token0.approve(address(bamm), 100e18);
        token1.approve(address(bamm), 100e18);
        bamm.executeActions(_action(1e18, 1e18));

        vm.expectRevert("MAX_UTILITY_RATE");
        bamm.executeActions(_actionRent(91e17));

        bamm.executeActions(_actionRent(9e18));

        vm.expectRevert("Not solvent");
        bamm.executeActions(_action(-8164e14, -8164e14));

        bamm.executeActions(_action(-8163e14, -8163e14));
        vm.stopPrank();
    }

    function test_returnRentedWithInterest() public {
        _mintBammLp(10e18);
        _fundUser(user1);

        bamm.nominateNewOwner(user2);
        vm.prank(user2);
        bamm.acceptOwnership();

        uint256 lpStart = pair.balanceOf(owner);

        vm.startPrank(user1);
        token0.approve(address(bamm), 100e18);
        token1.approve(address(bamm), 100e18);
        bamm.executeActions(_actionWith(1e18, 1e18, 1e18, false));
        vm.stopPrank();

        _warp(60 * 60 * 24 * 200);
        pair.sync();
        _warp(60 * 60 * 24 * 165);

        vm.prank(user1);
        bamm.executeActions(_actionRent(-1e18));

        (int256 v0, int256 v1, int256 rented) = bamm.userVaults(user1);
        int256 expected = int256(2e18) - (int256(101e16) + int256(9e16) / 7);
        assertApproxEqAbs(uint256(v0), uint256(expected), 1e12);
        assertApproxEqAbs(uint256(v1), uint256(expected), 1e12);
        assertEq(rented, 0);

        vm.prank(user2);
        bamm.redeem(user2, bamm.balanceOf(user2));
        uint256 feeLp = pair.balanceOf(user2);

        uint256 ownerBamm = bamm.balanceOf(owner);
        bamm.redeem(owner, ownerBamm);
        uint256 lpEnd = pair.balanceOf(owner);
        assertGt(lpEnd, lpStart);
        assertGt(feeLp, 0);
        assertLt(v0, 1e18);
    }

    function test_oneCallBorrow() public {
        _mintBammLp(10e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token0.approve(address(bamm), 100e18);
        bamm.executeActions(_actionWith(1e18, -4e17, 1e18, false));
        vm.stopPrank();

        _warp(60 * 60 * 24);
        (int256 rented,,) = bamm.userVaults(user1);
        assertGt(rented, 0);
    }

    function test_oneCallClose() public {
        _mintBammLp(10e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token0.approve(address(bamm), 100e18);
        bamm.executeActions(_actionWith(1e18, -4e17, 1e18, false));
        _warp(60 * 60 * 24);
        token1.approve(address(bamm), 100e18);
        bamm.executeActions(_actionClose());
        vm.stopPrank();

        (int256 v0, int256 v1, int256 rented) = bamm.userVaults(user1);
        assertEq(v0, 0);
        assertEq(v1, 0);
        assertEq(rented, 0);
    }

    function test_swap() public {
        _mintBammLp(10e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token1.approve(address(bamm), 100e18);
        bamm.executeActions(_actionWith(0, 1e18, 1e18, false));

        FraxswapRouterMultihop.FraxswapParams memory swapParams =
            _swapParams(address(token0), 45e16, address(token1), 45e16);
        BAMM.Action memory emptyAction = _action(0, 0);
        bamm.executeActionsAndSwap(emptyAction, swapParams);
        vm.stopPrank();

        (int256 v0, int256 v1, int256 rented) = bamm.userVaults(user1);
        assertGt(v0, 0);
        assertGt(v1, 0);
        assertEq(rented, 1e18);
    }

    function test_oneCallLeverage() public {
        _mintBammLp(10e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token1.approve(address(bamm), 100e18);
        FraxswapRouterMultihop.FraxswapParams memory swapParams =
            _swapParams(address(token0), 45e16, address(token1), 45e16);
        bamm.executeActionsAndSwap(_actionWith(0, 1e18, 1e18, false), swapParams);
        vm.stopPrank();

        (, int256 v1, int256 rented) = bamm.userVaults(user1);
        assertGt(v1, 0);
        assertEq(rented, 1e18);
    }

    function test_oneCallDeleverage() public {
        _mintBammLp(10e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token1.approve(address(bamm), 100e18);
        FraxswapRouterMultihop.FraxswapParams memory openSwap =
            _swapParams(address(token0), 45e16, address(token1), 45e16);
        bamm.executeActionsAndSwap(_actionWith(0, 1e18, 1e18, false), openSwap);

        FraxswapRouterMultihop.FraxswapParams memory closeSwap =
            _swapParams(address(token1), 44e16, address(token0), 46e16);
        bamm.executeActionsAndSwap(_actionClose(), closeSwap);
        vm.stopPrank();

        (int256 v0, int256 v1, int256 rented) = bamm.userVaults(user1);
        assertEq(v0, 0);
        assertEq(v1, 0);
        assertEq(rented, 0);
    }

    function test_liquidate() public {
        _deployBamm(9970, 100e18);
        _mintBammLp(1e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token1.approve(address(bamm), 100e18);
        FraxswapRouterMultihop.FraxswapParams memory swapParams =
            _swapParams(address(token0), 49e16, address(token1), 49e16);
        bamm.executeActionsAndSwap(_actionWith(0, 1e18, 90e16, false), swapParams);
        vm.stopPrank();

        _seedOracleHistory();

        vm.prank(user2);
        vm.expectRevert("User solvent");
        bamm.liquidate(user1);

        _warp(6 * 60 * 60 * 24);
        _seedOracleHistory();
        bamm.addInterest();

        vm.prank(user2);
        bamm.liquidate(user1);
    }

    function test_liquidate_ammPriceCheck() public {
        _deployBamm(9999, 100e18);
        _mintBammLp(1e18);
        _fundUser(user1);

        vm.startPrank(user1);
        token1.approve(address(bamm), 100e18);
        FraxswapRouterMultihop.FraxswapParams memory swapParams =
            _swapParams(address(token0), 49e16, address(token1), 49e16);
        bamm.executeActionsAndSwap(_actionWith(0, 1e18, 90e16, false), swapParams);
        vm.stopPrank();

        _seedOracleHistory();

        vm.prank(user2);
        vm.expectRevert("User solvent");
        bamm.liquidate(user1);

        _warp(6 * 60 * 60 * 24);
        for (uint256 i = 0; i < 25; i++) {
            _simulateSwap(1e18);
            _warp(60);
        }
        for (uint256 i = 0; i < 25; i++) {
            _simulateSwap(-1e18);
            _warp(60);
        }

        vm.prank(user2);
        vm.expectRevert("ammPriceCheck");
        bamm.liquidate(user1);

        _seedOracleHistory();
        bamm.addInterest();

        vm.prank(user2);
        bamm.liquidate(user1);
    }

    function _mintBammLp(uint256 amount) internal {
        pair.approve(address(bamm), 100e18);
        bamm.mint(owner, amount);
    }

    function _fundUser(address user) internal {
        token0.transfer(user, 1000e18);
        token1.transfer(user, 1000e18);
    }

    function _warp(uint256 seconds_) internal {
        vm.warp(block.timestamp + seconds_);
    }

    /// @dev FraxswapOracle needs two TWAP observations strictly more than 30 minutes apart.
    function _seedOracleHistory() internal {
        _warp(1);
        _simulateSwap(1e10);
        _warp(31 * 60);
        _simulateSwap(1e10);
    }

    function _simulateSwap(int256 amount) internal {
        if (amount > 0) {
            uint256 out = pair.getAmountOut(uint256(amount), address(token0));
            token0.transfer(address(pair), uint256(amount));
            pair.swap(0, out, owner, "");
        } else {
            uint256 out = pair.getAmountOut(uint256(-amount), address(token1));
            token1.transfer(address(pair), uint256(-amount));
            pair.swap(out, 0, owner, "");
        }
    }

    function _swapParams(address tokenIn, uint256 amountIn, address tokenOut, uint256 amountOutMin)
        internal
        pure
        returns (FraxswapRouterMultihop.FraxswapParams memory params)
    {
        params = FraxswapRouterMultihop.FraxswapParams({
            tokenIn: tokenIn,
            amountIn: amountIn,
            tokenOut: tokenOut,
            amountOutMinimum: amountOutMin,
            recipient: address(0),
            deadline: type(uint256).max,
            approveMax: false,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            route: bytes("")
        });
    }

    function _actionRent(int256 rent) internal pure returns (BAMM.Action memory action) {
        action = _actionWith(0, 0, rent, false);
    }

    function _actionClose() internal pure returns (BAMM.Action memory action) {
        action = _actionWith(0, 0, 0, true);
    }

    function _actionWith(int256 token0Amount, int256 token1Amount, int256 rent, bool closePosition)
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
        FraxswapOracle oracle = new FraxswapOracle();

        bamm = new BAMM(
            pair, true, 10_000 - feeTier, FraxswapRouterMultihop(payable(address(dummyRouter))), helper, oracle
        );
    }

    function _action(int256 token0Amount, int256 token1Amount) internal pure returns (BAMM.Action memory action) {
        action = BAMM.Action({
            token0Amount: token0Amount,
            token1Amount: token1Amount,
            rent: 0,
            to: address(0),
            minToken0Amount: 0,
            minToken1Amount: 0,
            closePosition: false,
            approveMax: false,
            v: 0,
            r: bytes32(0),
            s: bytes32(0),
            deadline: 0
        });
    }
}
