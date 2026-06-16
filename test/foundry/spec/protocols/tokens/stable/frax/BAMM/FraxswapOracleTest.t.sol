// SPDX-License-Identifier: ISC
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/BAMM/FraxswapOracle.js`.

import {TestBase_FraxBAMM} from "./TestBase_FraxBAMM.sol";
import {FraxswapOracle, IFraxswapPair} from "@crane/contracts/protocols/tokens/stable/frax/BAMM/FraxswapOracle.sol";

contract FraxswapOracleTest is TestBase_FraxBAMM {
    FraxswapOracle internal oracle;

    function setUp() public {
        _fraxBammSetUp();
        oracle = new FraxswapOracle();
    }

    function test_setupContracts() public {
        _createPair(9999);
        _mintPairLiquidity(100e18, 100e18);
        assertTrue(address(oracle) != address(0));
    }

    function test_getPrice_fixed() public {
        _createPair(9999);
        _mintPairLiquidity(100e18, 100e18);

        uint256[101] memory pricesDirect0;
        uint256[101] memory pricesDirect1;
        uint256 time = block.timestamp;

        for (uint256 i = 0; i < 101; i++) {
            time += 100_000;
            vm.warp(time);
            _pairSwap(1e18, fraxOwner);

            (uint112 r0, uint112 r1,) = pair.getReserves();
            pricesDirect0[i] = uint256(r1) * 1e18 / uint256(r0);
            pricesDirect1[i] = uint256(r0) * 1e18 / uint256(r1);
        }

        vm.warp(block.timestamp + 100_000);

        for (uint256 i = 0; i <= 100; i++) {
            (uint256 result0, uint256 result1) =
                oracle.getPrice(IFraxswapPair(address(pair)), i * 100_002 + 10, 10, 10_000);

            uint256 sum0;
            uint256 sum1;
            for (uint256 j = 0; j <= i; j++) {
                sum0 += pricesDirect0[100 - j];
                sum1 += pricesDirect1[100 - j];
            }
            uint256 average0 = sum0 / (i + 1);
            uint256 average1 = sum1 / (i + 1);

            assertApproxEqAbs(average0, result0, 1e13);
            assertApproxEqAbs(average1, result1, 1e13);
        }
    }

    function test_getPrice_fuzz() public {
        uint256 outer = vm.envOr("FRAX_ORACLE_FUZZ_OUTER", uint256(5));

        for (uint256 t = 0; t < outer; t++) {
            _createPair(9999);
            _mintPairLiquidity(100e18, 100e18);

            uint256[101] memory pricesDirect0;
            uint256[101] memory pricesDirect1;
            uint256 time = block.timestamp;

            for (uint256 i = 0; i < 101; i++) {
                time += 100_000;
                vm.warp(time);

                uint256 r = uint256(keccak256(abi.encode("oracleSwap", t, i)));
                int256 swapAmount = 1e18;
                if (r % 2 == 0) swapAmount = -swapAmount;
                _pairSwap(swapAmount, fraxOwner);

                (uint112 r0, uint112 r1,) = pair.getReserves();
                pricesDirect0[i] = uint256(r1) * 1e18 / uint256(r0);
                pricesDirect1[i] = uint256(r0) * 1e18 / uint256(r1);
            }

            vm.warp(block.timestamp + 100_000);

            for (uint256 i = 0; i <= 100; i++) {
                (uint256 result0, uint256 result1) =
                    oracle.getPrice(IFraxswapPair(address(pair)), i * 100_002 + 10, 10, 10_000);

                uint256 sum0;
                uint256 sum1;
                for (uint256 j = 0; j <= i; j++) {
                    sum0 += pricesDirect0[100 - j];
                    sum1 += pricesDirect1[100 - j];
                }
                uint256 average0 = sum0 / (i + 1);
                uint256 average1 = sum1 / (i + 1);

                assertApproxEqAbs(average0, result0, 1e14);
                assertApproxEqAbs(average1, result1, 1e14);
            }
        }
    }
}
