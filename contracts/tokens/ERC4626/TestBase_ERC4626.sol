// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {ERC4626TargetStubHandler} from "@crane/contracts/tokens/ERC4626/ERC4626TargetStubHandler.sol";

/**
 * @title TestBase_ERC4626
 * @notice Base test contract for ERC4626 invariant testing
 * @dev Follows the same pattern as TestBase_ERC20 for consistency
 */
abstract contract TestBase_ERC4626 is Test {
    ERC4626TargetStubHandler public handler;
    IERC4626 public vaultSubject;
    IERC20 public vaultAsERC20; // For balanceOf/totalSupply
    IERC20 public assetSubject;

    // Override in derived tests to deploy the vault
    function _deployVault(ERC4626TargetStubHandler handler_) internal virtual returns (IERC4626 vault_);

    function _deployHandler() internal virtual returns (ERC4626TargetStubHandler handler_) {
        handler_ = new ERC4626TargetStubHandler();
    }

    function _registerVault(ERC4626TargetStubHandler handler_, IERC4626 vault_) internal virtual {
        handler_.attachVault(vault_);
    }

    function setUp() public virtual {
        handler = _deployHandler();
        vaultSubject = _deployVault(handler);
        vaultAsERC20 = IERC20(address(vaultSubject));
        assetSubject = IERC20(vaultSubject.asset());
        _registerVault(handler, vaultSubject);

        // Register handler as the fuzz target
        targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = handler.deposit.selector;
        selectors[1] = handler.mint.selector;
        selectors[2] = handler.withdraw.selector;
        selectors[3] = handler.redeem.selector;

        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    /* ---------------------------------------------------------------------- */
    /*                              Invariants                                 */
    /* ---------------------------------------------------------------------- */

    /**
     * @notice totalAssets should never exceed sum of deposits minus withdrawals
     * @dev Accounts for rounding by allowing totalAssets to be slightly less
     */
    function invariant_totalAssets_bounded() public view {
        uint256 deposited = handler.ghostTotalDeposited();
        uint256 withdrawn = handler.ghostTotalWithdrawn();
        uint256 totalAssets_ = handler.totalAssets();

        // totalAssets should be <= (deposited - withdrawn) due to rounding down
        if (deposited >= withdrawn) {
            assertLe(totalAssets_, deposited - withdrawn + 1, "totalAssets exceeds net deposits");
        }
    }

    /**
     * @notice totalSupply should be non-negative (always true for uint, but explicit)
     */
    function invariant_totalSupply_nonNegative() public view {
        uint256 totalSupply_ = handler.totalSupply();
        assertGe(totalSupply_, 0, "totalSupply should be non-negative");
    }

    /**
     * @notice Sum of all actor share balances should equal totalSupply
     */
    function invariant_sumShares_equals_totalSupply() public view {
        uint256 actorCount = handler.actorCount();
        uint256 sumShares = 0;
        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.actorAt(i);
            sumShares += handler.balanceOf(actor);
        }
        // Include vault's own balance (for pre-transfer scenarios)
        sumShares += vaultAsERC20.balanceOf(address(vaultSubject));

        uint256 totalSupply_ = handler.totalSupply();
        assertEq(sumShares, totalSupply_, "Sum of shares should equal totalSupply");
    }

    /**
     * @notice convertToShares should round down (no free shares)
     * @dev With decimal offset, shares = assets * (totalSupply + offset) / (totalAssets + 1)
     *      This means for small assets, shares can be > assets due to decimal scaling
     */
    function invariant_convertToShares_roundsDown() public view {
        uint256 totalAssets_ = handler.totalAssets();
        uint256 totalSupply_ = handler.totalSupply();

        if (totalSupply_ == 0 || totalAssets_ == 0) return;

        // Test that converting shares back to assets doesn't exceed original
        // This is the real invariant: you shouldn't get free value
        uint256 testAmount = 1000e18;
        if (testAmount > totalAssets_) testAmount = totalAssets_;

        uint256 shares = vaultSubject.convertToShares(testAmount);
        uint256 assetsBack = vaultSubject.convertToAssets(shares);

        // Converting to shares and back should not create value
        assertLe(assetsBack, testAmount, "convertToShares should round down");
    }

    /**
     * @notice convertToAssets should round down (no free assets)
     * @dev With decimal offset, conversion math ensures no free value creation
     */
    function invariant_convertToAssets_roundsDown() public view {
        uint256 totalAssets_ = handler.totalAssets();
        uint256 totalSupply_ = handler.totalSupply();

        if (totalSupply_ == 0 || totalAssets_ == 0) return;

        // Test that converting assets to shares and back doesn't exceed original
        // This is the real invariant: you shouldn't get free value
        uint256 testShares = 1000e21; // Using high decimals for vault shares
        if (testShares > totalSupply_) testShares = totalSupply_;

        uint256 assets = vaultSubject.convertToAssets(testShares);
        uint256 sharesBack = vaultSubject.convertToShares(assets);

        // Converting to assets and back should not create shares
        assertLe(sharesBack, testShares, "convertToAssets should round down");
    }

    /**
     * @notice maxWithdraw should never exceed totalAssets
     */
    function invariant_maxWithdraw_bounded() public view {
        uint256 actorCount = handler.actorCount();
        uint256 totalAssets_ = handler.totalAssets();

        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.actorAt(i);
            uint256 maxWithdraw_ = vaultSubject.maxWithdraw(actor);
            assertLe(maxWithdraw_, totalAssets_, "maxWithdraw exceeds totalAssets");
        }
    }

    /**
     * @notice maxRedeem should never exceed totalSupply
     */
    function invariant_maxRedeem_bounded() public view {
        uint256 actorCount = handler.actorCount();
        uint256 totalSupply_ = handler.totalSupply();

        for (uint256 i = 0; i < actorCount; i++) {
            address actor = handler.actorAt(i);
            uint256 maxRedeem_ = vaultSubject.maxRedeem(actor);
            assertLe(maxRedeem_, totalSupply_, "maxRedeem exceeds totalSupply");
        }
    }

    /**
     * @notice Vault asset balance should match totalAssets
     */
    function invariant_vaultBalance_equals_totalAssets() public view {
        uint256 vaultBalance = assetSubject.balanceOf(address(vaultSubject));
        uint256 totalAssets_ = handler.totalAssets();
        assertEq(vaultBalance, totalAssets_, "Vault balance should equal totalAssets");
    }
}
