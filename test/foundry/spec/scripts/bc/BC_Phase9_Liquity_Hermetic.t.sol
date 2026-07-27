// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

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
import {ChainlinkOracleMock} from
    "test/foundry/spec/protocols/staking/liquity/v2/bold/TestContracts/ChainlinkOracleMock.sol";
import {WETHTester} from
    "test/foundry/spec/protocols/staking/liquity/v2/bold/TestContracts/WETHTester.sol";

import {BcLiquityPhase9Deploy} from "scripts/foundry/bc/BcLiquityPhase9Deploy.sol";

/// @notice Phase 9 local hermetic smoke: real BcLiquityPhase9Deploy + openTrove.
/// @dev Controllable WETH/oracle doubles only (not SUT). No live BC broadcast.
contract BC_Phase9_Liquity_Hermetic_Test is Test {
    BcLiquityPhase9Deploy internal phase9;
    BcLiquityPhase9Deploy.DeployResult internal branch;
    WETHTester internal weth;
    ChainlinkOracleMock internal ethUsd;

    function setUp() public {
        weth = new WETHTester(100 ether, 1 days);
        ethUsd = new ChainlinkOracleMock();
        ethUsd.setDecimals(8);
        ethUsd.setPrice(2000e8); // $2000 ETH
        ethUsd.setUpdatedAt(block.timestamp);

        phase9 = new BcLiquityPhase9Deploy();
        branch = phase9.deployWethBranch(address(weth), address(ethUsd));
    }

    function test_hermetic_fullBranch_hasCode_andWiring() public {
        assertTrue(address(branch.boldToken).code.length > 0, "BoldToken");
        assertTrue(address(branch.collateralRegistry).code.length > 0, "CollateralRegistry");
        assertTrue(address(branch.addressesRegistry).code.length > 0, "AddressesRegistry");
        assertTrue(address(branch.activePool).code.length > 0, "ActivePool");
        assertTrue(address(branch.defaultPool).code.length > 0, "DefaultPool");
        assertTrue(branch.gasPool.code.length > 0, "GasPool");
        assertTrue(address(branch.collSurplusPool).code.length > 0, "CollSurplusPool");
        assertTrue(address(branch.stabilityPool).code.length > 0, "StabilityPool");
        assertTrue(address(branch.sortedTroves).code.length > 0, "SortedTroves");
        assertTrue(address(branch.troveManager).code.length > 0, "TroveManager");
        assertTrue(address(branch.troveNFT).code.length > 0, "TroveNFT");
        assertTrue(address(branch.metadataNFT).code.length > 0, "MetadataNFT");
        assertTrue(address(branch.borrowerOperations).code.length > 0, "BorrowerOperations");
        assertTrue(address(branch.priceFeed).code.length > 0, "PriceFeed");
        assertTrue(address(branch.hintHelpers).code.length > 0, "HintHelpers");
        assertTrue(address(branch.multiTroveGetter).code.length > 0, "MultiTroveGetter");
        assertTrue(address(branch.redemptionHelper).code.length > 0, "RedemptionHelper");
        assertTrue(address(branch.debtInFrontHelper).code.length > 0, "DebtInFrontHelper");
        assertTrue(address(branch.interestRouter).code.length > 0, "InterestRouter");

        IAddressesRegistry reg = branch.addressesRegistry;
        assertEq(address(reg.borrowerOperations()), address(branch.borrowerOperations), "reg.BO");
        assertEq(address(reg.troveManager()), address(branch.troveManager), "reg.TM");
        assertEq(address(reg.stabilityPool()), address(branch.stabilityPool), "reg.SP");
        assertEq(address(reg.activePool()), address(branch.activePool), "reg.AP");
        assertEq(address(reg.priceFeed()), address(branch.priceFeed), "reg.PF");
        assertEq(address(reg.boldToken()), address(branch.boldToken), "reg.BOLD");
        assertEq(address(reg.collateralRegistry()), address(branch.collateralRegistry), "reg.CR");
        assertEq(address(reg.collToken()), address(weth), "reg.coll=WETH");
        assertEq(address(reg.WETH()), address(weth), "reg.WETH");
        assertTrue(address(reg.borrowerOperations()) != address(0), "BO non-zero");
        assertTrue(address(reg.troveManager()) != address(0), "TM non-zero");
        assertTrue(address(reg.priceFeed()) != address(0), "PF non-zero");
        assertEq(address(reg.gasPoolAddress()), branch.gasPool, "reg.gasPool");
        assertEq(address(reg.sortedTroves()), address(branch.sortedTroves), "reg.ST");
        assertEq(address(reg.hintHelpers()), address(branch.hintHelpers), "reg.HH");
        assertEq(address(reg.multiTroveGetter()), address(branch.multiTroveGetter), "reg.MTG");
        assertEq(address(reg.interestRouter()), address(branch.interestRouter), "reg.IR");
        assertEq(address(reg.troveNFT()), address(branch.troveNFT), "reg.TNFT");
        assertEq(address(reg.metadataNFT()), address(branch.metadataNFT), "reg.Meta");
        assertEq(address(reg.defaultPool()), address(branch.defaultPool), "reg.DP");
        assertEq(address(reg.collSurplusPool()), address(branch.collSurplusPool), "reg.CSP");

        assertEq(branch.ethUsdOracle, address(ethUsd), "oracle bind");
        assertEq(address(branch.weth), address(weth), "weth bind");
        assertEq(
            BoldToken(address(branch.boldToken)).collateralRegistryAddress(),
            address(branch.collateralRegistry),
            "BOLD.CR"
        );
    }

    function test_hermetic_priceFeed_fetchPrice() public {
        (uint256 price, bool failed) = branch.priceFeed.fetchPrice();
        assertFalse(failed, "oracle should not fail");
        assertEq(price, 2000e18, "scaled $2000");
        console2.log("ETH/USD price (1e18)", price);
    }

    /// @notice Open WETH trove via real BorrowerOperations on the wired branch.
    /// @dev MIN_DEBT = 2000e18 BOLD; also pulls ETH_GAS_COMPENSATION (0.0375 WETH).
    function test_hermetic_openTrove_weth() public {
        address user = makeAddr("boldUser");
        vm.deal(user, 100 ether);

        uint256 coll = 10 ether;
        uint256 gasComp = ETH_GAS_COMPENSATION;
        uint256 boldAmount = MIN_DEBT;
        uint256 interestRate = MIN_ANNUAL_INTEREST_RATE;

        vm.startPrank(user);
        IWETH(address(weth)).deposit{value: coll + gasComp + 1 ether}();
        IERC20(address(weth)).approve(address(branch.borrowerOperations), type(uint256).max);

        uint256 upfrontFee = branch.hintHelpers.predictOpenTroveUpfrontFee(0, boldAmount, interestRate);
        console2.log("upfrontFee", upfrontFee);
        console2.log("boldAmount", boldAmount);
        console2.log("coll", coll);
        console2.log("MIN_DEBT", MIN_DEBT);
        console2.log("ETH_GAS_COMPENSATION", ETH_GAS_COMPENSATION);

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
