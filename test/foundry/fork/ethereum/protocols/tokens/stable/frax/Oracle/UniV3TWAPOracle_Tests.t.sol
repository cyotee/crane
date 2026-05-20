// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/UniV3TWAPOracle-Tests.js`

import {UniV3TWAPOracle} from "@crane/contracts/protocols/tokens/stable/frax/Oracle/UniV3TWAPOracle.sol";
import {
    TestBase_FraxEthereumFork,
    FraxEthereumAddresses
} from "../TestBase_FraxEthereumFork.sol";

contract UniV3TWAPOracle_Tests is TestBase_FraxEthereumFork {
    UniV3TWAPOracle internal oracle;

    function setUp() public {
        _forkEthereum();
        oracle = UniV3TWAPOracle(FraxEthereumAddresses.UNIV3_TWAP_FRAX_FPI);
    }

    function test_Main_getPrecisePriceAndFlip() public {
        uint256 priceBefore = oracle.getPrecisePrice();
        assertGt(priceBefore, 0);

        (string memory baseBefore, string memory quoteBefore) = oracle.token_symbols();
        assertGt(bytes(baseBefore).length, 0);
        assertGt(bytes(quoteBefore).length, 0);

        address ownerAddr = oracle.owner();
        vm.prank(ownerAddr);
        oracle.toggleTokenForPricing();

        uint256 priceAfter = oracle.getPrecisePrice();
        assertGt(priceAfter, 0);

        (string memory baseAfter, string memory quoteAfter) = oracle.token_symbols();
        assertTrue(keccak256(bytes(baseAfter)) != keccak256(bytes(baseBefore)) || keccak256(bytes(quoteAfter)) != keccak256(bytes(quoteBefore)));
    }

    function test_getPrice_scalesToE6() public view {
        assertEq(oracle.getPrice(), oracle.getPrecisePrice() / 1e12);
    }
}