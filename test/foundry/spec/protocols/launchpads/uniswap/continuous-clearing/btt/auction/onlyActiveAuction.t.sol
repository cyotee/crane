// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {AuctionFuzzConstructorParams, BttBase} from '../BttBase.sol';

import {ERC20Mock} from '@openzeppelin/contracts/mocks/token/ERC20Mock.sol';
import {MockContinuousClearingAuction} from 'test/foundry/spec/protocols/launchpads/uniswap/continuous-clearing/btt/mocks/MockContinuousClearingAuction.sol';
import {IContinuousClearingAuction} from 'contracts/protocols/launchpads/uniswap/continuous-clearing/src/interfaces/IContinuousClearingAuction.sol';

contract OnlyActiveAuctionTest is BttBase {
    function test_WhenBlockNumberLTStartBlock(AuctionFuzzConstructorParams memory _params, uint256 _blockNumber)
        external
    {
        // it reverts with {AuctionNotStarted}

        AuctionFuzzConstructorParams memory mParams = validAuctionConstructorInputs(_params);

        MockContinuousClearingAuction auction =
            new MockContinuousClearingAuction(mParams.token, mParams.totalSupply, mParams.parameters);

        uint256 blockNumber = bound(_blockNumber, 0, mParams.parameters.startBlock - 1);

        vm.roll(blockNumber);
        vm.expectRevert(IContinuousClearingAuction.AuctionNotStarted.selector);
        auction.modifier_onlyActiveAuction();
    }

    modifier whenBlockNumberGEStartBlock() {
        _;
    }

    function test_GivenNoTokensHaveBeenReceived(AuctionFuzzConstructorParams memory _params, uint256 _blockNumber)
        external
        whenBlockNumberGEStartBlock
    {
        // it reverts with {TokensNotReceived}

        AuctionFuzzConstructorParams memory mParams = validAuctionConstructorInputs(_params);

        MockContinuousClearingAuction auction =
            new MockContinuousClearingAuction(mParams.token, mParams.totalSupply, mParams.parameters);

        uint256 blockNumber = bound(_blockNumber, mParams.parameters.startBlock, type(uint64).max);

        vm.roll(blockNumber);
        vm.expectRevert(IContinuousClearingAuction.TokensNotReceived.selector);
        auction.modifier_onlyActiveAuction();
    }

    function test_GivenTokensHaveBeenReceived(AuctionFuzzConstructorParams memory _params, uint256 _blockNumber)
        external
        whenBlockNumberGEStartBlock
    {
        // it does not revert

        AuctionFuzzConstructorParams memory mParams = validAuctionConstructorInputs(_params);

        ERC20Mock token = new ERC20Mock();
        vm.assume(address(token) != mParams.parameters.currency);

        MockContinuousClearingAuction auction =
            new MockContinuousClearingAuction(address(token), mParams.totalSupply, mParams.parameters);

        uint256 blockNumber = bound(_blockNumber, mParams.parameters.startBlock, type(uint64).max);

        token.mint(address(auction), mParams.totalSupply);
        auction.onTokensReceived();

        vm.roll(blockNumber);
        auction.modifier_onlyActiveAuction();
    }
}
