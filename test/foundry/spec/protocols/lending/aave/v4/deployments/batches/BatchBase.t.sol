// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from '@crane/contracts/protocols/lending/aave/v4/dependencies/openzeppelin/Ownable.sol';
import {IAccessManaged} from '@crane/contracts/protocols/lending/aave/v4/dependencies/openzeppelin/IAccessManaged.sol';

import {WETH9} from '@crane/contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol';
import {TestnetERC20} from '@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/TestnetERC20.sol';

import {Create2TestHelper} from '@crane/test/foundry/spec/protocols/lending/aave/v4/utils/Create2TestHelper.sol';
import {ProxyHelper} from '@crane/test/foundry/spec/protocols/lending/aave/v4/utils/ProxyHelper.sol';
import {Roles} from '@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/Roles.sol';
import {BatchReports} from '@crane/contracts/protocols/lending/aave/v4/deployments/libraries/BatchReports.sol';
import {AaveV4AuthorityBatch} from '@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4AuthorityBatch.sol';
import {AaveV4SpokeInstanceBatch} from '@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4SpokeInstanceBatch.sol';
import {AaveV4HubInstanceBatch} from '@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4HubInstanceBatch.sol';
import {AaveV4ConfiguratorBatch} from '@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4ConfiguratorBatch.sol';
import {AaveV4TokenizationSpokeBatch} from '@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4TokenizationSpokeBatch.sol';
import {AaveV4GatewayBatch} from '@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4GatewayBatch.sol';
import {AaveV4PositionManagerBatch} from '@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4PositionManagerBatch.sol';
import {AaveV4TreasurySpokeBatch} from '@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4TreasurySpokeBatch.sol';
import {AaveV4HubRolesProcedure} from '@crane/contracts/protocols/lending/aave/v4/deployments/procedures/roles/AaveV4HubRolesProcedure.sol';
import {NativeTokenGateway} from '@crane/contracts/protocols/lending/aave/v4/position-manager/NativeTokenGateway.sol';

import {IHub} from '@crane/contracts/protocols/lending/aave/v4/hub/interfaces/IHub.sol';
import {ITokenizationSpoke} from '@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ITokenizationSpoke.sol';
import {IAssetInterestRateStrategy} from '@crane/contracts/protocols/lending/aave/v4/hub/interfaces/IAssetInterestRateStrategy.sol';

import {AssetInterestRateStrategy} from '@crane/contracts/protocols/lending/aave/v4/hub/AssetInterestRateStrategy.sol';
import {IAccessManagerEnumerable} from '@crane/contracts/protocols/lending/aave/v4/access/interfaces/IAccessManagerEnumerable.sol';
import {TreasurySpoke} from '@crane/contracts/protocols/lending/aave/v4/spoke/TreasurySpoke.sol';
import {ISpoke} from '@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ISpoke.sol';
import {IPriceOracle} from '@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/IPriceOracle.sol';

contract BatchBaseTest is Create2TestHelper {
  address public admin = makeAddr('admin');
  address public feeReceiver = makeAddr('feeReceiver');
  bytes32 public salt;
  address public accessManager;
  address public nativeWrapper;
  bytes internal hubBytecode;
  bytes internal spokeBytecode;

  function setUp() public virtual {
    salt = keccak256('testSalt');
    _etchCreate2Factory();

    hubBytecode = vm.getCode('contracts/protocols/lending/aave/v4/hub/instances/HubInstance.sol:HubInstance');
    spokeBytecode = vm.getCode('contracts/protocols/lending/aave/v4/spoke/instances/SpokeInstance.sol:SpokeInstance');

    // used Hub, Spoke, Configurator batches
    AaveV4AuthorityBatch authorityBatch = new AaveV4AuthorityBatch({admin_: admin, salt_: salt});
    accessManager = authorityBatch.getReport().accessManager;

    // used by Gateway batch
    nativeWrapper = address(new WETH9());
  }
}
