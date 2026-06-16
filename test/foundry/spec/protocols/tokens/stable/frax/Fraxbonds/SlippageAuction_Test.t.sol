// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/Fraxbonds/SlippageAuction.js`

import {Test} from "forge-std/Test.sol";
import {SlippageAuction} from "@crane/contracts/protocols/tokens/stable/frax/Fraxbonds/SlippageAuction.sol";
import {MintableERC20} from "@crane/contracts/protocols/tokens/stable/frax/mocks/MintableERC20.sol";

contract SlippageAuction_Test is Test {
    uint128 internal constant PRECISION = 1e18;

    address internal buyer;
    MintableERC20 internal buyToken;
    MintableERC20 internal sellToken;
    SlippageAuction internal auction;

    function setUp() public {
        buyer = makeAddr("buyer");
        buyToken = new MintableERC20("BUY", "BUY");
        sellToken = new MintableERC20("SELL", "SELL");

        buyToken.mint(address(this), type(uint256).max / 2);
        sellToken.mint(address(this), type(uint256).max / 2);
        buyToken.mint(buyer, 1_000e18);
        sellToken.mint(buyer, 1_000e18);

        auction = new SlippageAuction();
    }

    function test_createAuction_storesAuction() public {
        sellToken.approve(address(auction), 1e18);
        uint256 auctionNo =
            auction.createAuction(address(buyToken), address(sellToken), 1e18, 1e18, uint128(1e14), uint128(1e16));
        assertEq(auctionNo, 0);

        (
            address owner,
            address storedBuy,
            address storedSell,
            uint128 priceDecay,
            uint128 priceSlippage,
            uint128 amountLeft,
            uint128 amountOut,
            uint128 lastPrice,,
            bool exited
        ) = auction.auctions(0);

        assertEq(owner, address(this));
        assertEq(storedBuy, address(buyToken));
        assertEq(storedSell, address(sellToken));
        assertEq(priceDecay, 1e14);
        assertEq(priceSlippage, 1e16);
        assertEq(amountLeft, 1e18);
        assertEq(amountOut, 0);
        assertEq(lastPrice, 1e18);
        assertFalse(exited);
    }

    function test_buy_transfersTokens() public {
        sellToken.approve(address(auction), 1e18);
        auction.createAuction(address(buyToken), address(sellToken), 1e18, 1e18, 1e14, 1e16);

        vm.warp(block.timestamp + 10);

        uint128 amountIn = 1e16;
        uint256 sellBefore = sellToken.balanceOf(buyer);

        vm.startPrank(buyer);
        buyToken.approve(address(auction), amountIn);
        uint128 bought = auction.buy(0, amountIn, 0);
        vm.stopPrank();

        assertGt(bought, 0);
        assertEq(sellToken.balanceOf(buyer), sellBefore + bought);
        assertEq(buyToken.balanceOf(address(auction)), amountIn);
    }

    function test_exit_returnsProceedsToOwner() public {
        uint256 ownerBuyBefore = buyToken.balanceOf(address(this));
        uint256 buyerBuyBefore = buyToken.balanceOf(buyer);

        sellToken.approve(address(auction), 1e18);
        auction.createAuction(address(buyToken), address(sellToken), 1e18, 1e18, 1e14, 1e16);

        vm.warp(block.timestamp + 10);

        uint128 amountIn = 1e16;
        uint256 buyerSellBeforeBuy = sellToken.balanceOf(buyer);

        vm.startPrank(buyer);
        buyToken.approve(address(auction), amountIn);
        uint128 bought = auction.buy(0, amountIn, 0);
        vm.stopPrank();

        auction.exit(0);

        assertEq(buyToken.balanceOf(address(this)) - ownerBuyBefore, amountIn);
        assertEq(buyerBuyBefore - buyToken.balanceOf(buyer), amountIn);
        assertEq(sellToken.balanceOf(buyer) - buyerSellBeforeBuy, bought);
        assertEq(buyToken.balanceOf(address(auction)), 0);
        assertEq(sellToken.balanceOf(address(auction)), 0);
    }
}
