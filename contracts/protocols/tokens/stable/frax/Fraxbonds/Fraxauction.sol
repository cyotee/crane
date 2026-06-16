//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.35;

import "@crane/contracts/external/uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract Fraxauction {
    Auction[] public auctions;

    struct Auction {
        address owner;
        address buyToken;
        address sellToken;
        uint256 sellAmount;
        uint256 pricePrecision;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 endTime;
        uint256 soldAmount;
        uint256 earnings;
        bool exited;
    }

    constructor() {}

    function createAuction(
        address _buyToken,
        address _sellToken,
        uint256 _sellAmount,
        uint256 _pricePrecision,
        uint256 _startPrice,
        uint256 _endPrice,
        uint256 _duration
    ) external {
        if (_startPrice < _endPrice) revert("Wrong price");
        TransferHelper.safeTransferFrom(_sellToken, msg.sender, address(this), _sellAmount);
        auctions.push(
            Auction(
                msg.sender,
                _buyToken,
                _sellToken,
                _sellAmount,
                _pricePrecision,
                _startPrice,
                _endPrice,
                block.timestamp,
                block.timestamp + _duration,
                0,
                0,
                false
            )
        );
    }

    function buy(uint256 _auctionNo, uint256 _amountIn, uint256 _maxPrice)
        external
        returns (uint256 _in, uint256 _out)
    {
        Auction memory auction = auctions[_auctionNo];
        if (auction.endTime < block.timestamp || auction.exited) revert("Auction ended");
        uint256 price = auction.startPrice - (auction.startPrice - auction.endPrice)
            * (block.timestamp - auction.startTime) / (auction.endTime - auction.startTime);
        if (price > _maxPrice) revert("maxPrice");
        uint256 amountOut = _amountIn * auction.pricePrecision / price;
        if (auction.soldAmount + amountOut > auction.sellAmount) {
            amountOut = auction.sellAmount - auction.soldAmount;
            _amountIn = _amountIn * price / auction.pricePrecision;
        }

        auctions[_auctionNo].soldAmount += amountOut;
        auctions[_auctionNo].earnings += _amountIn;

        TransferHelper.safeTransferFrom(auction.buyToken, msg.sender, address(this), _amountIn);
        TransferHelper.safeTransfer(auction.sellToken, msg.sender, amountOut);
        return (_amountIn, amountOut);
    }

    function exit(uint256 _auctionNo) external {
        Auction memory auction = auctions[_auctionNo];
        if (auction.owner != msg.sender) revert("Not owner");
        if (auction.exited) revert("Already exited");

        auctions[_auctionNo].exited = true;

        TransferHelper.safeTransferFrom(auction.buyToken, msg.sender, address(this), auction.earnings);
        TransferHelper.safeTransfer(auction.sellToken, msg.sender, auction.sellAmount - auction.soldAmount);
    }
}
