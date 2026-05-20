// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/Fraxoracle/Fraxoracle-test.js`.

import {Test} from "forge-std/Test.sol";
import {Fraxoracle} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/Fraxoracle.sol";
import {DummyPriceOracle} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/DummyPriceOracle.sol";
import {DummyStateRootOracle} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/DummyStateRootOracle.sol";
import {FraxoraclePriceSource} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/FraxoraclePriceSource.sol";
import {MerkleProofPriceSource} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/MerkleProofPriceSource.sol";
contract Fraxoracle_Test is Test {
    uint256 internal constant MAX_DELAY = 24 hours;
    uint256 internal constant LOW = 100e18;
    uint256 internal constant HIGH = 101e18;

    DummyPriceOracle internal dummyPriceOracle;
    DummyStateRootOracle internal dummyStateRootOracle;
    Fraxoracle internal fraxoracle;
    Fraxoracle internal fraxoracleL2;
    FraxoraclePriceSource internal fraxoraclePriceSource;
    MerkleProofPriceSource internal merkleProofPriceSource;

    function setUp() public {
        dummyStateRootOracle = new DummyStateRootOracle();
        dummyPriceOracle = new DummyPriceOracle();
        fraxoracle = new Fraxoracle(18, "TestFraxoracle", 1, MAX_DELAY, 2e16);
        fraxoracleL2 = new Fraxoracle(18, "TestFraxoracleL2", 1, MAX_DELAY, 2e16);
        fraxoraclePriceSource = new FraxoraclePriceSource(fraxoracle, dummyPriceOracle);
        fraxoracle.setPriceSource(address(fraxoraclePriceSource));
        merkleProofPriceSource =
            new MerkleProofPriceSource(fraxoracleL2, dummyStateRootOracle, address(fraxoracle));
        fraxoracleL2.setPriceSource(address(merkleProofPriceSource));
    }

    function test_setupContracts() public view {
        assertTrue(address(fraxoracle) != address(0));
        assertTrue(address(fraxoracleL2) != address(0));
    }

    function test_addRoundData() public {
        dummyPriceOracle.setPrices(false, LOW, HIGH);
        fraxoraclePriceSource.addRoundData();

        uint256 ts = block.timestamp;
        (bool isBad, uint256 priceLow, uint256 priceHigh) = fraxoracle.getPrices();
        assertFalse(isBad);
        assertEq(priceLow, LOW);
        assertEq(priceHigh, HIGH);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            fraxoracle.latestRoundData();
        assertEq(roundId, 0);
        assertEq(answer, int256((LOW + HIGH) / 2));
        assertEq(startedAt, ts);
        assertEq(updatedAt, ts);
        assertEq(answeredInRound, 0);

        (roundId, answer, startedAt, updatedAt, answeredInRound) = fraxoracle.getRoundData(0);
        assertEq(roundId, 0);
        assertEq(answer, int256((LOW + HIGH) / 2));
        assertEq(startedAt, ts);
        assertEq(updatedAt, ts);
        assertEq(answeredInRound, 0);

        vm.warp(ts + MAX_DELAY + 1);
        (isBad, priceLow, priceHigh) = fraxoracle.getPrices();
        assertTrue(isBad);
        assertEq(priceLow, LOW);
        assertEq(priceHigh, HIGH);
    }

    function test_merkleProofPriceSource_wired() public view {
        assertTrue(address(merkleProofPriceSource) != address(0));
        assertEq(fraxoracleL2.priceSource(), address(merkleProofPriceSource));
    }
}