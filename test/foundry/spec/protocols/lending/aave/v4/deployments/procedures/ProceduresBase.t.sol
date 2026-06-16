// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@crane/contracts/external/openzeppelin-contracts/access/Ownable.sol";
import {IAccessManaged} from "@crane/contracts/external/openzeppelin-contracts/access/manager/IAccessManaged.sol";

import {ProxyHelper} from "@crane/test/foundry/spec/protocols/lending/aave/v4/utils/ProxyHelper.sol";
import {
    DeployConstants
} from "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/DeployConstants.sol";
import {TestnetERC20} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/TestnetERC20.sol";
import {
    AaveV4HubConfiguratorDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4HubConfiguratorDeployProcedureWrapper.sol";
import {
    AaveV4HubDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4HubDeployProcedureWrapper.sol";
import {
    AaveV4InterestRateStrategyDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4InterestRateStrategyDeployProcedureWrapper.sol";
import {
    AaveV4NativeTokenGatewayDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4NativeTokenGatewayDeployProcedureWrapper.sol";
import {
    AaveV4SignatureGatewayDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4SignatureGatewayDeployProcedureWrapper.sol";
import {
    AaveV4AccessManagerEnumerableDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4AccessManagerEnumerableDeployProcedureWrapper.sol";
import {
    AaveV4AaveOracleDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4AaveOracleDeployProcedureWrapper.sol";
import {
    AaveV4SpokeDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4SpokeDeployProcedureWrapper.sol";
import {
    AaveV4TreasurySpokeDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4TreasurySpokeDeployProcedureWrapper.sol";
import {
    AaveV4SpokeConfiguratorDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4SpokeConfiguratorDeployProcedureWrapper.sol";
import {
    AaveV4AccessManagerRolesProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4AccessManagerRolesProcedureWrapper.sol";
import {
    AaveV4SpokeRolesProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4SpokeRolesProcedureWrapper.sol";
import {
    AaveV4HubRolesProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4HubRolesProcedureWrapper.sol";
import {
    AaveV4HubConfiguratorRolesProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4HubConfiguratorRolesProcedureWrapper.sol";
import {
    AaveV4SpokeConfiguratorRolesProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4SpokeConfiguratorRolesProcedureWrapper.sol";
import {
    AaveV4TokenizationSpokeDeployProcedureWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/procedures/AaveV4TokenizationSpokeDeployProcedureWrapper.sol";
import {
    AaveV4HubRolesProcedure
} from "@crane/contracts/protocols/lending/aave/v4/deployments/procedures/roles/AaveV4HubRolesProcedure.sol";
import {
    AaveV4DeployProcedureBase
} from "@crane/contracts/protocols/lending/aave/v4/deployments/procedures/AaveV4DeployProcedureBase.sol";
import {
    AaveV4HubInstanceBatch
} from "@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4HubInstanceBatch.sol";
import {
    AaveV4TreasurySpokeBatch
} from "@crane/contracts/protocols/lending/aave/v4/deployments/batches/AaveV4TreasurySpokeBatch.sol";
import {BatchReports} from "@crane/contracts/protocols/lending/aave/v4/deployments/libraries/BatchReports.sol";
import {Create2Utils} from "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/Create2Utils.sol";

import {AaveOracle} from "@crane/contracts/protocols/lending/aave/v4/spoke/AaveOracle.sol";
import {AccessManagerEnumerable} from "@crane/contracts/protocols/lending/aave/v4/access/AccessManagerEnumerable.sol";
import {Roles} from "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/Roles.sol";

import {IHub} from "@crane/contracts/protocols/lending/aave/v4/hub/interfaces/IHub.sol";
import {
    IAssetInterestRateStrategy
} from "@crane/contracts/protocols/lending/aave/v4/hub/interfaces/IAssetInterestRateStrategy.sol";
import {IAaveOracle} from "@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/IAaveOracle.sol";
import {ITreasurySpoke} from "@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ITreasurySpoke.sol";
import {ISpoke} from "@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ISpoke.sol";
import {
    IAccessManagerEnumerable
} from "@crane/contracts/protocols/lending/aave/v4/access/interfaces/IAccessManagerEnumerable.sol";
import {IAccessManager} from "@crane/contracts/external/openzeppelin-contracts/access/manager/IAccessManager.sol";
import {ITokenizationSpoke} from "@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ITokenizationSpoke.sol";
import {Create2TestHelper} from "@crane/test/foundry/spec/protocols/lending/aave/v4/utils/Create2TestHelper.sol";

contract ProceduresBase is Create2TestHelper {
    address public owner = makeAddr("owner");
    address public accessManager;
    address public hub = makeAddr("hub");
    address public nativeWrapper = makeAddr("nativeWrapper");
    address public accessManagerAdmin = makeAddr("accessManagerAdmin");
    uint8 public oracleDecimals = 8;
    uint16 public maxUserReservesLimit = DeployConstants.MAX_ALLOWED_USER_RESERVES_LIMIT;
    address public spoke = makeAddr("spoke");
    address public aaveOracle;
    address public feeReceiver = makeAddr("feeReceiver");
    address public admin = makeAddr("admin");
    bytes32 public salt;
    bytes internal hubBytecode;
    bytes internal spokeBytecode;

    function setUp() public virtual {
        _etchCreate2Factory();

        hubBytecode = vm.getCode("contracts/protocols/lending/aave/v4/hub/instances/HubInstance.sol:HubInstance");
        spokeBytecode =
            vm.getCode("contracts/protocols/lending/aave/v4/spoke/instances/SpokeInstance.sol:SpokeInstance");
        accessManager = address(new AccessManagerEnumerable(accessManagerAdmin));
        aaveOracle = address(new AaveOracle(oracleDecimals));
        salt = keccak256("testSalt");
    }

    function _assertCanCall(address target, bytes4[] memory selectors) internal {
        for (uint256 idx; idx < selectors.length; idx++) {
            (bool allowed, uint32 delay) = IAccessManager(accessManager).canCall(admin, target, selectors[idx]);
            assertTrue(allowed);
            assertEq(delay, 0);
        }

        address unauthorized = makeAddr("unauthorized");
        for (uint256 idx; idx < selectors.length; idx++) {
            (bool allowed, uint32 delay) = IAccessManager(accessManager).canCall(unauthorized, target, selectors[idx]);
            assertFalse(allowed);
            assertEq(delay, 0);
        }
    }
}
