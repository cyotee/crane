// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {Vm} from "forge-std/Vm.sol";
import {IERC20Metadata} from
    "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";

import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {Create2Utils} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/Create2Utils.sol";
import {SpokeBytecodeLinker} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/SpokeBytecodeLinker.sol";
import {InputUtils} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/InputUtils.sol";
import {BytecodeHelper} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/BytecodeHelper.sol";
import {MetadataLogger} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/utils/MetadataLogger.sol";
import {OrchestrationReports} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/libraries/OrchestrationReports.sol";
import {AaveV4DeployOrchestration} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/orchestration/AaveV4DeployOrchestration.sol";
import {IHub} from "@crane/contracts/protocols/lending/aave/v4/hub/interfaces/IHub.sol";
import {ISpoke} from "@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ISpoke.sol";
import {IAssetInterestRateStrategy} from
    "@crane/contracts/protocols/lending/aave/v4/hub/interfaces/IAssetInterestRateStrategy.sol";
import {Roles} from "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/Roles.sol";
import {AccessManagerEnumerable} from
    "@crane/contracts/protocols/lending/aave/v4/access/AccessManagerEnumerable.sol";
import {
    AaveV4HubConfiguratorRolesProcedure
} from "@crane/contracts/protocols/lending/aave/v4/deployments/procedures/roles/AaveV4HubConfiguratorRolesProcedure.sol";
import {
    AaveV4SpokeConfiguratorRolesProcedure
} from "@crane/contracts/protocols/lending/aave/v4/deployments/procedures/roles/AaveV4SpokeConfiguratorRolesProcedure.sol";
import {
    AaveV4HubRolesProcedure
} from "@crane/contracts/protocols/lending/aave/v4/deployments/procedures/roles/AaveV4HubRolesProcedure.sol";
import {
    AaveV4SpokeRolesProcedure
} from "@crane/contracts/protocols/lending/aave/v4/deployments/procedures/roles/AaveV4SpokeRolesProcedure.sol";

import {AaveV3BatchOrchestration} from
    "@crane/contracts/protocols/lending/aave/v3.6/deployments/projects/aave-v3-batched/AaveV3BatchOrchestration.sol";
import {
    Roles as V3Roles,
    MarketConfig,
    DeployFlags,
    MarketReport
} from "@crane/contracts/protocols/lending/aave/v3.6/deployments/interfaces/IMarketReportTypes.sol";
import {IPoolConfigurator} from
    "@crane/contracts/protocols/lending/aave/v3.6/interfaces/IPoolConfigurator.sol";
import {IAaveOracle} from "@crane/contracts/protocols/lending/aave/v3.6/interfaces/IAaveOracle.sol";
import {
    ConfiguratorInputTypes
} from "@crane/contracts/protocols/lending/aave/v3.6/protocol/libraries/types/ConfiguratorInputTypes.sol";
import {IDefaultInterestRateStrategyV2} from
    "@crane/contracts/protocols/lending/aave/v3.6/interfaces/IDefaultInterestRateStrategyV2.sol";

/// @notice Shared Phase 3 deploy helpers for forge scripts and createSelectFork tests.
library BcAavePhase3Deploy {
    Vm private constant VM = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));

    bytes32 internal constant V4_SALT = keccak256("crane-bc-aave-v4-v1");

    struct V4DeployResult {
        address liquidationLogic;
        address accessManager;
        address hub;
        address hubConfigurator;
        address spoke;
        address spokeConfigurator;
        address aaveOracle;
        address treasurySpoke;
        address nativeTokenGateway;
        address signatureGateway;
        address irStrategy;
        OrchestrationReports.FullDeploymentReport report;
    }

    struct V4ConfigureResult {
        uint256 wethAssetId;
        uint256 usdcAssetId;
        uint256 daiAssetId;
        uint256 wethReserveId;
        uint256 usdcReserveId;
        uint256 daiReserveId;
    }

    struct V3DeployResult {
        MarketReport report;
    }

    /// @notice Ensure a real on-chain CREATE2 factory (Path A or Path B via BC Deployer / CREATE).
    /// @dev Must not use `vm.etch`. Returns the factory address that has non-empty code.
    function ensureCreate2FactoryPathB() internal returns (address factory) {
        factory = Create2Utils.ensureCreate2Factory();
        require(factory.code.length > 0, "BcAavePhase3: CREATE2 factory missing after Path B");
        // Path B must not leave us pretending Path A is live when it is not.
        if (Create2Utils.CREATE2_FACTORY.code.length == 0) {
            require(factory != Create2Utils.CREATE2_FACTORY, "BcAavePhase3: Path B factory unresolved");
        }
    }

    /// @notice Active CREATE2 factory used by Phase 3 (Path A canonical or Path B deployed).
    function create2Factory() internal view returns (address) {
        return Create2Utils.getFactory();
    }

    function deployLiquidationLogicLinkedSpoke()
        internal
        returns (address liquidationLogic, bytes memory spokeBytecode)
    {
        ensureCreate2FactoryPathB();
        return SpokeBytecodeLinker.deployLiquidationLogicAndLinkSpoke();
    }

    function bcFullDeployInputs(address deployer) internal pure returns (InputUtils.FullDeployInputs memory inputs) {
        string[] memory hubLabels = new string[](1);
        hubLabels[0] = "core";
        string[] memory spokeLabels = new string[](1);
        spokeLabels[0] = "bc";
        uint16[] memory maxReserves = new uint16[](1);
        maxReserves[0] = 16;

        inputs = InputUtils.FullDeployInputs({
            accessManagerAdmin: deployer,
            proxyAdminOwner: deployer,
            hubAdmin: deployer,
            hubConfiguratorAdmin: deployer,
            treasurySpokeOwner: deployer,
            spokeAdmin: deployer,
            spokeConfiguratorAdmin: deployer,
            gatewayOwner: deployer,
            positionManagerOwner: deployer,
            nativeWrapper: BC_TESTNET.WETH,
            deployNativeTokenGateway: true,
            deploySignatureGateway: true,
            deployPositionManagers: true,
            grantRoles: true,
            hubLabels: hubLabels,
            spokeLabels: spokeLabels,
            spokeMaxReservesLimits: maxReserves,
            salt: V4_SALT
        });
    }

    function deployV4Core(address deployer) internal returns (V4DeployResult memory result) {
        ensureCreate2FactoryPathB();
        bytes memory spokeBytecode;
        (result.liquidationLogic, spokeBytecode) = deployLiquidationLogicLinkedSpoke();
        bytes memory hubBytecode = BytecodeHelper.getHubBytecode();

        VM.createDir("output/reports/deployments/", true);
        MetadataLogger logger = new MetadataLogger("output/reports/deployments/");
        InputUtils.FullDeployInputs memory inputs = bcFullDeployInputs(deployer);

        result.report =
            AaveV4DeployOrchestration.deployAaveV4(logger, deployer, inputs, hubBytecode, spokeBytecode);

        result.accessManager = result.report.authorityBatchReport.accessManager;
        result.hubConfigurator = result.report.configuratorBatchReport.hubConfigurator;
        result.spokeConfigurator = result.report.configuratorBatchReport.spokeConfigurator;
        result.treasurySpoke = result.report.treasurySpokeBatchReport.treasurySpoke;
        result.nativeTokenGateway = result.report.gatewaysBatchReport.nativeGateway;
        result.signatureGateway = result.report.gatewaysBatchReport.signatureGateway;

        require(result.report.hubInstanceBatchReports.length > 0, "BcAavePhase3: no hub");
        require(result.report.spokeInstanceBatchReports.length > 0, "BcAavePhase3: no spoke");
        result.hub = result.report.hubInstanceBatchReports[0].report.hubProxy;
        result.irStrategy = result.report.hubInstanceBatchReports[0].report.irStrategy;
        result.spoke = result.report.spokeInstanceBatchReports[0].report.spokeProxy;
        result.aaveOracle = result.report.spokeInstanceBatchReports[0].report.aaveOracle;

        console2.log("V4 accessManager", result.accessManager);
        console2.log("V4 hub", result.hub);
        console2.log("V4 spoke", result.spoke);
        console2.log("V4 liquidationLogic", result.liquidationLogic);
    }

    /// @notice List WETH/USDC/DAI on hub + spoke with BC Chainlink mocks.
    function configureV4Market(address deployer, V4DeployResult memory core)
        internal
        returns (V4ConfigureResult memory cfg)
    {
        AccessManagerEnumerable am = AccessManagerEnumerable(core.accessManager);

        am.grantRole(Roles.HUB_CONFIGURATOR_ROLE, deployer, 0);
        am.grantRole(Roles.SPOKE_CONFIGURATOR_ROLE, deployer, 0);
        AaveV4HubRolesProcedure.grantHubAllRoles(address(am), deployer);
        AaveV4SpokeRolesProcedure.grantSpokeAllRoles(address(am), deployer);
        AaveV4HubConfiguratorRolesProcedure.grantHubConfiguratorAllRoles(address(am), deployer);
        AaveV4SpokeConfiguratorRolesProcedure.grantSpokeConfiguratorAllRoles(address(am), deployer);

        IHub hub = IHub(core.hub);
        ISpoke spoke = ISpoke(core.spoke);

        bytes memory irData = abi.encode(
            IAssetInterestRateStrategy.InterestRateData({
                optimalUsageRatio: 80_00,
                baseDrawnRate: 0,
                rateGrowthBeforeOptimal: 4_00,
                rateGrowthAfterOptimal: 60_00
            })
        );
        address feeReceiver = core.treasurySpoke;

        cfg.wethAssetId = hub.addAsset(
            BC_TESTNET.WETH, IERC20Metadata(BC_TESTNET.WETH).decimals(), feeReceiver, core.irStrategy, irData
        );
        cfg.usdcAssetId = hub.addAsset(
            BC_TESTNET.USDC, IERC20Metadata(BC_TESTNET.USDC).decimals(), feeReceiver, core.irStrategy, irData
        );
        cfg.daiAssetId = hub.addAsset(
            BC_TESTNET.DAI, IERC20Metadata(BC_TESTNET.DAI).decimals(), feeReceiver, core.irStrategy, irData
        );

        IHub.SpokeConfig memory spokeCfg =
            IHub.SpokeConfig({addCap: type(uint40).max, drawCap: type(uint40).max, riskPremiumThreshold: 10_000, active: true, halted: false});

        hub.addSpoke(cfg.wethAssetId, address(spoke), spokeCfg);
        hub.addSpoke(cfg.usdcAssetId, address(spoke), spokeCfg);
        hub.addSpoke(cfg.daiAssetId, address(spoke), spokeCfg);

        // targetHealthFactor >= 1e18; healthFactorForMaxBonus < 1e18 (Spoke validation).
        spoke.updateLiquidationConfig(
            ISpoke.LiquidationConfig({
                targetHealthFactor: 1.05e18, healthFactorForMaxBonus: 0.95e18, liquidationBonusFactor: 10_00
            })
        );

        ISpoke.ReserveConfig memory rcfg = ISpoke.ReserveConfig({
            collateralRisk: 15_00, paused: false, frozen: false, borrowable: true, receiveSharesEnabled: true
        });
        ISpoke.DynamicReserveConfig memory dcfg =
            ISpoke.DynamicReserveConfig({collateralFactor: 75_00, maxLiquidationBonus: 105_00, liquidationFee: 10_00});

        cfg.wethReserveId =
            spoke.addReserve(core.hub, cfg.wethAssetId, BC_TESTNET.CHAINLINK_ETH_USD, rcfg, dcfg);
        cfg.usdcReserveId =
            spoke.addReserve(core.hub, cfg.usdcAssetId, BC_TESTNET.CHAINLINK_USDC_USD, rcfg, dcfg);
        cfg.daiReserveId =
            spoke.addReserve(core.hub, cfg.daiAssetId, BC_TESTNET.CHAINLINK_USDC_USD, rcfg, dcfg);

        console2.log("V4 configured WETH assetId", cfg.wethAssetId);
        console2.log("V4 configured WETH reserveId", cfg.wethReserveId);
        console2.log("V4 configured USDC reserveId", cfg.usdcReserveId);
        console2.log("V4 configured DAI reserveId", cfg.daiReserveId);
    }

    function deployV3Market(address deployer) internal returns (V3DeployResult memory result) {
        // V3 market uses procedure `new` (no CREATE2 required). Do not gate on etch/Path B.

        V3Roles memory roles =
            V3Roles({marketOwner: deployer, poolAdmin: deployer, emergencyAdmin: deployer});

        MarketConfig memory config = MarketConfig({
            networkBaseTokenPriceInUsdProxyAggregator: BC_TESTNET.CHAINLINK_ETH_USD,
            marketReferenceCurrencyPriceInUsdProxyAggregator: BC_TESTNET.CHAINLINK_ETH_USD,
            marketId: "Crane BC Aave V3",
            oracleDecimals: 8,
            l2SequencerUptimeFeed: address(0),
            l2PriceOracleSentinelGracePeriod: 0,
            providerId: 1,
            salt: bytes32(0),
            wrappedNativeToken: BC_TESTNET.WETH,
            flashLoanPremium: 0.0005e4,
            incentivesProxy: address(0),
            treasury: address(0)
        });

        DeployFlags memory flags;
        MarketReport memory empty;
        result.report = AaveV3BatchOrchestration.deployAaveV3(deployer, roles, config, flags, empty);

        _initV3Reserves(result.report);

        console2.log("V3 poolProxy", result.report.poolProxy);
        console2.log("V3 poolAddressesProvider", result.report.poolAddressesProvider);
        console2.log("V3 aaveOracle", result.report.aaveOracle);
    }

    function _initV3Reserves(MarketReport memory report) private {
        address[] memory assets = new address[](3);
        assets[0] = BC_TESTNET.WETH;
        assets[1] = BC_TESTNET.USDC;
        assets[2] = BC_TESTNET.DAI;

        address[] memory sources = new address[](3);
        sources[0] = BC_TESTNET.CHAINLINK_ETH_USD;
        sources[1] = BC_TESTNET.CHAINLINK_USDC_USD;
        sources[2] = BC_TESTNET.CHAINLINK_USDC_USD;

        IAaveOracle(report.aaveOracle).setAssetSources(assets, sources);

        ConfiguratorInputTypes.InitReserveInput[] memory inputs = new ConfiguratorInputTypes.InitReserveInput[](3);
        bytes memory rateData = abi.encode(
            IDefaultInterestRateStrategyV2.InterestRateData({
                optimalUsageRatio: 80_00,
                baseVariableBorrowRate: 0,
                variableRateSlope1: 4_00,
                variableRateSlope2: 60_00
            })
        );

        for (uint256 i; i < 3; ++i) {
            string memory sym = i == 0 ? "WETH" : (i == 1 ? "USDC" : "DAI");
            inputs[i] = ConfiguratorInputTypes.InitReserveInput({
                aTokenImpl: report.aToken,
                variableDebtTokenImpl: report.variableDebtToken,
                underlyingAsset: assets[i],
                aTokenName: string.concat("Aave BC ", sym),
                aTokenSymbol: string.concat("a", sym),
                variableDebtTokenName: string.concat("Aave BC Variable Debt ", sym),
                variableDebtTokenSymbol: string.concat("variableDebt", sym),
                params: bytes(""),
                interestRateData: rateData
            });
        }

        IPoolConfigurator(report.poolConfiguratorProxy).initReserves(inputs);

        for (uint256 i; i < 3; ++i) {
            IPoolConfigurator(report.poolConfiguratorProxy).configureReserveAsCollateral(assets[i], 7500, 8000, 10500);
            IPoolConfigurator(report.poolConfiguratorProxy).setReserveBorrowing(assets[i], true);
            IPoolConfigurator(report.poolConfiguratorProxy).setReserveActive(assets[i], true);
        }
    }
}
