// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import 'forge-std/Test.sol';
import '@crane/contracts/protocols/lending/aave/v3.6/deployments/interfaces/IMarketReportTypes.sol';

import {BatchTestProcedures} from '../utils/BatchTestProcedures.sol';
import {AaveV3TestListing} from '@crane/contracts/protocols/lending/aave/v3.6/utils/mocks/AaveV3TestListing.sol';
import {ACLManager} from '@crane/contracts/protocols/lending/aave/v3.6/protocol/configuration/ACLManager.sol';
import {WETH9} from '@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol';
import {IPoolAddressesProvider} from '@crane/contracts/protocols/lending/aave/v3.6/interfaces/IPoolAddressesProvider.sol';
import {IAaveV3ConfigEngine} from '@crane/contracts/protocols/lending/aave/v3.6/extensions/v3-config-engine/IAaveV3ConfigEngine.sol';
import {IPool} from '@crane/contracts/protocols/lending/aave/v3.6/interfaces/IPool.sol';
import {AaveV3ConfigEngine} from '@crane/contracts/protocols/lending/aave/v3.6/extensions/v3-config-engine/AaveV3ConfigEngine.sol';
import {SequencerOracle} from '@crane/contracts/protocols/lending/aave/v3.6/utils/mocks/oracle/SequencerOracle.sol';
import {IPoolDataProvider} from '@crane/contracts/protocols/lending/aave/v3.6/interfaces/IPoolDataProvider.sol';
import {IAToken} from '@crane/contracts/protocols/lending/aave/v3.6/interfaces/IAToken.sol';
import {IncentivizedERC20} from '@crane/contracts/protocols/lending/aave/v3.6/protocol/tokenization/base/IncentivizedERC20.sol';
import {RewardsController} from '@crane/contracts/protocols/lending/aave/v3.6/rewards/RewardsController.sol';
import {EmissionManager} from '@crane/contracts/protocols/lending/aave/v3.6/rewards/EmissionManager.sol';

contract AaveV3BatchDeployment is BatchTestProcedures {
  address public marketOwner;
  address public emergencyAdmin;

  Roles public roles;
  DeployFlags public flags;
  MarketConfig config;
  MarketReport deployedContracts;

  address public weth9;

  function setUp() public {
    bytes32 emptySalt;
    weth9 = address(new WETH9());
    marketOwner = makeAddr('marketOwner');
    poolAdmin = makeAddr('poolAdmin');
    emergencyAdmin = makeAddr('emergencyAdmin');

    roles = Roles(marketOwner, poolAdmin, emergencyAdmin);
    config = MarketConfig(
      makeAddr('ethUsdOracle'),
      makeAddr('ethUsdOracle'),
      'Testnet Market',
      8,
      address(0), // l2SequencerUptimeFeed
      0, // l2PriceOracleSentinelGracePeriod
      8080,
      emptySalt,
      weth9,
      0.0005e4,
      address(0),
      address(0)
    );
  }

  function testAaveV3BatchDeploymentCheck() public {
    MarketReport memory fullReport = deployAaveV3Testnet(
      marketOwner,
      roles,
      config,
      flags,
      deployedContracts
    );
    checkFullReport(config, flags, fullReport);

    AaveV3TestListing testnetListingPayload = new AaveV3TestListing(
      IAaveV3ConfigEngine(fullReport.configEngine),
      marketOwner,
      weth9,
      fullReport
    );

    ACLManager manager = ACLManager(fullReport.aclManager);

    vm.prank(poolAdmin);
    manager.addPoolAdmin(address(testnetListingPayload));

    testnetListingPayload.execute();

    address aToken = IPool(fullReport.poolProxy).getReserveAToken(weth9);

    assertEq(IAToken(aToken).RESERVE_TREASURY_ADDRESS(), fullReport.treasury);
  }

  function testAaveV3L2BatchDeploymentCheck() public {
    flags.l2 = true;
    config.l2SequencerUptimeFeed = address(new SequencerOracle(poolAdmin));
    config.l2PriceOracleSentinelGracePeriod = 2 hours;

    MarketReport memory fullReport = deployAaveV3Testnet(
      marketOwner,
      roles,
      config,
      flags,
      deployedContracts
    );

    checkFullReport(config, flags, fullReport);

    AaveV3TestListing testnetListingPayload = new AaveV3TestListing(
      IAaveV3ConfigEngine(fullReport.configEngine),
      marketOwner,
      weth9,
      fullReport
    );

    ACLManager manager = ACLManager(fullReport.aclManager);

    vm.prank(poolAdmin);
    manager.addPoolAdmin(address(testnetListingPayload));

    testnetListingPayload.execute();
  }

  function testAaveV3BatchDeploy() public {
    checkFullReport(
      config,
      flags,
      deployAaveV3Testnet(marketOwner, roles, config, flags, deployedContracts)
    );
  }

  function testAaveV3Batch_reuseIncentivesProxy() public {
    EmissionManager emissionManager = new EmissionManager(poolAdmin);
    RewardsController controller = new RewardsController(address(emissionManager));

    config.incentivesProxy = address(controller);

    checkFullReport(
      config,
      flags,
      deployAaveV3Testnet(marketOwner, roles, config, flags, deployedContracts)
    );
  }
}
