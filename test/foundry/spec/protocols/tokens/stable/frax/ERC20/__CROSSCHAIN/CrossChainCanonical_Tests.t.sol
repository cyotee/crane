// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/CrossChainCanonical-Tests.js`
/// @dev Local deploy with DummyToken stand-in for anyFRAX (same ERC20 bridge semantics).

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {CrossChainCanonicalFRAX} from
    "@crane/contracts/protocols/tokens/stable/frax/ERC20/__CROSSCHAIN/CrossChainCanonicalFRAX.sol";
import {DummyToken} from "@crane/contracts/protocols/tokens/stable/frax/Fraxferry/DummyToken.sol";

contract CrossChainCanonical_Tests is Test {
    uint256 internal constant INITIAL_MINT = 1_000_000e18;
    uint256 internal constant PRICE_PRECISION = 1e6;
    uint256 internal constant SWAP_FEE = 400; // 0.04%

    address internal collateralOwner;
    address internal governorGuardian;
    address internal oracleAdmin;
    address internal timelockAdmin;
    address internal stakingRewardsDistributor;

    DummyToken internal bridgeToken;
    DummyToken internal invalidToken;
    CrossChainCanonicalFRAX internal canFrax;

    function setUp() public {
        collateralOwner = makeAddr("collateralOwner");
        governorGuardian = makeAddr("governorGuardian");
        oracleAdmin = makeAddr("oracleAdmin");
        timelockAdmin = makeAddr("timelockAdmin");
        stakingRewardsDistributor = makeAddr("stakingRewardsDistributor");

        bridgeToken = new DummyToken();
        invalidToken = new DummyToken();

        address[] memory bridges = new address[](1);
        bridges[0] = address(bridgeToken);

        vm.prank(collateralOwner);
        canFrax = new CrossChainCanonicalFRAX(
            "Frax",
            "FRAX",
            collateralOwner,
            INITIAL_MINT,
            collateralOwner,
            bridges
        );

        _seedBalances();
        _runInitializationSetup();
    }

    function _seedBalances() internal {
        bridgeToken.mint(collateralOwner, 50_000e18);
        bridgeToken.mint(governorGuardian, 5_000e18);
        bridgeToken.mint(oracleAdmin, 5_000e18);
        bridgeToken.mint(timelockAdmin, 5_000e18);
        bridgeToken.mint(stakingRewardsDistributor, 5_000e18);

        vm.startPrank(collateralOwner);
        canFrax.transfer(oracleAdmin, 1_000e18);
        canFrax.transfer(timelockAdmin, 1_000e18);
        canFrax.transfer(stakingRewardsDistributor, 1_000e18);
        vm.stopPrank();
    }

    function _runInitializationSetup() internal {
        vm.startPrank(collateralOwner);
        canFrax.setMintCap(10_000_000e18);
        canFrax.toggleFeesForAddress(timelockAdmin);
        canFrax.setSwapFees(address(bridgeToken), SWAP_FEE, SWAP_FEE);
        vm.stopPrank();

        bridgeToken.mint(governorGuardian, 5_000e18);
    }

    function test_Initialization_listsBridgeToken() public view {
        address[] memory tokens = canFrax.allBridgeTokens();
        assertEq(tokens.length, 1);
        assertEq(tokens[0], address(bridgeToken));
    }

    function test_MainFunctions_exchangesMintBurnWithdraw() public {
        uint256 exchangeAmt = 100e18;

        // Old -> new, non-minter, non-exempt (fee applies)
        uint256 govCanBefore = canFrax.balanceOf(governorGuardian);
        uint256 govBridgeBefore = bridgeToken.balanceOf(governorGuardian);

        vm.startPrank(governorGuardian);
        bridgeToken.approve(address(canFrax), 500e18);
        canFrax.exchangeOldForCanonical(address(bridgeToken), exchangeAmt);
        vm.stopPrank();

        uint256 expectedCan = exchangeAmt - (exchangeAmt * SWAP_FEE / PRICE_PRECISION);
        assertEq(canFrax.balanceOf(governorGuardian), govCanBefore + expectedCan);
        assertEq(bridgeToken.balanceOf(governorGuardian), govBridgeBefore - exchangeAmt);

        // Add minter and exchange as minter (fee exempt)
        vm.prank(collateralOwner);
        canFrax.addMinter(stakingRewardsDistributor);

        uint256 distCanBefore = canFrax.balanceOf(stakingRewardsDistributor);
        uint256 distBridgeBefore = bridgeToken.balanceOf(stakingRewardsDistributor);

        vm.startPrank(stakingRewardsDistributor);
        bridgeToken.approve(address(canFrax), 500e18);
        canFrax.exchangeOldForCanonical(address(bridgeToken), exchangeAmt);
        vm.stopPrank();

        assertEq(canFrax.balanceOf(stakingRewardsDistributor), distCanBefore + exchangeAmt);
        assertEq(bridgeToken.balanceOf(stakingRewardsDistributor), distBridgeBefore - exchangeAmt);

        // Fee-exempt timelock admin
        uint256 tlCanBefore = canFrax.balanceOf(timelockAdmin);
        uint256 tlBridgeBefore = bridgeToken.balanceOf(timelockAdmin);

        vm.startPrank(timelockAdmin);
        bridgeToken.approve(address(canFrax), 500e18);
        canFrax.exchangeOldForCanonical(address(bridgeToken), exchangeAmt);
        vm.stopPrank();

        assertEq(canFrax.balanceOf(timelockAdmin), tlCanBefore + exchangeAmt);
        assertEq(bridgeToken.balanceOf(timelockAdmin), tlBridgeBefore - exchangeAmt);

        // Minter mint / burn
        uint256 mintAmt = 100e18;
        uint256 burnAmt = 10e18;

        vm.prank(stakingRewardsDistributor);
        canFrax.minter_mint(stakingRewardsDistributor, mintAmt);
        assertEq(canFrax.balanceOf(stakingRewardsDistributor), distCanBefore + exchangeAmt + mintAmt);

        vm.prank(stakingRewardsDistributor);
        canFrax.minter_burn(burnAmt);

        // New -> old as minter
        uint256 exchangeBack = 25e18;
        uint256 canBeforeBack = canFrax.balanceOf(stakingRewardsDistributor);
        uint256 bridgeBeforeBack = bridgeToken.balanceOf(stakingRewardsDistributor);

        vm.prank(stakingRewardsDistributor);
        canFrax.exchangeCanonicalForOld(address(bridgeToken), exchangeBack);

        assertEq(canFrax.balanceOf(stakingRewardsDistributor), canBeforeBack - exchangeBack);
        assertEq(bridgeToken.balanceOf(stakingRewardsDistributor), bridgeBeforeBack + exchangeBack);

        // New -> old non-minter (fee on bridge out)
        uint256 oracleExchange = 10e18;
        uint256 oracleCanBefore = canFrax.balanceOf(oracleAdmin);
        uint256 oracleBridgeBefore = bridgeToken.balanceOf(oracleAdmin);
        uint256 expectedBridgeOut = oracleExchange - (oracleExchange * SWAP_FEE / PRICE_PRECISION);

        vm.prank(oracleAdmin);
        canFrax.exchangeCanonicalForOld(address(bridgeToken), oracleExchange);

        assertEq(canFrax.balanceOf(oracleAdmin), oracleCanBefore - oracleExchange);
        assertEq(bridgeToken.balanceOf(oracleAdmin), oracleBridgeBefore + expectedBridgeOut);

        // Fee-exempt canonical -> old
        uint256 tlExchange = 10e18;
        uint256 tlCanBefore2 = canFrax.balanceOf(timelockAdmin);
        uint256 tlBridgeBefore2 = bridgeToken.balanceOf(timelockAdmin);

        vm.prank(timelockAdmin);
        canFrax.exchangeCanonicalForOld(address(bridgeToken), tlExchange);

        assertEq(canFrax.balanceOf(timelockAdmin), tlCanBefore2 - tlExchange);
        assertEq(bridgeToken.balanceOf(timelockAdmin), tlBridgeBefore2 + tlExchange);

        vm.prank(collateralOwner);
        canFrax.removeMinter(stakingRewardsDistributor);

        // Withdraw bridge tokens (owner)
        uint256 ownerBridgeBefore = bridgeToken.balanceOf(collateralOwner);
        vm.prank(collateralOwner);
        canFrax.withdrawBridgeTokens(address(bridgeToken), tlExchange);
        assertEq(bridgeToken.balanceOf(collateralOwner), ownerBridgeBefore + tlExchange);
    }

    function test_FailTests_guards() public {
        uint256 testAmt = 1e18;

        vm.prank(governorGuardian);
        bridgeToken.approve(address(canFrax), 500e18);

        vm.prank(collateralOwner);
        canFrax.setMintCap(100e18);

        vm.prank(governorGuardian);
        vm.expectRevert("Invalid old token");
        canFrax.exchangeOldForCanonical(address(invalidToken), testAmt);

        vm.startPrank(collateralOwner);
        canFrax.toggleExchanges();
        vm.stopPrank();

        vm.prank(governorGuardian);
        vm.expectRevert("Exchanges paused");
        canFrax.exchangeOldForCanonical(address(bridgeToken), testAmt);

        vm.startPrank(collateralOwner);
        canFrax.toggleExchanges();
        vm.stopPrank();

        vm.prank(governorGuardian);
        vm.expectRevert("Mint cap");
        canFrax.exchangeOldForCanonical(address(bridgeToken), 250e18);

        vm.prank(governorGuardian);
        vm.expectRevert("TransferHelper: TRANSFER_FROM_FAILED");
        canFrax.exchangeOldForCanonical(address(bridgeToken), 10_000e18);

        vm.prank(governorGuardian);
        vm.expectRevert("Not minter, owner, or tlck");
        canFrax.withdrawBridgeTokens(address(bridgeToken), testAmt);

        vm.prank(collateralOwner);
        vm.expectRevert("Invalid old token");
        canFrax.withdrawBridgeTokens(address(invalidToken), testAmt);

        vm.prank(collateralOwner);
        vm.expectRevert("TransferHelper: TRANSFER_FAILED");
        canFrax.withdrawBridgeTokens(address(bridgeToken), 1_000_000_000e18);

        vm.prank(collateralOwner);
        canFrax.toggleBridgeToken(address(bridgeToken));

        vm.prank(collateralOwner);
        vm.expectRevert("Invalid old token");
        canFrax.withdrawBridgeTokens(address(bridgeToken), testAmt);

        vm.prank(collateralOwner);
        canFrax.toggleBridgeToken(address(bridgeToken));

        vm.prank(governorGuardian);
        vm.expectRevert("Not a minter");
        canFrax.minter_mint(governorGuardian, testAmt);

        vm.startPrank(collateralOwner);
        canFrax.addMinter(governorGuardian);
        vm.stopPrank();

        vm.prank(governorGuardian);
        vm.expectRevert("Mint cap");
        canFrax.minter_mint(governorGuardian, 1_000_000_000e18);

        vm.prank(collateralOwner);
        canFrax.removeMinter(governorGuardian);

        vm.prank(governorGuardian);
        vm.expectRevert("Not a minter");
        canFrax.minter_mint(governorGuardian, testAmt);

        vm.prank(collateralOwner);
        canFrax.addMinter(governorGuardian);

        vm.prank(governorGuardian);
        vm.expectRevert();
        canFrax.burnFrom(collateralOwner, testAmt);

        vm.prank(collateralOwner);
        canFrax.removeMinter(governorGuardian);
    }
}