// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.35;

import {
    IMorpho,
    Id,
    MarketParams,
    Market,
    Position
} from "@crane/contracts/external/morpho/blue/interfaces/IMorpho.sol";
import {MarketParamsLib} from "@crane/contracts/external/morpho/blue/libraries/MarketParamsLib.sol";
import {MorphoLib} from "@crane/contracts/external/morpho/blue/libraries/periphery/MorphoLib.sol";
import {MorphoBlueService} from "@crane/contracts/protocols/lending/morpho/blue/services/MorphoBlueService.sol";
import {TestBase_MorphoBlue} from
    "@crane/contracts/protocols/lending/morpho/blue/test/bases/TestBase_MorphoBlue.sol";
import {Behavior_IMorpho} from "@crane/contracts/protocols/lending/morpho/blue/Behavior_IMorpho.sol";

/// @title MorphoBlueLifecycle
/// @notice Hermetic full lifecycle with exact deltas.
/// @dev MorphoBlueService is library-style (Diamond holds tokens). User-path ops use direct Morpho calls under prank.
contract MorphoBlueLifecycle_Test is TestBase_MorphoBlue {
    using MarketParamsLib for MarketParams;
    using MorphoLib for IMorpho;

    uint256 internal constant SUPPLY_ASSETS = 1000e18;
    uint256 internal constant COLLATERAL_ASSETS = 2000e18;
    uint256 internal constant BORROW_ASSETS = 500e18;

    function test_lifecycle_supply_borrow_repay_withdraw() public {
        _fundSupplier(SUPPLY_ASSETS);
        _fundBorrowerCollateral(COLLATERAL_ASSETS);

        // Supply liquidity (user path)
        vm.prank(SUPPLIER);
        (uint256 suppliedAssets, uint256 supplyShares) =
            morpho.supply(marketParams, SUPPLY_ASSETS, 0, SUPPLIER, "");
        assertEq(suppliedAssets, SUPPLY_ASSETS, "supplied assets");
        assertGt(supplyShares, 0, "supply shares minted");

        Market memory mAfterSupply = morpho.market(marketId);
        assertEq(mAfterSupply.totalSupplyAssets, SUPPLY_ASSETS, "totalSupplyAssets");
        assertEq(mAfterSupply.totalSupplyShares, supplyShares, "totalSupplyShares");
        assertEq(mAfterSupply.totalBorrowAssets, 0);

        Position memory supplierPos = morpho.position(marketId, SUPPLIER);
        assertEq(supplierPos.supplyShares, supplyShares);

        // Collateral + borrow
        vm.prank(BORROWER);
        morpho.supplyCollateral(marketParams, COLLATERAL_ASSETS, BORROWER, "");

        uint256 borrowerLoanBefore = loanToken.balanceOf(BORROWER);
        vm.prank(BORROWER);
        (uint256 borrowedAssets, uint256 borrowShares) =
            morpho.borrow(marketParams, BORROW_ASSETS, 0, BORROWER, BORROWER);
        assertEq(borrowedAssets, BORROW_ASSETS, "borrowed assets");
        assertEq(loanToken.balanceOf(BORROWER), borrowerLoanBefore + BORROW_ASSETS, "borrower loan balance");
        assertGt(borrowShares, 0, "borrow shares");

        Position memory borrowerPos = morpho.position(marketId, BORROWER);
        assertEq(borrowerPos.collateral, COLLATERAL_ASSETS);
        assertEq(borrowerPos.borrowShares, borrowShares);

        // Accrue interest
        vm.warp(block.timestamp + 30 days);
        morpho.accrueInterest(marketParams);

        Market memory mAfterAccrue = morpho.market(marketId);
        assertGt(mAfterAccrue.totalBorrowAssets, BORROW_ASSETS, "interest accrued on borrow");
        assertGt(mAfterAccrue.totalSupplyAssets, SUPPLY_ASSETS, "interest accrued on supply");

        // Repay full debt via shares
        uint256 debtAssets = MorphoBlueService._expectedBorrowAssets(morpho, marketParams, BORROWER);
        _mintLoan(BORROWER, debtAssets + loanToken.balanceOf(BORROWER));
        vm.startPrank(BORROWER);
        loanToken.approve(address(morpho), type(uint256).max);
        (uint256 repaidAssets, uint256 repaidShares) =
            morpho.repay(marketParams, 0, borrowerPos.borrowShares, BORROWER, "");
        vm.stopPrank();

        assertEq(repaidShares, borrowerPos.borrowShares, "full borrow shares repaid");
        assertApproxEqAbs(repaidAssets, debtAssets, 1, "repay assets ~ expected debt");

        borrowerPos = morpho.position(marketId, BORROWER);
        assertEq(borrowerPos.borrowShares, 0, "no borrow left");

        // Withdraw collateral
        vm.prank(BORROWER);
        morpho.withdrawCollateral(marketParams, COLLATERAL_ASSETS, BORROWER, BORROWER);
        assertEq(morpho.position(marketId, BORROWER).collateral, 0);
        assertEq(collateralToken.balanceOf(BORROWER), COLLATERAL_ASSETS);

        // Withdraw supply
        uint256 supplierShares = morpho.position(marketId, SUPPLIER).supplyShares;
        uint256 supplierLoanBefore = loanToken.balanceOf(SUPPLIER);
        vm.prank(SUPPLIER);
        (uint256 withdrawnAssets, uint256 burnedShares) =
            morpho.withdraw(marketParams, 0, supplierShares, SUPPLIER, SUPPLIER);
        assertEq(burnedShares, supplierShares);
        assertGt(withdrawnAssets, SUPPLY_ASSETS, "supplier earns interest");
        assertEq(loanToken.balanceOf(SUPPLIER), supplierLoanBefore + withdrawnAssets);
        assertEq(morpho.position(marketId, SUPPLIER).supplyShares, 0);
    }

    function test_idToMarketParams_roundtrip() public view {
        MarketParams memory stored = morpho.idToMarketParams(marketId);
        assertTrue(Behavior_IMorpho.isValid_IMorpho_idToMarketParams(morpho, marketId, marketParams, stored));
        assertEq(Id.unwrap(marketParams.id()), Id.unwrap(marketId));
    }

    function test_service_supply_exact_delta_diamond_style() public {
        // Service runs in this contract's context (simulates Diamond holding inventory).
        uint256 amount = 123e18;
        _mintLoan(address(this), amount);
        loanToken.approve(address(morpho), type(uint256).max);

        uint256 morphoBefore = loanToken.balanceOf(address(morpho));
        uint256 selfBefore = loanToken.balanceOf(address(this));

        (uint256 assets, uint256 shares) =
            MorphoBlueService._supply(morpho, marketParams, amount, address(this));

        assertEq(assets, amount);
        assertEq(loanToken.balanceOf(address(morpho)), morphoBefore + amount);
        assertEq(loanToken.balanceOf(address(this)), selfBefore - amount);
        assertEq(morpho.position(marketId, address(this)).supplyShares, shares);
    }
}
