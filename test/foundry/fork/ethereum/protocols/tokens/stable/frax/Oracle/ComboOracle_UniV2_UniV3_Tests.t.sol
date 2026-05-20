// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/ComboOracle_SLP_UniV2_UniV3-Tests.js`

import {ComboOracle} from "@crane/contracts/protocols/tokens/stable/frax/Oracle/ComboOracle.sol";
import {ComboOracle_UniV2_UniV3} from "@crane/contracts/protocols/tokens/stable/frax/Oracle/ComboOracle_UniV2_UniV3.sol";
import {
    TestBase_FraxEthereumFork,
    FraxEthereumAddresses
} from "../TestBase_FraxEthereumFork.sol";

contract ComboOracle_UniV2_UniV3_Tests is TestBase_FraxEthereumFork {
    ComboOracle internal combo;
    ComboOracle_UniV2_UniV3 internal comboUni;

    function setUp() public {
        _forkEthereum();
        combo = ComboOracle(FraxEthereumAddresses.COMBO_ORACLE);
        comboUni = ComboOracle_UniV2_UniV3(FraxEthereumAddresses.COMBO_ORACLE_UNIV2_UNIV3);
    }

    function test_Main_getTokenPrices() public view {
        (uint256 fraxUsd,, uint256 fraxEth) = combo.getTokenPrice(FraxEthereumAddresses.FRAX);
        assertGt(fraxUsd, 0);
        assertGt(fraxEth, 0);

        (uint256 fxsUsd,,) = combo.getTokenPrice(FraxEthereumAddresses.FXS);
        assertGt(fxsUsd, 0);

        (uint256 usdcUsd,,) = combo.getTokenPrice(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        assertGt(usdcUsd, 0);
    }

    function test_Main_uniV2LPPriceInfoViaReserves() public view {
        _assertLpPrice(FraxEthereumAddresses.UNIV2_LP_FRAX_FXS);
        _assertLpPrice(FraxEthereumAddresses.UNIV2_LP_FRAX_USDC);
    }

    function test_Main_uniV2LPPriceInfo_homora() public view {
        ComboOracle_UniV2_UniV3.UniV2PriceInfo memory info = comboUni.uniV2LPPriceInfo(FraxEthereumAddresses.UNIV2_LP_FRAX_FXS);
        assertGt(info.precise_price, 0);
        assertGt(bytes(info.token_symbol).length, 0);
    }

    function _assertLpPrice(address lpToken) internal view {
        ComboOracle_UniV2_UniV3.UniV2PriceInfo memory info = comboUni.uniV2LPPriceInfoViaReserves(lpToken);
        assertGt(info.precise_price, 0);
        assertGt(bytes(info.token_symbol).length, 0);
        assertGt(bytes(info.token0_symbol).length, 0);
        assertGt(bytes(info.token1_symbol).length, 0);
    }
}