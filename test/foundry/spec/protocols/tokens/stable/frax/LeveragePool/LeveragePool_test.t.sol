// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/LeveragePool-test.js`

import {Test} from "forge-std/Test.sol";
import {
    LeveragePool,
    TestOracle,
    BaseInterestRateModel
} from "@crane/contracts/protocols/tokens/stable/frax/LeveragePool/LeveragePool.sol";
import {TestERC20} from "@crane/contracts/protocols/tokens/stable/frax/LeveragePool/TestERC20.sol";
import {IERC20} from "@crane/contracts/protocols/tokens/stable/frax/LeveragePool/IERC20.sol";

contract LeveragePool_test is Test {
    int256 internal constant ONE = 1e18;

    address internal owner;
    address internal newOwner;
    address internal user1;
    address internal user2;
    address internal user3;
    TestERC20 internal collateral;
    TestOracle internal oracle;
    BaseInterestRateModel internal fundingRateModel;
    LeveragePool internal pool;

    function setUp() public {
        owner = address(this);
        newOwner = makeAddr("newOwner");
        user1 = makeAddr("user1");

        collateral = new TestERC20();
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        collateral.mint(owner, 1_000e18);
        collateral.mint(user1, 1_000e18);
        collateral.mint(user2, 1_000e18);
        collateral.mint(user3, 1_000e18);
        oracle = new TestOracle();
        fundingRateModel = new BaseInterestRateModel();
        pool = new LeveragePool(IERC20(address(collateral)), oracle, fundingRateModel, 0);
        pool.initializePools();
    }

    function test_Deploy_initialState() public view {
        assertEq(pool.admin(), owner);
        assertEq(address(pool.collateralToken()), address(collateral));
        assertEq(address(pool.oracle()), address(oracle));
        assertEq(address(pool.fundingRateModel()), address(fundingRateModel));
        assertEq(pool.epoch(), 0);
        assertEq(pool.price(), int256(1e18));
    }

    function test_setEpochPeriods() public {
        pool.setEpochPeriods(3600, 360);
        assertEq(pool.epochPeriod(), 3600);
        assertEq(pool.waitPeriod(), 360);
    }

    function test_setFees_revertsAndSets() public {
        vm.expectRevert("Fees not correct");
        pool.setFees(1e15, 4e17, 7e17);

        vm.expectRevert("Fees can not be negative");
        pool.setFees(-1e15, 3e17, 7e17);

        pool.setFees(2e16, 3e17, 7e17);
        assertEq(pool.TRANSACTION_FEE(), 2e16);
        assertEq(pool.ADMIN_FEES(), 3e17);
        assertEq(pool.LIQUIDITYPOOL_FEES(), 7e17);

        vm.expectRevert("Transaction fee too high");
        pool.setFees(2e16 + 1, 3e17, 7e17);

        pool.setFees(1e15, 3e17, 7e17);
        assertEq(pool.TRANSACTION_FEE(), 1e15);
    }

    function test_setChangeCap() public {
        assertEq(pool.CHANGE_CAP(), 5e16);
        pool.setChangeCap(6e16);
        assertEq(pool.CHANGE_CAP(), 6e16);
    }

    function test_setOracle() public {
        TestOracle newOracle = new TestOracle();
        assertTrue(address(pool.oracle()) != address(newOracle));
        pool.setOracle(address(newOracle));
        assertEq(address(pool.oracle()), address(newOracle));
    }

    function test_setFundingRateModel() public {
        BaseInterestRateModel newModel = new BaseInterestRateModel();
        assertTrue(address(pool.fundingRateModel()) != address(newModel));
        pool.setFundingRateModel(address(newModel));
        assertEq(address(pool.fundingRateModel()), address(newModel));
    }

    function test_setAdmin() public {
        assertEq(pool.admin(), owner);
        vm.expectRevert("Admin can not be zero");
        pool.setAdmin(address(0));

        pool.setAdmin(newOwner);
        assertEq(pool.admin(), newOwner);

        vm.expectRevert("Only admin");
        pool.setAdmin(owner);

        vm.prank(newOwner);
        pool.setAdmin(owner);
        assertEq(pool.admin(), owner);
    }

    function test_initializePools_layout() public view {
        _checkPool(0, 0, 0, 1, 0, true);
        _checkPool(1, 0, 0, 1, 0, false);
        _checkPool(2, 0, 0, -1, 1, false);
        _checkPool(3, 0, 0, 2, 0, true);
        _checkPool(4, 0, 0, 2, 1, false);
        _checkPool(5, 0, 0, -2, 3, false);
        _checkPool(6, 0, 0, 3, 0, true);
        _checkPool(7, 0, 0, 3, 3, false);
        _checkPool(8, 0, 0, -3, 6, false);
    }

    function test_initializePools_revertsOnOutOfRangeIndex() public {
        vm.expectRevert();
        this.poolsOutOfRange(9);
    }

    function test_startNextEpoch() public {
        assertEq(pool.epoch(), 0);
        pool.startNextEpoch();
        assertEq(pool.epoch(), 0);

        _startNextEpoch();
        assertEq(pool.epoch(), 1);
    }

    function _startNextEpoch() internal {
        uint256 epochPeriod = pool.epochPeriod();
        uint256 epochStart = pool.epochStartTime();
        uint256 target = epochStart + epochPeriod;
        if (block.timestamp < target) {
            vm.warp(target + 1);
        }
        pool.startNextEpoch();
    }

    function poolsOutOfRange(uint256 idx) external view {
        pool.pools(idx);
    }

    function _checkPool(
        uint256 idx,
        int256 shares,
        int256 collateralAmt,
        int256 leverage,
        int256 rebalanceMultiplier,
        bool isLiquidityPool
    ) internal view {
        (int256 pShares, int256 pCollateral, int256 pLeverage, int256 pRebalance, bool pIsLiq) = pool.pools(idx);
        assertEq(pShares, shares);
        assertEq(pCollateral, collateralAmt);
        assertEq(pLeverage, leverage);
        assertEq(pRebalance, rebalanceMultiplier);
        assertEq(pIsLiq, isLiquidityPool);
    }

    function test_deposit_liquidityPool_revertsWithoutApproval() public {
        vm.expectRevert();
        pool.deposit(ONE, 0);
    }

    function test_deposit_liquidityPool_revertsOnNegativeAmount() public {
        vm.expectRevert("amount needs to be positive");
        pool.deposit(-1, 0);
    }

    function test_deposit_liquidityPool_revertsOnInvalidPool() public {
        vm.expectRevert("Pool not initialized");
        pool.deposit(ONE, 10);
    }

    function test_deposit_liquidityPool_flow() public {
        assertEq(pool.getUserActionsView(owner).length, 0);
        _checkPoolEpochData(1, 0, 0, 0, 0, 0);

        collateral.approve(address(pool), uint256(ONE));
        pool.deposit(ONE, 0);
        assertEq(collateral.balanceOf(address(pool)), uint256(ONE));

        LeveragePool.Action[] memory actions = pool.getUserActionsView(owner);
        assertEq(actions.length, 1);
        _checkAction(actions[0], 1, 0, ONE, 0);
        _checkPoolEpochData(1, 0, 0, 0, ONE, 0);

        _startNextEpoch();
        _checkPoolEpochData(1, 0, 997e15, 0, ONE, 0);

        actions = pool.getUserActionsView(owner);
        assertEq(actions.length, 1);
        _checkAction(actions[0], 1, 0, ONE, 0);

        pool.bookKeeping();
        assertEq(pool.getUserActionsView(owner).length, 0);

        int256[] memory shares = pool.getUserSharesView(owner);
        assertEq(shares[0], 997e15);

        int256[] memory deposits = pool.getUserDepositsView(owner);
        assertEq(deposits[0], 999_400_000_000_000_000);

        assertEq(pool.adminFees(), 600_000_000_000_000);
    }

    function test_deposit_leveragePool_flow() public {
        collateral.approve(address(pool), uint256(ONE));
        pool.deposit(ONE, 1);
        assertEq(collateral.balanceOf(address(pool)), uint256(ONE));

        LeveragePool.Action[] memory actions = pool.getUserActionsView(owner);
        assertEq(actions.length, 1);
        _checkAction(actions[0], 1, 1, ONE, 0);

        _startNextEpoch();
        _checkPoolEpochData(1, 1, 997e15, 0, ONE, 0);

        pool.bookKeeping();
        assertEq(pool.getUserActionsView(owner).length, 0);

        int256[] memory shares = pool.getUserSharesView(owner);
        assertEq(shares[1], 997e15);

        int256[] memory deposits = pool.getUserDepositsView(owner);
        assertEq(deposits[1], 997e15);

        assertEq(pool.adminFees(), 3e15);
    }

    function test_withdraw_partialAndCollateral() public {
        collateral.approve(address(pool), uint256(ONE));
        pool.deposit(ONE, 0);
        _startNextEpoch();

        pool.withdraw(ONE / 10, 0);

        _checkPoolEpochData(2, 0, 0, 0, 0, ONE / 10);

        _startNextEpoch();
        _checkPoolEpochData(2, 0, 0, 1_002_407_221_664_994_984, 0, ONE / 10);

        assertEq(pool.getWithdrawableCollateralView(owner), 0);
        pool.bookKeeping();
        assertEq(pool.getWithdrawableCollateralView(owner), 100_240_722_166_499_498);

        uint256 balBefore = collateral.balanceOf(owner);
        pool.withdrawCollateral(ONE / 20);
        assertEq(pool.getWithdrawableCollateralView(owner), 50_240_722_166_499_498);
        assertEq(collateral.balanceOf(owner), balBefore + uint256(ONE / 20));
    }

    function test_withdrawAdminFees() public {
        vm.startPrank(user1);
        collateral.approve(address(pool), uint256(ONE));
        pool.deposit(ONE, 0);
        vm.stopPrank();

        _startNextEpoch();

        assertEq(pool.adminFees(), 600_000_000_000_000);

        vm.prank(user1);
        vm.expectRevert("Only admin");
        pool.withdrawAdminFees(600_000_000_000_000);

        uint256 balBefore = collateral.balanceOf(owner);
        pool.withdrawAdminFees(600_000_000_000_000);
        assertEq(collateral.balanceOf(owner), balBefore + 600_000_000_000_000);
    }

    function test_fundingAndRebalanceRates() public {
        _useHourlyEpochs();
        _deposit(user1, ONE, 0);
        _deposit(user2, ONE, 1);
        _deposit(user3, ONE, 2);
        oracle.setPrice(uint256(ONE));
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 0, 1_004_200_000_000_000_000);
        _assertUserDeposit(user2, 1, 997e15);
        _assertUserDeposit(user3, 2, 997e15);

        _checkPoolAmounts(997e15, 997e15, 1_004_200_000_000_000_000, 997e15, ONE, ONE, 0);
        _checkRates(0, 0, 0, 992_830_113_523_202_549, -985_711_634_318_495_261);

        oracle.setPrice(uint256(ONE));
        _startNextEpoch();

        _assertUserDeposit(user1, 0, 1_004_312_921_737_291_278);
        _assertUserDeposit(user2, 1, 997e15);
        _assertUserDeposit(user3, 2, 996_887_078_262_708_722);

        _checkPoolAmounts(
            997e15,
            996_887_078_262_708_722,
            1_004_312_921_737_291_278,
            996_887_078_262_708_722,
            ONE,
            ONE,
            -112_436_806_145_979
        );

        _checkRates(
            113_261_521_856_848,
            -113_261_521_856_848,
            -12_734_763_776,
            992_606_046_070_046_470,
            -985_266_762_694_811_216
        );

        oracle.setPrice(uint256(ONE));
        _startNextEpoch();

        _assertUserDeposit(user1, 0, 1_004_425_805_204_430_958);
        _assertUserDeposit(user2, 1, 996_999_987_117_949_343);
        _assertUserDeposit(user3, 2, 996_774_207_677_619_698);
    }

    function test_priceChange_1xLeverage() public {
        _useHourlyEpochs();
        fundingRateModel.setMultipliers(0, 0);

        _deposit(user1, ONE, 0);
        _deposit(user2, ONE, 1);
        _deposit(user3, ONE, 2);
        oracle.setPrice(uint256(ONE));
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 0, 1_004_200_000_000_000_000);
        _assertUserDeposit(user2, 1, 997e15);
        _assertUserDeposit(user3, 2, 997e15);
        _checkPoolAmounts(997e15, 997e15, 1_004_200_000_000_000_000, 997e15, ONE, ONE, 0);
        _checkRates(0, 0, 0, 0, 0);

        oracle.setPrice(1_010_000_000_000_000_000);
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 0, 1_004_200_000_000_000_000);
        _assertUserDeposit(user2, 1, 1_006_970_000_000_000_000);
        _assertUserDeposit(user3, 2, 987_030_000_000_000_000);
        _checkPoolAmounts(
            1_006_970_000_000_000_000,
            987_030_000_000_000_000,
            1_004_200_000_000_000_000,
            987_030_000_000_000_000,
            ONE,
            ONE,
            -19_856_602_270_464_050
        );
        _checkRates(0, 0, 0, 0, 0);

        oracle.setPrice(1_030_200_000_000_000_000);
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 0, 1_003_801_200_000_000_001);
        _assertUserDeposit(user2, 1, 1_027_109_400_000_000_000);
        _assertUserDeposit(user3, 2, 967_289_400_000_000_000);
        _checkPoolAmounts(
            1_027_109_400_000_000_000,
            967_289_400_000_000_000,
            1_003_801_200_000_000_001,
            967_289_400_000_000_000,
            ONE,
            ONE,
            -59_593_473_289_332_588
        );
        _checkRates(0, 0, 0, 0, 0);

        oracle.setPrice(1_092_012_000_000_000_000);
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 0, 999_290_772_000_000_003);
        _assertUserDeposit(user2, 1, 1_088_735_963_999_999_999);
        _assertUserDeposit(user3, 2, 910_173_264_000_000_001);
    }

    function test_priceChange_2xLeverage() public {
        _useHourlyEpochs();
        fundingRateModel.setMultipliers(0, 0);

        _deposit(user1, ONE, 3);
        _deposit(user2, ONE, 4);
        _deposit(user3, ONE, 5);
        oracle.setPrice(uint256(ONE));
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 3, 1_008_400_000_000_000_000);
        _assertUserDeposit(user2, 4, 994e15);
        _assertUserDeposit(user3, 5, 994e15);
        _checkPoolAmounts(
            1_988_000_000_000_000_000,
            1_988_000_000_000_000_000,
            2_016_800_000_000_000_000,
            3_976_000_000_000_000_000,
            ONE,
            ONE,
            0
        );
        _checkRates(0, 0, 0, 0, 0);

        oracle.setPrice(1_010_000_000_000_000_000);
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 3, 1_008_400_000_000_000_000);
        _assertUserDeposit(user2, 4, 1_013_880_000_000_000_000);
        _assertUserDeposit(user3, 5, 974_120_000_000_000_000);
        _checkPoolAmounts(
            2_027_760_000_000_000_000,
            1_948_240_000_000_000_000,
            2_016_800_000_000_000_000,
            3_936_240_000_000_000_000,
            ONE,
            ONE,
            -39_428_798_095_993_653
        );
        _checkRates(0, 0, 0, 0, 0);

        oracle.setPrice(1_030_200_000_000_000_000);
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 3, 1_006_809_600_000_000_001);
        _assertUserDeposit(user2, 4, 1_054_435_200_000_000_000);
        _assertUserDeposit(user3, 5, 935_155_200_000_000_000);
        _checkPoolAmounts(
            2_108_870_400_000_000_000,
            1_870_310_400_000_000_000,
            2_013_619_200_000_000_002,
            3_859_900_800_000_000_000,
            ONE,
            ONE,
            -118_473_244_593_615_317
        );
        _checkRates(0, 0, 0, 0, 0);

        oracle.setPrice(1_092_012_000_000_000_000);
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user1, 3, 988_819_904_000_000_005);
        _assertUserDeposit(user2, 4, 1_181_971_647_999_999_998);
        _assertUserDeposit(user3, 5, 825_608_448_000_000_002);
    }

    function test_lowLiquidityAttack() public {
        _useHourlyEpochs();
        fundingRateModel.setMaxRebalanceRate(1e36);

        _deposit(user2, ONE, 4);
        _deposit(user3, ONE, 5);
        oracle.setPrice(uint256(ONE));
        _startNextEpoch();
        _bookKeepAll();

        _assertUserDeposit(user2, 4, 994e15);
        _assertUserDeposit(user3, 5, 994e15);

        _deposit(user1, 1, 3);
        _startNextEpoch();
        vm.prank(user1);
        pool.bookKeeping();
        _assertUserDeposit(user1, 3, 1);

        _startNextEpoch();

        int256[] memory d1 = pool.getUserDepositsView(user1);
        assertEq(d1[3], 453_579_927_491_096_098_254_356_124_127_578);
        int256[] memory d2 = pool.getUserDepositsView(user2);
        assertEq(d2[4], -113_394_981_872_773_030_563_589_031_031_894);
        int256[] memory d3 = pool.getUserDepositsView(user3);
        assertEq(d3[5], -340_184_945_618_321_079_690_767_093_095_683);
    }

    function _useHourlyEpochs() internal {
        pool.setEpochPeriods(3600, 360);
    }

    function _deposit(address user, int256 amount, uint256 poolIdx) internal {
        vm.startPrank(user);
        collateral.approve(address(pool), uint256(amount));
        pool.deposit(amount, poolIdx);
        vm.stopPrank();
    }

    function _bookKeepAll() internal {
        vm.prank(user1);
        pool.bookKeeping();
        vm.prank(user2);
        pool.bookKeeping();
        vm.prank(user3);
        pool.bookKeeping();
    }

    function _assertUserDeposit(address user, uint256 poolIdx, int256 expected) internal view {
        int256[] memory deposits = pool.getUserDepositsView(user);
        assertEq(deposits[poolIdx], expected);
    }

    function _checkPoolAmounts(
        int256 longAmount,
        int256 shortAmount,
        int256 liquidityPoolAmount,
        int256 rebalanceAmount,
        int256 longLeverage,
        int256 shortLeverage,
        int256 liquidityPoolLeverage
    ) internal view {
        LeveragePool.PoolAmounts memory amounts = pool.calculatePoolAmounts();
        assertEq(amounts.longAmount, longAmount);
        assertEq(amounts.shortAmount, shortAmount);
        assertEq(amounts.liquidityPoolAmount, liquidityPoolAmount);
        assertEq(amounts.rebalanceAmount, rebalanceAmount);
        assertEq(amounts.longLeverage, longLeverage);
        assertEq(amounts.shortLeverage, shortLeverage);
        assertEq(amounts.liquidityPoolLeverage, liquidityPoolLeverage);
    }

    function _checkRates(
        int256 longFundingRate,
        int256 shortFundingRate,
        int256 liquidityPoolFundingRate,
        int256 rebalanceRate,
        int256 rebalanceLiquidityPoolRate
    ) internal view {
        LeveragePool.Rates memory rates = pool.getRates();
        assertEq(rates.longFundingRate, longFundingRate);
        assertEq(rates.shortFundingRate, shortFundingRate);
        assertEq(rates.liquidityPoolFundingRate, liquidityPoolFundingRate);
        assertEq(rates.rebalanceRate, rebalanceRate);
        assertEq(rates.rebalanceLiquidityPoolRate, rebalanceLiquidityPoolRate);
    }

    function _checkAction(
        LeveragePool.Action memory action,
        uint256 epoch,
        uint256 poolIdx,
        int256 depositAmount,
        int256 withdrawAmount
    ) internal pure {
        assertEq(action.epoch, epoch);
        assertEq(action.pool, poolIdx);
        assertEq(action.depositAmount, depositAmount);
        assertEq(action.withdrawAmount, withdrawAmount);
    }

    function _checkPoolEpochData(
        uint256 epoch,
        uint256 poolIdx,
        int256 sharesPerCollateralDeposit,
        int256 collateralPerShareWithdraw,
        int256 deposits,
        int256 withdrawals
    ) internal view {
        (int256 spd, int256 cpsw, int256 dep, int256 wit) = pool.poolEpochData(epoch, poolIdx);
        assertEq(spd, sharesPerCollateralDeposit);
        assertEq(cpsw, collateralPerShareWithdraw);
        assertEq(dep, deposits);
        assertEq(wit, withdrawals);
    }
}
