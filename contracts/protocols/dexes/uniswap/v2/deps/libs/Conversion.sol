// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

library Conversion {

    using Conversion for uint256;

    uint8 constant ERC20_DEFAULT_DECIMALS = 18;

  function _convertDecimalsFromTo(
    uint256 amount,
    uint8 amountDecimals,
    uint8 targetDecimals
  ) internal pure returns(uint256 convertedAmount) {
    if(amountDecimals == targetDecimals) {
      return amount;
    }
    convertedAmount = amountDecimals > targetDecimals
    ? amount / 10**(amountDecimals - targetDecimals)
    : amount * 10**(targetDecimals - amountDecimals);
  }

    function _precision(
        uint256 value,
        uint8 precision,
        uint8 targetPrecision
    ) internal pure returns(uint256 preciseValue) {
        preciseValue = value._convertDecimalsFromTo(
            precision,
            targetPrecision
        );
    }

    function _normalize(
        uint256 value
    ) internal pure returns(uint256) {
        return value._precision(ERC20_DEFAULT_DECIMALS, 2);
    }

}