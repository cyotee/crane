// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";
import {
    MIN_DEBT,
    ETH_GAS_COMPENSATION,
    MIN_ANNUAL_INTEREST_RATE
} from "@crane/contracts/protocols/cdps/liquity/v2/bold/Dependencies/Constants.sol";
import {IAddressesRegistry} from
    "@crane/contracts/protocols/cdps/liquity/v2/bold/Interfaces/IAddressesRegistry.sol";
import {BoldToken} from "@crane/contracts/protocols/cdps/liquity/v2/bold/BoldToken.sol";
import {IWETH} from
    "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";

import {BcLiquityPhase9Deploy} from "scripts/foundry/bc/BcLiquityPhase9Deploy.sol";

/// @notice Phase 9 Liquity/BOLD fork smoke against BC testnet WETH + Chainlink ETH/USD.
/// @dev Opt-in: set `BC_FORK_RPC` (and optionally run with network). Hermetic suite is always-on DoD.
///      No live BC broadcast.
contract BC_Phase9_Liquity_Fork_Test is Test {
    bool internal forked;
    BcLiquityPhase9Deploy internal phase9;
    BcLiquityPhase9Deploy.DeployResult internal branch;

    function setUp() public {
        // Opt-in only — createSelectFork failures are not always try/catch-safe in Foundry.
        string memory rpc;
        try vm.envString("BC_FORK_RPC") returns (string memory envRpc) {
            rpc = envRpc;
        } catch {
            console2.log("Phase9 fork: set BC_FORK_RPC to enable (hermetic suite is DoD)");
            return;
        }
        if (bytes(rpc).length == 0) {
            console2.log("Phase9 fork: BC_FORK_RPC empty; skipped");
            return;
        }

        vm.createSelectFork(rpc);
        require(block.chainid == BC_TESTNET.CHAIN_ID, "fork chainId != 627");
        forked = true;

        phase9 = new BcLiquityPhase9Deploy();
        branch = phase9.deployWethBranch(BC_TESTNET.WETH, BC_TESTNET.CHAINLINK_ETH_USD);
    }

    modifier onlyForked() {
        if (!forked) return;
        _;
    }

    function test_fork_bcBinds() public view onlyForked {
        assertTrue(BC_TESTNET.WETH.code.length > 0, "WETH");
        assertTrue(BC_TESTNET.CHAINLINK_ETH_USD.code.length > 0, "ETH/USD");
    }

    function test_fork_fullBranch_hasCode_andWiring() public onlyForked {
        assertTrue(address(branch.boldToken).code.length > 0, "BoldToken");
        assertTrue(address(branch.collateralRegistry).code.length > 0, "CollateralRegistry");
        assertTrue(address(branch.addressesRegistry).code.length > 0, "AddressesRegistry");
        assertTrue(address(branch.borrowerOperations).code.length > 0, "BorrowerOperations");
        assertTrue(address(branch.troveManager).code.length > 0, "TroveManager");
        assertTrue(address(branch.priceFeed).code.length > 0, "PriceFeed");
        assertTrue(address(branch.activePool).code.length > 0, "ActivePool");
        assertTrue(address(branch.stabilityPool).code.length > 0, "StabilityPool");
        assertTrue(branch.gasPool.code.length > 0, "GasPool");

        IAddressesRegistry reg = branch.addressesRegistry;
        assertEq(address(reg.borrowerOperations()), address(branch.borrowerOperations), "reg.BO");
        assertEq(address(reg.troveManager()), address(branch.troveManager), "reg.TM");
        assertEq(address(reg.collToken()), BC_TESTNET.WETH, "reg.coll=WETH");
        assertEq(address(reg.WETH()), BC_TESTNET.WETH, "reg.WETH");
        assertEq(address(reg.priceFeed()), address(branch.priceFeed), "reg.PF");
        assertEq(branch.ethUsdOracle, BC_TESTNET.CHAINLINK_ETH_USD, "oracle bind");
        assertEq(
            BoldToken(address(branch.boldToken)).collateralRegistryAddress(),
            address(branch.collateralRegistry),
            "BOLD.CR"
        );
    }

    function test_fork_priceFeed_fetchPrice() public onlyForked {
        (uint256 price, bool failed) = branch.priceFeed.fetchPrice();
        assertFalse(failed, "oracle should not fail on BC");
        assertGt(price, 0, "price > 0");
        console2.log("ETH/USD price (1e18)", price);
    }

    function test_fork_openTrove_weth() public onlyForked {
        address user = makeAddr("boldUser");
        vm.deal(user, 100 ether);

        uint256 coll = 10 ether;
        uint256 gasComp = ETH_GAS_COMPENSATION;
        uint256 boldAmount = MIN_DEBT;
        uint256 interestRate = MIN_ANNUAL_INTEREST_RATE;

        vm.startPrank(user);
        IWETH(BC_TESTNET.WETH).deposit{value: coll + gasComp + 1 ether}();
        IERC20(BC_TESTNET.WETH).approve(address(branch.borrowerOperations), type(uint256).max);

        uint256 upfrontFee = branch.hintHelpers.predictOpenTroveUpfrontFee(0, boldAmount, interestRate);
        uint256 troveId = branch.borrowerOperations.openTrove(
            user,
            0,
            coll,
            boldAmount,
            0,
            0,
            interestRate,
            upfrontFee + (upfrontFee / 10) + 1e18,
            address(0),
            address(0),
            address(0)
        );
        vm.stopPrank();

        assertTrue(troveId != 0, "troveId");
        assertEq(branch.boldToken.balanceOf(user), boldAmount, "minted boldAmount");
        console2.log("troveId", troveId);
        console2.log("user BOLD", branch.boldToken.balanceOf(user));
    }
}
