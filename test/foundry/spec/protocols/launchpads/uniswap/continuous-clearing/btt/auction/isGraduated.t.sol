// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {
    AuctionFuzzConstructorParams,
    BttBase
} from "test/foundry/spec/protocols/launchpads/uniswap/continuous-clearing/btt/BttBase.sol";
import {
    MockContinuousClearingAuction
} from "test/foundry/spec/protocols/launchpads/uniswap/continuous-clearing/btt/mocks/MockContinuousClearingAuction.sol";
import {
    IContinuousClearingAuction
} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/interfaces/IContinuousClearingAuction.sol";
import {
    ITokenCurrencyStorage
} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/interfaces/ITokenCurrencyStorage.sol";
import {Checkpoint} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/CheckpointLib.sol";
import {ConstantsLib} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/ConstantsLib.sol";
import {FixedPoint96} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/FixedPoint96.sol";
import {
    MaxBidPriceLib
} from "contracts/protocols/launchpads/uniswap/continuous-clearing/src/libraries/MaxBidPriceLib.sol";
import {ERC20Mock} from "openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";

contract IsGraduatedTest is BttBase {
    function test_GivenRaisedIsLTRequired(
        AuctionFuzzConstructorParams memory _params,
        uint128 _requiredCurrencyRaised,
        uint128 _bidAmount
    ) external {
        // it returns false

        alice = makeAddr("alice");

        AuctionFuzzConstructorParams memory mParams = validAuctionConstructorInputs(_params);
        mParams.token = address(new ERC20Mock());
        vm.assume(mParams.token != mParams.parameters.currency);
        mParams.parameters.currency = address(0);
        mParams.parameters.validationHook = address(0);
        mParams.totalSupply = uint128(bound(mParams.totalSupply, 1, ConstantsLib.MAX_TOTAL_SUPPLY));
        mParams.parameters.tickSpacing = bound(mParams.parameters.tickSpacing, 2, type(uint24).max) * FixedPoint96.Q96;
        mParams.parameters.floorPrice = bound(mParams.parameters.floorPrice, 1, 100) * mParams.parameters.tickSpacing;

        uint256 computedMaxBidPrice = MaxBidPriceLib.maxBidPrice(mParams.totalSupply);
        vm.assume(mParams.parameters.floorPrice + mParams.parameters.tickSpacing <= computedMaxBidPrice);

        mParams.parameters.requiredCurrencyRaised = uint128(
            bound(
                _requiredCurrencyRaised, 2, mParams.totalSupply * mParams.parameters.floorPrice / FixedPoint96.Q96 - 1
            )
        );

        MockContinuousClearingAuction auction =
            new MockContinuousClearingAuction(mParams.token, mParams.totalSupply, mParams.parameters);

        ERC20Mock(mParams.token).mint(address(auction), mParams.totalSupply);
        auction.onTokensReceived();

        vm.roll(auction.startBlock());

        uint256 maxPrice = mParams.parameters.floorPrice + mParams.parameters.tickSpacing;
        uint128 bidAmount = uint128(bound(_bidAmount, 1, mParams.parameters.requiredCurrencyRaised - 1));

        vm.deal(address(this), bidAmount);

        auction.submitBid{value: bidAmount}(maxPrice, bidAmount, alice, bytes(""));

        vm.roll(auction.endBlock());

        auction.checkpoint();

        assertFalse(auction.isGraduated(), "auction is graduated");
    }

    function test_GivenRaisedIsGERequired(
        AuctionFuzzConstructorParams memory _params,
        uint128 _requiredCurrencyRaised,
        uint128 _bidAmount
    ) external {
        // it returns true

        alice = makeAddr("alice");

        AuctionFuzzConstructorParams memory mParams = validAuctionConstructorInputs(_params);
        mParams.token = address(new ERC20Mock());
        vm.assume(mParams.token != mParams.parameters.currency);
        mParams.parameters.currency = address(0);
        mParams.parameters.validationHook = address(0);
        mParams.totalSupply = uint128(bound(mParams.totalSupply, 1, ConstantsLib.MAX_TOTAL_SUPPLY));
        mParams.parameters.tickSpacing = bound(mParams.parameters.tickSpacing, 2, type(uint24).max) * FixedPoint96.Q96;
        mParams.parameters.floorPrice = bound(mParams.parameters.floorPrice, 1, 100) * mParams.parameters.tickSpacing;

        uint256 computedMaxBidPrice = MaxBidPriceLib.maxBidPrice(mParams.totalSupply);
        vm.assume(mParams.parameters.floorPrice + mParams.parameters.tickSpacing <= computedMaxBidPrice);

        mParams.parameters.requiredCurrencyRaised = uint128(
            bound(
                _requiredCurrencyRaised, 1, mParams.totalSupply * mParams.parameters.floorPrice / FixedPoint96.Q96 - 1
            )
        );

        MockContinuousClearingAuction auction =
            new MockContinuousClearingAuction(mParams.token, mParams.totalSupply, mParams.parameters);

        ERC20Mock(mParams.token).mint(address(auction), mParams.totalSupply);
        auction.onTokensReceived();

        vm.roll(auction.startBlock());

        uint256 maxPrice = mParams.parameters.floorPrice + mParams.parameters.tickSpacing;
        uint128 bidAmount = uint128(bound(_bidAmount, mParams.parameters.requiredCurrencyRaised, type(uint128).max));

        vm.deal(address(this), bidAmount);
        auction.submitBid{value: bidAmount}(maxPrice, bidAmount, alice, bytes(""));

        vm.roll(auction.endBlock());

        // @note Relies on the checkpoint, without it we won't be seen as graduated.
        assertFalse(auction.isGraduated(), "auction is not graduated");

        auction.checkpoint();

        assertTrue(auction.isGraduated(), "auction is not graduated");
    }
}
