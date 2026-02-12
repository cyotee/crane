// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {ICLPool} from "../interfaces/ICLPool.sol";
import {ICLFactory} from "../interfaces/ICLFactory.sol";
import {IFeeModule} from "../interfaces/fees/IFeeModule.sol";
import {ICustomFeeModule} from "../interfaces/fees/ICustomFeeModule.sol";

/// @title CustomUnstakedFeeModule
/// @notice Fee module that allows custom unstaked fees to be set per pool
/// @dev Ported from Slipstream (Solidity 0.7.6) to Solidity 0.8.x
contract CustomUnstakedFeeModule is ICustomFeeModule {
    /// @inheritdoc IFeeModule
    ICLFactory public immutable override factory;

    /// @inheritdoc ICustomFeeModule
    mapping(address => uint24) public override customFee;

    /// @notice Maximum unstaked fee allowed (50%)
    uint256 public constant MAX_FEE = 500_000;

    /// @notice Indicator value used to explicitly set a 0% fee
    /// @dev A 0 value in customFee mapping indicates no custom fee is set (use default)
    uint256 public constant ZERO_FEE_INDICATOR = 420;

    /// @notice Default unstaked fee (10%)
    uint24 public constant DEFAULT_FEE = 100_000;

    /// @notice Creates the CustomUnstakedFeeModule
    /// @param _factory The CLFactory address
    constructor(address _factory) {
        factory = ICLFactory(_factory);
    }

    /// @inheritdoc ICustomFeeModule
    function setCustomFee(address _pool, uint24 _fee) external override {
        require(msg.sender == factory.unstakedFeeManager(), "Not unstaked fee manager");
        require(_fee <= MAX_FEE || _fee == ZERO_FEE_INDICATOR, "Fee too high");
        require(factory.isPool(_pool), "Not a valid pool");

        customFee[_pool] = _fee;
        emit CustomFeeSet(_pool, _fee);
    }

    /// @inheritdoc IFeeModule
    function getFee(address _pool) external view override returns (uint24) {
        uint24 fee = customFee[_pool];

        // If ZERO_FEE_INDICATOR, return 0
        // If custom fee is set (non-zero), return it
        // Otherwise return default fee
        if (fee == ZERO_FEE_INDICATOR) {
            return 0;
        } else if (fee != 0) {
            return fee;
        } else {
            return DEFAULT_FEE;
        }
    }
}
