// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC4626} from "@crane/contracts/interfaces/IERC4626.sol";
import {IERC4626Events} from "@crane/contracts/interfaces/IERC4626Events.sol";
// import {IERC20Errors} from "@crane/contracts/interfaces/IERC20Errors.sol";
import {ERC4626Repo} from "@crane/contracts/tokens/ERC4626/ERC4626Repo.sol";
import {ERC4626Service} from "@crane/contracts/tokens/ERC4626/ERC4626Service.sol";
import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {BetterMath} from "@crane/contracts/utils/math/BetterMath.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {ReentrancyLockModifiers} from "@crane/contracts/access/reentrancy/ReentrancyLockModifiers.sol";

contract ERC4626Target is ReentrancyLockModifiers, IERC4626Events {
    using BetterMath for uint256;
    using BetterSafeERC20 for IERC20;
    using ERC4626Repo for ERC4626Repo.Storage;

    function deposit(uint256 assets, address receiver) public virtual lock returns (uint256 shares) {
        ERC4626Repo.Storage storage erc4626 = ERC4626Repo._layout();
        uint256 lastTotalAssets = ERC4626Repo._lastTotalAssets(erc4626);
        uint256 actualIn = ERC4626Service._secureReserveDeposit(erc4626, lastTotalAssets, assets);
        ERC20Repo.Storage storage erc20 = ERC20Repo._layout();
        uint256 totalSupply_ = ERC20Repo._totalSupply(erc20);
        shares = BetterMath._convertToSharesDown(
            actualIn, lastTotalAssets, totalSupply_, ERC4626Repo._decimalOffset(erc4626)
        );
        ERC20Repo._mint(erc20, receiver, shares);
        emit Deposit(msg.sender, receiver, actualIn, shares);
        return shares;
    }

    function mint(uint256 shares, address receiver) public virtual lock returns (uint256 assets) {
        ERC4626Repo.Storage storage erc4626 = ERC4626Repo._layout();
        uint256 lastTotalAssets = ERC4626Repo._lastTotalAssets(erc4626);
        ERC20Repo.Storage storage erc20 = ERC20Repo._layout();
        uint256 totalSupply_ = ERC20Repo._totalSupply(erc20);
        assets =
            BetterMath._convertToAssetsUp(shares, lastTotalAssets, totalSupply_, ERC4626Repo._decimalOffset(erc4626));
        assets = ERC4626Service._secureReserveDeposit(erc4626, lastTotalAssets, assets);
        ERC20Repo._mint(erc20, receiver, shares);
        emit Deposit(msg.sender, receiver, assets, shares);
        return assets;
    }

    function withdraw(uint256 assets, address receiver, address owner) public virtual lock returns (uint256 shares) {
        ERC4626Repo.Storage storage erc4626 = ERC4626Repo._layout();
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets(erc4626);
        ERC20Repo.Storage storage erc20 = ERC20Repo._layout();
        uint256 totalSupply_ = ERC20Repo._totalSupply(erc20);
        shares = BetterMath._convertToSharesDown(assets, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset());
        if (msg.sender == owner || owner == address(this)) {
            ERC20Repo._burn(erc20, owner, shares);
        } else {
            ERC20Repo._spendAllowance(erc20, owner, msg.sender, shares);
            ERC20Repo._burn(erc20, owner, shares);
        }
        IERC20 assetToken = ERC4626Repo._reserveAsset(erc4626);
        assetToken.safeTransfer(receiver, assets);
        uint256 currentBalance = assetToken.balanceOf(address(this));
        ERC4626Repo._setLastTotalAssets(erc4626, currentBalance);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return shares;
    }

    function redeem(uint256 shares, address receiver, address owner) public virtual lock returns (uint256 assets) {
        ERC4626Repo.Storage storage erc4626 = ERC4626Repo._layout();
        ERC20Repo.Storage storage erc20 = ERC20Repo._layout();
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets(erc4626);
        uint256 totalSupply_ = ERC20Repo._totalSupply(erc20);
        // compute assets using pre-burn totalSupply to match previewRedeem
        assets = BetterMath._convertToAssetsDown(shares, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset());

        if (msg.sender == owner || owner == address(this)) {
            ERC20Repo._burn(erc20, owner, shares);
        } else {
            ERC20Repo._spendAllowance(erc20, owner, msg.sender, shares);
            ERC20Repo._burn(erc20, owner, shares);
        }

        IERC20 assetToken = ERC4626Repo._reserveAsset(erc4626);
        assetToken.safeTransfer(receiver, assets);
        uint256 currentBalance = assetToken.balanceOf(address(this));
        ERC4626Repo._setLastTotalAssets(erc4626, currentBalance);
        emit Withdraw(msg.sender, receiver, owner, assets, shares);
        return assets;
    }

    function asset() public view virtual returns (address) {
        return address(ERC4626Repo._reserveAsset());
    }

    function totalAssets() public view virtual returns (uint256) {
        return ERC4626Repo._lastTotalAssets();
    }

    function convertToShares(uint256 assets) public view returns (uint256 shares) {
        ERC4626Repo.Storage storage Storage = ERC4626Repo._layout();
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets(Storage);
        uint256 totalSupply_ = ERC20Repo._totalSupply();
        return
            BetterMath._convertToSharesDown(
                assets, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset(Storage)
            );
    }

    function convertToAssets(uint256 shares) public view returns (uint256 assets) {
        ERC4626Repo.Storage storage Storage = ERC4626Repo._layout();
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets(Storage);
        uint256 totalSupply_ = ERC20Repo._totalSupply();
        return
            BetterMath._convertToAssetsDown(
                shares, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset(Storage)
            );
    }

    function maxDeposit(address) public pure returns (uint256 maxDeposit_) {
        return type(uint256).max;
    }

    function maxMint(address) public pure returns (uint256 maxMint_) {
        return type(uint256).max;
    }

    function maxWithdraw(address account) public view returns (uint256 maxWithdraw_) {
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets();
        uint256 totalSupply_ = ERC20Repo._totalSupply();
        uint256 accountBalance_ = ERC20Repo._balanceOf(account);
        return
            BetterMath._convertToAssetsDown(accountBalance_, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset());
    }

    function maxRedeem(address account) public view returns (uint256 maxRedeem_) {
        return ERC20Repo._balanceOf(account);
    }

    function previewDeposit(uint256 assets) public view returns (uint256 shares) {
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets();
        uint256 totalSupply_ = ERC20Repo._totalSupply();
        return BetterMath._convertToSharesDown(assets, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset());
    }

    function previewMint(uint256 shares) public view returns (uint256 assets) {
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets();
        uint256 totalSupply_ = ERC20Repo._totalSupply();
        return BetterMath._convertToAssetsUp(shares, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset());
    }

    function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets();
        uint256 totalSupply_ = ERC20Repo._totalSupply();
        return BetterMath._convertToSharesUp(assets, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset());
    }

    function previewRedeem(uint256 shares) public view returns (uint256 assets) {
        uint256 totalAssets_ = ERC4626Repo._lastTotalAssets();
        uint256 totalSupply_ = ERC20Repo._totalSupply();
        return BetterMath._convertToAssetsDown(shares, totalAssets_, totalSupply_, ERC4626Repo._decimalOffset());
    }
}
