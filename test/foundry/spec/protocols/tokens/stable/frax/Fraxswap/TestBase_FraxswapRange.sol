// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {FraxswapRangeFactory} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/range/FraxswapRangeFactory.sol";
import {FraxswapRangePair} from "@crane/contracts/protocols/tokens/stable/frax/Fraxswap/range/FraxswapRangePair.sol";
import {DummyToken} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";

abstract contract TestBase_FraxswapRange is Test {
    uint256 internal constant PRECISION = 1e18;
    uint256 internal constant MINIMUM_LIQUIDITY = 1000;
    uint256 internal constant DEFAULT_FEE = 30;

    address internal owner;
    address internal user1;
    address internal user2;
    address internal user3;

    DummyToken internal token0;
    DummyToken internal token1;
    FraxswapRangeFactory internal factory;
    FraxswapRangePair internal rangePair;

    function _rangeSetUp(uint256 centerPrice, uint256 rangeSize, uint256 fee) internal {
        owner = address(this);
        user1 = makeAddr("rangeUser1");
        user2 = makeAddr("rangeUser2");
        user3 = makeAddr("rangeUser3");

        DummyToken tA = new DummyToken();
        DummyToken tB = new DummyToken();
        if (address(tB) < address(tA)) {
            token0 = tB;
            token1 = tA;
        } else {
            token0 = tA;
            token1 = tB;
        }

        uint256 mintAmt = 1000e18;
        token0.mint(owner, mintAmt);
        token0.mint(user1, mintAmt);
        token0.mint(user2, mintAmt);
        token0.mint(user3, mintAmt);
        token1.mint(owner, mintAmt);
        token1.mint(user1, mintAmt);
        token1.mint(user2, mintAmt);
        token1.mint(user3, mintAmt);

        factory = new FraxswapRangeFactory(owner);
        factory.createPair(address(token0), address(token1), centerPrice, rangeSize, fee);
        rangePair = FraxswapRangePair(factory.allPairs(0));
    }

    function _defaultRangeSetUp() internal {
        _rangeSetUp(PRECISION, PRECISION * 3, DEFAULT_FEE);
    }

    function _addInitialLiquidity(uint256 amount0, uint256 amount1) internal {
        token0.transfer(address(rangePair), amount0);
        token1.transfer(address(rangePair), amount1);
        rangePair.mint(owner);
    }
}