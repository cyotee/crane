// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

/**
 * @title ERC4626TargetStubHandler
 * @notice Handler for invariant testing of ERC4626 vault implementations
 * @dev Exposes deposit, mint, withdraw, redeem operations for fuzzing
 */
contract ERC4626TargetStubHandler is Test {
    using BetterEfficientHashLib for bytes;

    IERC4626 public vault;
    IERC20 public vaultAsERC20; // For balanceOf/totalSupply
    IERC20 public asset;

    address[] internal _actors;
    mapping(address => bool) internal _seenActor;

    // Track total deposited assets for invariant checking
    uint256 public ghostTotalDeposited;
    uint256 public ghostTotalWithdrawn;

    // Track shares per actor
    mapping(address => uint256) internal _expectedShares;

    constructor() {}

    function attachVault(IERC4626 vault_) external {
        vault = vault_;
        vaultAsERC20 = IERC20(address(vault_));
        asset = IERC20(vault_.asset());
        _pushActor(address(this));
    }

    // Normalize arbitrary uint input into small set of addresses
    function actorFromSeed(uint256 seed) public pure returns (address) {
        uint160 v = uint160((seed % 8) + 1);
        return address(v);
    }

    function _pushActor(address a) internal {
        if (!_seenActor[a]) {
            _seenActor[a] = true;
            _actors.push(a);
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                           Deposit Operations                           */
    /* ---------------------------------------------------------------------- */

    function deposit(uint256 actorSeed, uint256 assets) external {
        address actor = actorFromSeed(actorSeed);
        _pushActor(actor);

        // Bound assets to reasonable range
        uint256 maxAssets = asset.balanceOf(address(this));
        if (maxAssets == 0) return;
        assets = bound(assets, 1, maxAssets);

        // Transfer assets to actor first
        asset.transfer(actor, assets);

        // Actor approves vault
        vm.startPrank(actor);
        asset.approve(address(vault), assets);

        uint256 sharesBefore = vaultAsERC20.balanceOf(actor);
        uint256 shares = vault.deposit(assets, actor);
        uint256 sharesAfter = vaultAsERC20.balanceOf(actor);
        vm.stopPrank();

        // Verify shares received
        assertEq(sharesAfter - sharesBefore, shares, "Shares mismatch after deposit");

        ghostTotalDeposited += assets;
        _expectedShares[actor] += shares;
    }

    function mint(uint256 actorSeed, uint256 shares) external {
        address actor = actorFromSeed(actorSeed);
        _pushActor(actor);

        // Get max mintable shares based on available assets
        uint256 maxAssets = asset.balanceOf(address(this));
        if (maxAssets == 0) return;

        // Preview how many assets needed for these shares
        uint256 assetsNeeded = vault.previewMint(shares);
        if (assetsNeeded == 0 || assetsNeeded > maxAssets) {
            shares = vault.previewDeposit(maxAssets);
            if (shares == 0) return;
            assetsNeeded = vault.previewMint(shares);
        }
        if (assetsNeeded > maxAssets) return;

        // Transfer assets to actor
        asset.transfer(actor, assetsNeeded);

        vm.startPrank(actor);
        asset.approve(address(vault), assetsNeeded);

        uint256 sharesBefore = vaultAsERC20.balanceOf(actor);
        uint256 assetsUsed = vault.mint(shares, actor);
        uint256 sharesAfter = vaultAsERC20.balanceOf(actor);
        vm.stopPrank();

        assertEq(sharesAfter - sharesBefore, shares, "Shares mismatch after mint");

        ghostTotalDeposited += assetsUsed;
        _expectedShares[actor] += shares;
    }

    /* ---------------------------------------------------------------------- */
    /*                          Withdraw Operations                           */
    /* ---------------------------------------------------------------------- */

    function withdraw(uint256 actorSeed, uint256 assets) external {
        address actor = actorFromSeed(actorSeed);
        _pushActor(actor);

        uint256 maxWithdraw = vault.maxWithdraw(actor);
        if (maxWithdraw == 0) return;

        assets = bound(assets, 1, maxWithdraw);

        vm.startPrank(actor);
        uint256 sharesBefore = vaultAsERC20.balanceOf(actor);
        uint256 assetsBefore = asset.balanceOf(actor);

        uint256 sharesBurned = vault.withdraw(assets, actor, actor);

        uint256 sharesAfter = vaultAsERC20.balanceOf(actor);
        uint256 assetsAfter = asset.balanceOf(actor);
        vm.stopPrank();

        assertEq(sharesBefore - sharesAfter, sharesBurned, "Shares burned mismatch");
        assertEq(assetsAfter - assetsBefore, assets, "Assets received mismatch");

        ghostTotalWithdrawn += assets;
        if (_expectedShares[actor] >= sharesBurned) {
            _expectedShares[actor] -= sharesBurned;
        } else {
            _expectedShares[actor] = 0;
        }
    }

    function redeem(uint256 actorSeed, uint256 shares) external {
        address actor = actorFromSeed(actorSeed);
        _pushActor(actor);

        uint256 maxRedeem = vault.maxRedeem(actor);
        if (maxRedeem == 0) return;

        shares = bound(shares, 1, maxRedeem);

        vm.startPrank(actor);
        uint256 sharesBefore = vaultAsERC20.balanceOf(actor);
        uint256 assetsBefore = asset.balanceOf(actor);

        uint256 assetsReceived = vault.redeem(shares, actor, actor);

        uint256 sharesAfter = vaultAsERC20.balanceOf(actor);
        uint256 assetsAfter = asset.balanceOf(actor);
        vm.stopPrank();

        assertEq(sharesBefore - sharesAfter, shares, "Shares redeemed mismatch");
        assertEq(assetsAfter - assetsBefore, assetsReceived, "Assets received mismatch");

        ghostTotalWithdrawn += assetsReceived;
        if (_expectedShares[actor] >= shares) {
            _expectedShares[actor] -= shares;
        } else {
            _expectedShares[actor] = 0;
        }
    }

    /* ---------------------------------------------------------------------- */
    /*                           View Helpers                                  */
    /* ---------------------------------------------------------------------- */

    function actors() external view returns (address[] memory) {
        return _actors;
    }

    function actorCount() external view returns (uint256) {
        return _actors.length;
    }

    function actorAt(uint256 idx) external view returns (address) {
        return _actors[idx];
    }

    function expectedShares(address actor) external view returns (uint256) {
        return _expectedShares[actor];
    }

    function totalAssets() external view returns (uint256) {
        return vault.totalAssets();
    }

    function totalSupply() external view returns (uint256) {
        return vaultAsERC20.totalSupply();
    }

    function balanceOf(address actor) external view returns (uint256) {
        return vaultAsERC20.balanceOf(actor);
    }

    function assetBalanceOf(address actor) external view returns (uint256) {
        return asset.balanceOf(actor);
    }
}
