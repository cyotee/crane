// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {TransparentUpgradeableProxy} from '@crane/contracts/protocols/lending/aave/v3.6/dependencies/openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol';
import {Collector} from '@crane/contracts/protocols/lending/aave/v3.6/treasury/Collector.sol';
import {EmptyImplementation} from '@crane/contracts/protocols/lending/aave/v3.6/misc/EmptyImplementation.sol';
import '../interfaces/IMarketReportTypes.sol';

contract AaveV3TreasuryProcedure {
  struct TreasuryReport {
    address treasuryImplementation;
    address treasury;
    address emptyImplementation;
    address dustBin;
  }

  function _deployAaveV3Treasury(
    address poolAdmin,
    bytes32 collectorSalt
  ) internal returns (TreasuryReport memory) {
    TreasuryReport memory treasuryReport;
    bytes32 salt = collectorSalt;

    if (salt != '') {
      Collector treasuryImplementation = new Collector{salt: salt}();
      treasuryReport.treasuryImplementation = address(treasuryImplementation);

      treasuryReport.treasury = address(
        new TransparentUpgradeableProxy{salt: salt}(
          treasuryReport.treasuryImplementation,
          poolAdmin,
          abi.encodeWithSelector(treasuryImplementation.initialize.selector, 100_000, poolAdmin)
        )
      );
      treasuryReport.emptyImplementation = address(new EmptyImplementation{salt: salt}());
      treasuryReport.dustBin = address(
        new TransparentUpgradeableProxy{salt: salt}(
          treasuryReport.emptyImplementation,
          poolAdmin,
          ''
        )
      );
    } else {
      Collector treasuryImplementation = new Collector();
      treasuryReport.treasuryImplementation = address(treasuryImplementation);

      treasuryReport.treasury = address(
        new TransparentUpgradeableProxy(
          treasuryReport.treasuryImplementation,
          poolAdmin,
          abi.encodeWithSelector(treasuryImplementation.initialize.selector, 100_000, poolAdmin)
        )
      );
      treasuryReport.emptyImplementation = address(new EmptyImplementation());
      treasuryReport.dustBin = address(
        new TransparentUpgradeableProxy(treasuryReport.emptyImplementation, poolAdmin, '')
      );
    }

    return treasuryReport;
  }
}
