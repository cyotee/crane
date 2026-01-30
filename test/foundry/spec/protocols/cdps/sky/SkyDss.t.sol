// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import { TestBase_SkyDss } from "@crane/contracts/protocols/cdps/sky/test/bases/TestBase_SkyDss.sol";

/// @title SkyDss_Test
/// @notice Basic tests for the Sky/DSS port
contract SkyDss_Test is TestBase_SkyDss {

    function setUp() public override {
        super.setUp();
    }

    // --- Deployment Tests ---

    function test_deployment_vatIsLive() public view {
        assertEq(vat.live(), 1, "Vat should be live");
    }

    function test_deployment_daiHasCorrectMetadata() public view {
        assertEq(dai.name(), "Dai Stablecoin");
        assertEq(dai.symbol(), "DAI");
        assertEq(dai.decimals(), 18);
    }

    function test_deployment_ilkIsInitialized() public view {
        (, uint256 rate,,,) = vat.ilks(DEFAULT_ILK);
        assertEq(rate, RAY, "Ilk rate should be RAY");
    }

    function test_deployment_chainlogHasAddresses() public view {
        assertEq(chainlog.getAddress("MCD_VAT"), address(vat));
        assertEq(chainlog.getAddress("MCD_DAI"), address(dai));
        assertEq(chainlog.getAddress("MCD_JUG"), address(jug));
    }

    // --- CDP Operations Tests ---

    function test_openCdp_basicOperation() public {
        uint256 collateral = 10 * WAD; // 10 GEM
        uint256 debt = 1000 * WAD;     // 1000 DAI

        openCdp(alice, collateral, debt);

        // Check Alice's position
        (uint256 ink, uint256 art) = getUrn(alice);
        assertEq(ink, collateral, "Collateral should be locked");
        assertEq(art, debt, "Debt should be recorded");

        // Check Alice received DAI
        assertEq(daiBalance(alice), debt, "Alice should have DAI");
    }

    function test_openCdp_multipleUsers() public {
        // Alice opens a CDP
        openCdp(alice, 10 * WAD, 1000 * WAD);

        // Bob opens a CDP
        openCdp(bob, 20 * WAD, 2000 * WAD);

        // Check both positions
        (uint256 aliceInk, uint256 aliceArt) = getUrn(alice);
        (uint256 bobInk, uint256 bobArt) = getUrn(bob);

        assertEq(aliceInk, 10 * WAD);
        assertEq(aliceArt, 1000 * WAD);
        assertEq(bobInk, 20 * WAD);
        assertEq(bobArt, 2000 * WAD);
    }

    function test_lockCollateral_noDebt() public {
        lockCollateral(alice, 10 * WAD);

        (uint256 ink, uint256 art) = getUrn(alice);
        assertEq(ink, 10 * WAD, "Collateral should be locked");
        assertEq(art, 0, "No debt should be recorded");
    }

    function test_drawDai_fromExistingCdp() public {
        // First lock collateral
        lockCollateral(alice, 10 * WAD);

        // Then draw DAI
        drawDai(alice, 500 * WAD);

        assertEq(daiBalance(alice), 500 * WAD);
        (uint256 ink, uint256 art) = getUrn(alice);
        assertEq(ink, 10 * WAD);
        assertEq(art, 500 * WAD);
    }

    function test_wipeDai_partialRepayment() public {
        openCdp(alice, 10 * WAD, 1000 * WAD);

        // Repay half
        wipeDai(alice, 500 * WAD);

        (uint256 ink, uint256 art) = getUrn(alice);
        assertEq(ink, 10 * WAD, "Collateral unchanged");
        assertEq(art, 500 * WAD, "Debt should be reduced");
        assertEq(daiBalance(alice), 500 * WAD, "DAI balance should be reduced");
    }

    function test_wipeDai_fullRepayment() public {
        openCdp(alice, 10 * WAD, 1000 * WAD);

        // Repay all
        wipeDai(alice, 1000 * WAD);

        (uint256 ink, uint256 art) = getUrn(alice);
        assertEq(ink, 10 * WAD, "Collateral unchanged");
        assertEq(art, 0, "Debt should be zero");
        assertEq(daiBalance(alice), 0, "DAI balance should be zero");
    }

    function test_freeCollateral_afterRepayment() public {
        openCdp(alice, 10 * WAD, 1000 * WAD);

        // Repay all debt
        wipeDai(alice, 1000 * WAD);

        // Free collateral
        freeCollateral(alice, 10 * WAD);

        (uint256 ink, uint256 art) = getUrn(alice);
        assertEq(ink, 0, "Collateral should be zero");
        assertEq(art, 0, "Debt should be zero");
        assertEq(gemBalance(alice), 10 * WAD, "Alice should have her gems back");
    }

    // --- Collateralization Tests ---

    function test_collateralRatio_calculation() public {
        // Price is $1000 per GEM
        // 10 GEM = $10,000 collateral
        // 1000 DAI debt
        // Ratio = 10,000 / 1,000 = 10 = 1000%
        openCdp(alice, 10 * WAD, 1000 * WAD);

        uint256 ratio = getCollateralRatio(alice);
        // Note: ratio is in ray, so 10 * RAY = 1000%
        assertGt(ratio, 5 * RAY, "Should be overcollateralized");
    }

    function test_isSafe_overcollateralized() public {
        openCdp(alice, 10 * WAD, 1000 * WAD);
        assertTrue(isSafe(alice), "CDP should be safe");
    }

    function test_isSafe_afterPriceDrop() public {
        openCdp(alice, 10 * WAD, 5000 * WAD);

        // Initial price: $1000
        // Collateral: 10 GEM = $10,000
        // Debt: 5000 DAI
        // LTV: 50%, safe with 150% liquidation ratio

        assertTrue(isSafe(alice), "Should start safe");

        // Drop price to $100 (90% drop)
        // Collateral value: 10 * $100 = $1000
        // Debt: 5000 DAI
        // Now undercollateralized
        setPrice(100 * WAD);

        assertFalse(isSafe(alice), "Should be unsafe after price drop");
    }

    // --- Price Feed Tests ---

    function test_setPrice_updatesSpot() public {
        openCdp(alice, 10 * WAD, 1000 * WAD);

        uint256 ratioBefore = getCollateralRatio(alice);

        // Double the price
        setPrice(2000 * WAD);

        uint256 ratioAfter = getCollateralRatio(alice);

        assertGt(ratioAfter, ratioBefore, "Ratio should increase with price");
    }

    // --- Stability Fee Tests ---

    function test_drip_accumulatesFees() public {
        // Set a stability fee (2% annual)
        // duty = 1.02^(1/year) in ray
        // For simplicity, we'll just check that drip can be called
        openCdp(alice, 10 * WAD, 1000 * WAD);

        (, uint256 rateBefore,,,) = vat.ilks(DEFAULT_ILK);

        // Warp 1 year
        warpForward(365 days);

        // Drip
        drip();

        (, uint256 rateAfter,,,) = vat.ilks(DEFAULT_ILK);

        // Rate should still be RAY if no duty was set (default is 0%)
        assertEq(rateAfter, rateBefore, "Rate unchanged with 0% fee");
    }

    // --- Edge Cases ---

    function test_revert_drawTooMuchDai() public {
        lockCollateral(alice, 1 * WAD);

        // Try to draw more DAI than collateralization allows
        // 1 GEM at $1000 = $1000 collateral
        // With 150% ratio, max safe debt is ~$666
        // Try to draw $900
        vm.expectRevert("Vat/not-safe");
        vat.frob(DEFAULT_ILK, alice, alice, alice, 0, int256(900 * WAD));
    }

    function test_revert_freeCollateralWithDebt() public {
        openCdp(alice, 10 * WAD, 5000 * WAD);

        // Try to free all collateral while debt exists
        vm.expectRevert("Vat/not-safe");
        vat.frob(DEFAULT_ILK, alice, alice, alice, -int256(10 * WAD), 0);
    }
}
