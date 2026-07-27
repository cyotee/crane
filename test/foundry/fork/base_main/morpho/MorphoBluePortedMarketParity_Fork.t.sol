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

/// @title MorphoBluePortedMarketParity_Fork (Base)
/// @notice Matching-market parity on Base mainnet fork (same design as Ethereum parity suite).
contract MorphoBluePortedMarketParity_Fork_Test is TestBase_MorphoBlueFork {
    using MarketParamsLib for MarketParams;

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

        oracle = new OracleMock();
        oracle.setPrice(ORACLE_PRICE_SCALE);
        loanToken = new ERC20Mock();
        collateralToken = new ERC20Mock();

        assertTrue(liveMorpho.isIrmEnabled(liveIrm), "live IRM enabled");
        uint256 lltv = _pickEnabledLltv();

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
        assertTrue(
            Behavior_IMorpho.areEqual_markets(liveMorpho.market(liveId), localMorpho.market(localId)), "markets"
        );
        assertTrue(
            Behavior_IMorpho.areEqual_positions(
                liveMorpho.position(liveId, supplier), localMorpho.position(localId, supplier)
            ),
            "supplier"
        );
        assertTrue(
            Behavior_IMorpho.areEqual_positions(
                liveMorpho.position(liveId, borrower), localMorpho.position(localId, borrower)
            ),
            "borrower"
        );
        assertEq(loanToken.balanceOf(address(liveMorpho)), loanToken.balanceOf(address(localMorpho)));
        assertEq(collateralToken.balanceOf(address(liveMorpho)), collateralToken.balanceOf(address(localMorpho)));
    }

    function test_parity_supply_withdraw() public {
        uint256 amount = 1_000e18;
        loanToken.setBalance(supplier, amount * 2);

        vm.startPrank(supplier);
        liveMorpho.supply(liveParams, amount, 0, supplier, "");
        localMorpho.supply(localParams, amount, 0, supplier, "");
        vm.stopPrank();
        _assertParity();

        uint256 sharesLive = liveMorpho.position(liveId, supplier).supplyShares;
        uint256 sharesLocal = localMorpho.position(localId, supplier).supplyShares;
        assertEq(sharesLive, sharesLocal);

        vm.startPrank(supplier);
        liveMorpho.withdraw(liveParams, 0, sharesLive, supplier, supplier);
        localMorpho.withdraw(localParams, 0, sharesLocal, supplier, supplier);
        vm.stopPrank();
        _assertParity();
    }

    function test_parity_full_borrow_cycle() public {
        uint256 supplyAmt = 10_000e18;
        uint256 collAmt = 20_000e18;
        uint256 borrowAmt = 5_000e18;

        loanToken.setBalance(supplier, supplyAmt * 2);
        collateralToken.setBalance(borrower, collAmt * 2);
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

        vm.warp(block.timestamp + 7 days);
        liveMorpho.accrueInterest(liveParams);
        localMorpho.accrueInterest(localParams);
        _assertParity();

        uint256 liveBorrowShares = liveMorpho.position(liveId, borrower).borrowShares;
        uint256 localBorrowShares = localMorpho.position(localId, borrower).borrowShares;
        assertEq(liveBorrowShares, localBorrowShares);

        vm.startPrank(borrower);
        liveMorpho.repay(liveParams, 0, liveBorrowShares, borrower, "");
        localMorpho.repay(localParams, 0, localBorrowShares, borrower, "");
        liveMorpho.withdrawCollateral(liveParams, collAmt, borrower, borrower);
        localMorpho.withdrawCollateral(localParams, collAmt, borrower, borrower);
        vm.stopPrank();
        _assertParity();
    }
}
