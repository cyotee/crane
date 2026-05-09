// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Interfaces
import {IERC20} from '@crane/contracts/interfaces/IERC20.sol';
import {IPool} from '@crane/contracts/protocols/lending/aave/v3.6/interfaces/IPool.sol';

// Libraries
import {DataTypes} from '@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/types/DataTypes.sol';
import {PercentageMath} from '@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/math/PercentageMath.sol';

// Test Contracts
import {Actor} from '@crane/contracts/protocols/lending/aave/v3.6/utils/Actor.sol';
import {BaseHandler} from 'test/foundry/spec/protocols/lending/aave/3.6/invariants/base/BaseHandler.t.sol';

/// @title FlashLoanHandler
/// @notice Handler test contract for a set of actions
contract FlashLoanHandler is BaseHandler {
  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                      STATE VARIABLES                                      //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                          ACTIONS                                          //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  function flashLoan(
    uint256[3] memory amounts,
    bool[3] memory interestRateModes,
    uint8 i
  ) external setup {
    bool success;
    bytes memory returnData;

    address[] memory assets = new address[](3);
    assets[0] = baseAssets[0];
    assets[1] = baseAssets[1];
    assets[2] = baseAssets[2];

    uint256[] memory interestRateModesUint = new uint256[](3);
    interestRateModesUint[0] = interestRateModes[0] ? 2 : 0;
    interestRateModesUint[1] = interestRateModes[1] ? 2 : 0;
    interestRateModesUint[2] = interestRateModes[2] ? 2 : 0;

    address onBehalfOf = _getRandomActor(i);

    bytes memory calldata_ = abi.encodeWithSelector(
      IPool.flashLoan.selector,
      flashLoanReceiver,
      assets,
      amounts,
      interestRateModesUint,
      onBehalfOf,
      '',
      0
    );

    _before();
    (success, returnData) = actor.proxy(address(pool), calldata_);

    if (success) {
      _after();
    } else {
      revert('FlashLoanHandler: flashLoan failed');
    }
  }

  function flashLoanSimple(uint256 amount, uint8 i) external setup {
    bool success;
    bytes memory returnData;

    address asset = _getRandomBaseAsset(i);

    _before();
    (success, returnData) = actor.proxy(
      address(pool),
      abi.encodeWithSelector(
        IPool.flashLoanSimple.selector,
        flashLoanReceiver,
        asset,
        amount,
        '',
        0
      )
    );

    if (success) {
      _after();
    } else {
      revert('FlashLoanHandler: flashLoanSimple failed');
    }
  }

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                         OWNER ACTIONS                                     //
  ///////////////////////////////////////////////////////////////////////////////////////////////

  ///////////////////////////////////////////////////////////////////////////////////////////////
  //                                           HELPERS                                         //
  ///////////////////////////////////////////////////////////////////////////////////////////////
}
