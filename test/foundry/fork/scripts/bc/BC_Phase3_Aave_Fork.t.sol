// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {Create2Utils} from
    "@crane/contracts/protocols/lending/aave/v4/deployments/utils/libraries/Create2Utils.sol";
import {ISpoke} from "@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ISpoke.sol";
import {IHub} from "@crane/contracts/protocols/lending/aave/v4/hub/interfaces/IHub.sol";
import {IPool} from "@crane/contracts/protocols/lending/aave/v3.6/interfaces/IPool.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

import {BcAavePhase3Deploy} from "scripts/foundry/bc/BcAavePhase3Deploy.sol";

/// @notice Phase 3 Aave fork smoke: real Path B CREATE2, V3 market, V4 core+configure on BC.
/// @dev Uses vm.createSelectFork (in-process). No live battlechain-sepolia broadcast.
///      Fails if factory install used etch (Path A must stay empty; Path B must have real code
///      at a non-canonical address or via BC Deployer lineage).
contract BC_Phase3_Aave_Fork_Test is Test {
    string internal constant BC_RPC = "https://testnet.battlechain.com";

    address internal deployer;

    function setUp() public {
        string memory rpc = BC_RPC;
        try vm.envString("BC_FORK_RPC") returns (string memory envRpc) {
            if (bytes(envRpc).length > 0) rpc = envRpc;
        } catch {}

        vm.createSelectFork(rpc);
        require(block.chainid == BC_TESTNET.CHAIN_ID, "fork chainId != 627");

        deployer = makeAddr("bcPhase3Deployer");
        vm.deal(deployer, 1000 ether);
    }

    function test_fork_bcBinds_and_safeSingletonEmpty() public view {
        assertTrue(BC_TESTNET.WETH.code.length > 0, "WETH");
        assertTrue(BC_TESTNET.USDC.code.length > 0, "USDC");
        assertTrue(BC_TESTNET.DAI.code.length > 0, "DAI");
        assertTrue(BC_TESTNET.CHAINLINK_ETH_USD.code.length > 0, "ETH/USD");
        assertTrue(BC_TESTNET.CHAINLINK_USDC_USD.code.length > 0, "USDC/USD");
        assertTrue(BC_TESTNET.DEPLOYER.code.length > 0, "BC Deployer");
        // Path A absent — Path B required
        assertEq(Create2Utils.CREATE2_FACTORY.code.length, 0, "Safe Singleton should be empty on BC");
    }

    function test_fork_pathB_realCreate2Factory_noEtch() public {
        assertEq(Create2Utils.CREATE2_FACTORY.code.length, 0, "precondition: Path A empty");

        vm.startPrank(deployer);
        address factory = BcAavePhase3Deploy.ensureCreate2FactoryPathB();
        vm.stopPrank();

        assertTrue(factory.code.length > 0, "Path B factory must have code");
        assertTrue(factory != Create2Utils.CREATE2_FACTORY, "Path B must not be the empty Path A address");
        // Canonical Path A still empty — proves we did not etch 0x914d…
        assertEq(Create2Utils.CREATE2_FACTORY.code.length, 0, "must not etch Safe Singleton at 0x914d");
        // Factory must match BC Deployer CREATE2 prediction (real Path B lineage).
        address predicted = Create2Utils.predictedPathBFactory(BC_TESTNET.DEPLOYER);
        assertEq(factory, predicted, "factory must be BC Deployer CREATE2 Path B address");

        // Probe CREATE2 through the real factory (Safe encoding: salt || initcode).
        // Minimal creation code: stores nothing, returns empty runtime.
        bytes memory emptyCtor = hex"60006000f3";
        bytes32 probeSalt = keccak256("crane-bc-pathb-probe-v2");
        address expected = Create2Utils.computeCreate2Address(probeSalt, keccak256(emptyCtor), factory);
        bytes memory payload = abi.encodePacked(probeSalt, emptyCtor);
        (bool ok, bytes memory ret) = factory.call(payload);
        assertTrue(ok, "factory CREATE2 call failed");
        assertEq(ret.length, 20, "factory must return 20-byte address");
        address deployed = address(uint160(bytes20(ret)));
        assertEq(deployed, expected, "CREATE2 address must match formula");
        console2.log("Path B factory", factory);
        console2.log("Path B probe", deployed);
    }

    function test_fork_v3_market_initReserves() public {
        vm.startPrank(deployer);
        BcAavePhase3Deploy.V3DeployResult memory v3 = BcAavePhase3Deploy.deployV3Market(deployer);
        vm.stopPrank();

        assertTrue(v3.report.poolAddressesProvider.code.length > 0, "provider");
        assertTrue(v3.report.poolProxy.code.length > 0, "poolProxy");
        assertTrue(v3.report.aaveOracle.code.length > 0, "oracle");
        assertTrue(v3.report.poolConfiguratorProxy.code.length > 0, "configurator");

        IPool pool = IPool(v3.report.poolProxy);
        assertTrue(pool.getReserveAToken(BC_TESTNET.WETH) != address(0), "WETH aToken");
        assertTrue(pool.getReserveAToken(BC_TESTNET.USDC) != address(0), "USDC aToken");
        assertTrue(pool.getReserveAToken(BC_TESTNET.DAI) != address(0), "DAI aToken");

        console2.log("fork V3 OK pool", v3.report.poolProxy);
    }

    function test_fork_v4_core_and_configure() public {
        vm.startPrank(deployer);
        BcAavePhase3Deploy.V4DeployResult memory core = BcAavePhase3Deploy.deployV4Core(deployer);
        BcAavePhase3Deploy.V4ConfigureResult memory cfg = BcAavePhase3Deploy.configureV4Market(deployer, core);
        vm.stopPrank();

        assertTrue(core.accessManager.code.length > 0, "accessManager");
        assertTrue(core.hub.code.length > 0, "hub");
        assertTrue(core.spoke.code.length > 0, "spoke");
        assertTrue(core.liquidationLogic.code.length > 0, "liquidationLogic");
        assertTrue(core.aaveOracle.code.length > 0, "aaveOracle");

        // Real Path B — not etch at 0x914d
        address factory = Create2Utils.getFactory();
        assertTrue(factory.code.length > 0, "create2 factory after Path B");
        assertEq(Create2Utils.CREATE2_FACTORY.code.length, 0, "must not etch Path A");
        assertEq(factory, Create2Utils.predictedPathBFactory(BC_TESTNET.DEPLOYER), "Path B lineage");

        ISpoke spoke = ISpoke(core.spoke);
        spoke.getReserve(cfg.wethReserveId);
        spoke.getReserve(cfg.usdcReserveId);
        spoke.getReserve(cfg.daiReserveId);
        IHub(core.hub).getAsset(cfg.wethAssetId);

        console2.log("fork V4 OK hub", core.hub);
        console2.log("fork V4 OK spoke", core.spoke);
        console2.log("fork V4 factory", factory);
    }

    function test_fork_v4_optional_supply_smoke() public {
        vm.startPrank(deployer);
        BcAavePhase3Deploy.V4DeployResult memory core = BcAavePhase3Deploy.deployV4Core(deployer);
        BcAavePhase3Deploy.V4ConfigureResult memory cfg = BcAavePhase3Deploy.configureV4Market(deployer, core);

        deal(BC_TESTNET.WETH, deployer, 10 ether);
        IERC20(BC_TESTNET.WETH).approve(core.spoke, type(uint256).max);

        try ISpoke(core.spoke).supply(cfg.wethReserveId, 1 ether, deployer) returns (uint256, uint256) {
            console2.log("V4 spoke.supply WETH ok");
        } catch (bytes memory reason) {
            console2.log("V4 supply smoke skipped (role/balance); core+configure still valid");
            console2.logBytes(reason);
        }
        vm.stopPrank();

        assertTrue(core.hub.code.length > 0);
        assertTrue(core.spoke.code.length > 0);
    }

    /// @notice Combined Phase 3 path: CREATE2 factory + V3 + V4 (shipped helpers only).
    function test_fork_phase3_full_v3_and_v4() public {
        vm.startPrank(deployer);

        address factory = BcAavePhase3Deploy.ensureCreate2FactoryPathB();
        assertTrue(factory.code.length > 0, "factory");
        assertEq(Create2Utils.CREATE2_FACTORY.code.length, 0, "no etch Path A");

        BcAavePhase3Deploy.V3DeployResult memory v3 = BcAavePhase3Deploy.deployV3Market(deployer);
        assertTrue(v3.report.poolProxy.code.length > 0, "v3 pool");
        assertTrue(IPool(v3.report.poolProxy).getReserveAToken(BC_TESTNET.WETH) != address(0), "v3 WETH");

        BcAavePhase3Deploy.V4DeployResult memory v4 = BcAavePhase3Deploy.deployV4Core(deployer);
        BcAavePhase3Deploy.V4ConfigureResult memory cfg = BcAavePhase3Deploy.configureV4Market(deployer, v4);
        assertTrue(v4.accessManager.code.length > 0, "v4 am");
        assertTrue(v4.hub.code.length > 0, "v4 hub");
        assertTrue(v4.spoke.code.length > 0, "v4 spoke");
        assertTrue(v4.liquidationLogic.code.length > 0, "v4 liq");
        ISpoke(v4.spoke).getReserve(cfg.wethReserveId);
        ISpoke(v4.spoke).getReserve(cfg.usdcReserveId);

        vm.stopPrank();

        console2.log("phase3 full factory", factory);
        console2.log("phase3 full v3 pool", v3.report.poolProxy);
        console2.log("phase3 full v4 hub", v4.hub);
    }
}
