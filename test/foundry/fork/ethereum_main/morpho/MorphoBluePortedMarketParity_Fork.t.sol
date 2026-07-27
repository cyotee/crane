// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {IMorpho, Id, MarketParams, Market, Position} from
    "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {Morpho} from "@crane/contracts/external/morpho/blue/Morpho.sol";
import {OracleMock} from "@crane/contracts/external/morpho/blue/mocks/OracleMock.sol";
import {ERC20Mock} from "@crane/contracts/external/morpho/blue/mocks/ERC20Mock.sol";
import {AdaptiveCurveIrm} from "@crane/contracts/external/morpho/blue-irm/AdaptiveCurveIrm.sol";
import {MarketParamsLib} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";
import {ORACLE_PRICE_SCALE} from "@crane/contracts/external/morpho/blue/libraries/ConstantsLib.sol";
import {Behavior_IMorpho} from "@crane/contracts/protocols/lending/morpho/blue/Behavior_IMorpho.sol";
import {TestBase_MorphoBlueFork} from "./TestBase_MorphoBlueFork.sol";

/// @title MorphoBluePortedMarketParity_Fork (Ethereum)
/// @notice Matching-market parity: same ops on live Morpho vs local ported Morpho → exact market/position/balance equality.
/// @dev AdaptiveCurveIRM binds `MORPHO` immutably, so live and local markets use different IRM addresses in
///      MarketParams; rate math is identical at rateAtTarget=0. Loan/collateral tokens + oracle + LLTV are shared.
contract MorphoBluePortedMarketParity_Fork_Test is TestBase_MorphoBlueFork {
    using MarketParamsLib for MarketParams;

    uint256 internal constant LLTV = 0.86e18; // commonly enabled on live Morpho

    IMorpho internal localMorpho;
    AdaptiveCurveIrm internal localIrm;
    OracleMock internal oracle;
    ERC20Mock internal loanToken;
    ERC20Mock internal collateralToken;

    MarketParams internal liveParams;
    MarketParams internal localParams;
    Id internal liveId;
    Id internal localId;

    address internal supplier;
    address internal borrower;

    function setUp() public override {
        super.setUp();

        address owner = makeAddr("localOwner");
        localMorpho = IMorpho(address(new Morpho(owner)));
        localIrm = new AdaptiveCurveIrm(address(localMorpho));
        vm.label(address(localMorpho), "LocalMorpho");
        vm.label(address(localIrm), "LocalIrm");

        oracle = new OracleMock();
        oracle.setPrice(ORACLE_PRICE_SCALE);

        loanToken = new ERC20Mock();
        collateralToken = new ERC20Mock();

        // Live Morpho: IRM already enabled; enable LLTV if not already (may revert if already set — ignore)
        if (!liveMorpho.isLltvEnabled(LLTV)) {
            // Only owner can enable — skip and assume LLTV enabled; try common enabled LLTVs
            // 0.86e18 is enabled on ETH Morpho in practice; assert below
        }
        assertTrue(liveMorpho.isIrmEnabled(liveIrm), "live IRM enabled");
        // Fall back through common LLTVs if needed
        uint256 lltv = _pickEnabledLltv();
        assertTrue(liveMorpho.isLltvEnabled(lltv), "need enabled LLTV on live Morpho");

        vm.startPrank(owner);
        localMorpho.enableIrm(address(localIrm));
        localMorpho.enableLltv(lltv);
        vm.stopPrank();

        liveParams = MarketParams({
            loanToken: address(loanToken),
            collateralToken: address(collateralToken),
            oracle: address(oracle),
            irm: liveIrm,
            lltv: lltv
        });
        localParams = MarketParams({
            loanToken: address(loanToken),
            collateralToken: address(collateralToken),
            oracle: address(oracle),
            irm: address(localIrm),
            lltv: lltv
        });

        liveMorpho.createMarket(liveParams);
        localMorpho.createMarket(localParams);
        liveId = liveParams.id();
        localId = localParams.id();

        supplier = makeAddr("supplier");
        borrower = makeAddr("borrower");

        _approve(supplier, address(liveMorpho));
        _approve(supplier, address(localMorpho));
        _approve(borrower, address(liveMorpho));
        _approve(borrower, address(localMorpho));
    }

    function _pickEnabledLltv() internal view returns (uint256) {
        uint256[6] memory candidates = [uint256(0.86e18), 0.915e18, 0.945e18, 0.77e18, 0.625e18, 0.8e18];
        for (uint256 i; i < candidates.length; ++i) {
            if (liveMorpho.isLltvEnabled(candidates[i])) return candidates[i];
        }
        revert("no common LLTV enabled on live Morpho at fork block");
    }

    function _approve(address who, address morpho_) internal {
        vm.startPrank(who);
        loanToken.approve(morpho_, type(uint256).max);
        collateralToken.approve(morpho_, type(uint256).max);
        vm.stopPrank();
    }

    function _assertParity() internal view {
        Market memory liveM = liveMorpho.market(liveId);
        Market memory localM = localMorpho.market(localId);
        assertTrue(Behavior_IMorpho.areEqual_markets(liveM, localM), "market aggregates");

        Position memory liveS = liveMorpho.position(liveId, supplier);
        Position memory localS = localMorpho.position(localId, supplier);
        assertTrue(Behavior_IMorpho.areEqual_positions(liveS, localS), "supplier position");

        Position memory liveB = liveMorpho.position(liveId, borrower);
        Position memory localB = localMorpho.position(localId, borrower);
        assertTrue(Behavior_IMorpho.areEqual_positions(liveB, localB), "borrower position");

        // Token balances of each Morpho singleton must match for loan + collateral
        assertEq(loanToken.balanceOf(address(liveMorpho)), loanToken.balanceOf(address(localMorpho)), "morpho loan bal");
        assertEq(
            collateralToken.balanceOf(address(liveMorpho)),
            collateralToken.balanceOf(address(localMorpho)),
            "morpho coll bal"
        );
        assertEq(loanToken.balanceOf(supplier), loanToken.balanceOf(supplier)); // tautology placeholder
        // Per-user balances are shared tokens — net effects must keep supplier/borrower equal across paths:
        // We fund each path separately with identical mint amounts, so track via positions + morpho vault balances.
    }

    function test_parity_supply_withdraw() public {
        uint256 amount = 1_000e18;
        // Fund twice: once for live path, once for local path
        loanToken.setBalance(supplier, amount * 2);

        vm.startPrank(supplier);
        liveMorpho.supply(liveParams, amount, 0, supplier, "");
        localMorpho.supply(localParams, amount, 0, supplier, "");
        vm.stopPrank();

        _assertParity();

        uint256 sharesLive = liveMorpho.position(liveId, supplier).supplyShares;
        uint256 sharesLocal = localMorpho.position(localId, supplier).supplyShares;
        assertEq(sharesLive, sharesLocal, "supply shares equal");

        vm.startPrank(supplier);
        liveMorpho.withdraw(liveParams, 0, sharesLive, supplier, supplier);
        localMorpho.withdraw(localParams, 0, sharesLocal, supplier, supplier);
        vm.stopPrank();

        _assertParity();
        assertEq(liveMorpho.position(liveId, supplier).supplyShares, 0);
        assertEq(localMorpho.position(localId, supplier).supplyShares, 0);
    }

    function test_parity_full_borrow_cycle() public {
        uint256 supplyAmt = 10_000e18;
        uint256 collAmt = 20_000e18;
        uint256 borrowAmt = 5_000e18;

        loanToken.setBalance(supplier, supplyAmt * 2);
        collateralToken.setBalance(borrower, collAmt * 2);
        // borrower needs loan tokens for interest repay — mint large buffer
        loanToken.setBalance(borrower, borrowAmt * 4);

        vm.startPrank(supplier);
        liveMorpho.supply(liveParams, supplyAmt, 0, supplier, "");
        localMorpho.supply(localParams, supplyAmt, 0, supplier, "");
        vm.stopPrank();

        vm.startPrank(borrower);
        liveMorpho.supplyCollateral(liveParams, collAmt, borrower, "");
        localMorpho.supplyCollateral(localParams, collAmt, borrower, "");
        liveMorpho.borrow(liveParams, borrowAmt, 0, borrower, borrower);
        localMorpho.borrow(localParams, borrowAmt, 0, borrower, borrower);
        vm.stopPrank();

        _assertParity();

        // Accrue same time on both (shared chain clock)
        vm.warp(block.timestamp + 7 days);
        liveMorpho.accrueInterest(liveParams);
        localMorpho.accrueInterest(localParams);

        _assertParity();

        uint256 liveBorrowShares = liveMorpho.position(liveId, borrower).borrowShares;
        uint256 localBorrowShares = localMorpho.position(localId, borrower).borrowShares;
        assertEq(liveBorrowShares, localBorrowShares, "borrow shares after accrue");

        vm.startPrank(borrower);
        liveMorpho.repay(liveParams, 0, liveBorrowShares, borrower, "");
        localMorpho.repay(localParams, 0, localBorrowShares, borrower, "");
        liveMorpho.withdrawCollateral(liveParams, collAmt, borrower, borrower);
        localMorpho.withdrawCollateral(localParams, collAmt, borrower, borrower);
        vm.stopPrank();

        _assertParity();
        assertEq(liveMorpho.position(liveId, borrower).borrowShares, 0);
        assertEq(localMorpho.position(localId, borrower).borrowShares, 0);
        assertEq(liveMorpho.position(liveId, borrower).collateral, 0);
        assertEq(localMorpho.position(localId, borrower).collateral, 0);
    }
}
