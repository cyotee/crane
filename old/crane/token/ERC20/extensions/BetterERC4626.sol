// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

// import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
// import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    CRANE                                   */
/* -------------------------------------------------------------------------- */

import {BetterMath} from "contracts/crane/utils/math/BetterMath.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {BetterERC20 as ERC20} from "contracts/crane/token/ERC20/BetterERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "contracts/crane/token/ERC20/utils/BetterSafeERC20.sol";
import {BetterIERC4626} from "contracts/crane/interfaces/BetterIERC4626.sol";
// import {ERC4626Storage} from "contracts/crane/token/ERC20/extensions/utils/ERC4626Storage.sol";
import {ERC4626Target} from "contracts/crane/token/ERC20/extensions/ERC4626Target.sol";

// tag::BetterERC4626[]e
/**
 * @title BetterERC4626 - A better implementation of ERC426.
 * @author cyotee doge <doge.cyotee>
 * @dev Exptects to be composed into proxies or other contracts.
 * @dev Initializes ERC20Storage with expected metadata.
 * @dev Uses ERC20Storage for state changes.
 * @dev Is compatible with any contreact that exposes ERC20Storage state.
 */
contract BetterERC4626 is ERC4626Target, ERC20, BetterIERC4626 {
    using BetterMath for uint256;
    using SafeERC20 for IERC20;

    /**
     * @dev Constructor that initializes the ERC4626 vault
     * @param asset_ The address of the underlying asset
     * @param name_ The name of the vault token
     * @param symbol_ The symbol of the vault token
     * @param decimalsOffset_ The decimals offset for the vault
     */
    constructor(address asset_, string memory name_, string memory symbol_, uint8 decimalsOffset_) {
        _initERC4626(name_, symbol_, IERC20(asset_), decimalsOffset_);
    }

    function asset() public view virtual override(ERC4626Target, IERC4626) returns (address) {
        return super.asset();
    }

    function totalAssets() public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.totalAssets();
    }

    function convertToShares(uint256 assets) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.convertToShares(assets);
    }

    function convertToAssets(uint256 shares) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.convertToAssets(shares);
    }

    function maxDeposit(address) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.maxDeposit(address(0));
    }

    function maxMint(address) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.maxMint(address(0));
    }

    function maxWithdraw(address owner) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.maxWithdraw(owner);
    }

    function maxRedeem(address owner) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.maxRedeem(owner);
    }

    function previewDeposit(uint256 assets) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.previewDeposit(assets);
    }

    function previewMint(uint256 shares) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.previewMint(shares);
    }

    function previewWithdraw(uint256 assets) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.previewWithdraw(assets);
    }

    function previewRedeem(uint256 shares) public view virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.previewRedeem(shares);
    }

    function deposit(uint256 assets, address receiver)
        public
        virtual
        override(ERC4626Target, IERC4626)
        returns (uint256)
    {
        return super.deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) public virtual override(ERC4626Target, IERC4626) returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(uint256 assets, address receiver, address owner)
        public
        virtual
        override(ERC4626Target, IERC4626)
        returns (uint256)
    {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner)
        public
        virtual
        override(ERC4626Target, IERC4626)
        returns (uint256)
    {
        return super.redeem(shares, receiver, owner);
    }
}
// end::BetterERC4626[]
