// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterMath} from "contracts/crane/utils/math/BetterMath.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "contracts/crane/token/ERC20/utils/BetterSafeERC20.sol";

import {ERC20Storage} from "contracts/crane/token/ERC20/utils/ERC20Storage.sol";

import {ERC4626Layout, ERC4626Repo} from "contracts/crane/token/ERC20/extensions/utils/ERC4626Repo.sol";

/// forge-lint: disable-next-line(pascal-case-struct)
interface IERC4626Storage {
    struct ERC4626StorageInit {
        IERC20 asset;
        uint8 decimalsOffset;
    }
}

// tag::ERC4626Storage[]
contract ERC4626Storage is IERC4626Storage, ERC20Storage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using ERC4626Repo for bytes32;

    using BetterMath for uint256;
    using SafeERC20 for IERC20;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(ERC4626Repo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE =
    // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
    // https://eips.ethereum.org/EIPS/eip-20
    type(IERC4626).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_erc4626()[]
    /**
     * @dev internal hook for the default storage range used by this library.
     * @dev Other services will use their default storage range to ensure consistent storage usage.
     * @return The default storage range used with repos.
     */
    function _erc4626() internal pure virtual returns (ERC4626Layout storage) {
        return STORAGE_SLOT.layout();
    }

    // end::_erc4626()[]

    /* ---------------------------------------------------------------------- */
    /*                             INITIALIZATION                             */
    /* ---------------------------------------------------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC4626(string memory name, string memory symbol, IERC20 asset, uint8 decimalsOffset) internal {
        _erc4626().asset = asset;
        _erc4626().decimalsOffset = decimalsOffset;
        uint8 assetDecimals = asset.safeDecimals();
        _erc4626().assetDecimals = assetDecimals;
        _initERC20(name, symbol, assetDecimals);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC4626(ERC20StorageInit memory erc20Init, ERC4626StorageInit memory erc4626Init) internal {
        _initERC4626(erc20Init.name, erc20Init.symbol, erc4626Init.asset, erc4626Init.decimalsOffset);
    }

    function _asset() internal view returns (IERC20) {
        return _erc4626().asset;
    }

    function _assetDecimals() internal view returns (uint8) {
        return _erc4626().assetDecimals;
    }

    function _decimalsOffset() internal view returns (uint8) {
        return _erc4626().decimalsOffset;
    }

    function _totalAssets() internal view virtual returns (uint256) {
        return IERC20(_asset()).balanceOf(address(this));
    }

    /**
     * @dev Internal conversion function (from assets to shares) with support for rounding direction.
     */
    function _convertToShares(uint256 assets, Math.Rounding rounding) internal view virtual returns (uint256) {
        return assets.mulDiv(_totalSupply() + 10 ** _decimalsOffset(), _totalAssets() + 1, rounding);
    }

    /**
     * @dev Internal conversion function (from shares to assets) with support for rounding direction.
     */
    function _convertToAssets(uint256 shares, Math.Rounding rounding) internal view virtual returns (uint256) {
        return shares.mulDiv(_totalAssets() + 1, _totalSupply() + 10 ** _decimalsOffset(), rounding);
    }

    /**
     * @dev Deposit/mint common workflow.
     */
    function _deposit(address caller, address receiver, uint256 assets, uint256 shares) internal virtual {
        // If asset() is ERC-777, `transferFrom` can trigger a reentrancy BEFORE the transfer happens through the
        // `tokensToSend` hook. On the other hand, the `tokenReceived` hook, that is triggered after the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer before we mint so that any reentrancy would happen before the
        // assets are transferred and before the shares are minted, which is a valid state.
        // slither-disable-next-line reentrancy-no-eth
        SafeERC20.safeTransferFrom(IERC20(_asset()), caller, address(this), assets);
        _mint(receiver, shares);

        emit IERC4626.Deposit(caller, receiver, assets, shares);
    }

    /**
     * @dev Withdraw/redeem common workflow.
     */
    function _withdraw(address caller, address receiver, address owner, uint256 assets, uint256 shares)
        internal
        virtual
    {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        // If asset() is ERC-777, `transfer` can trigger a reentrancy AFTER the transfer happens through the
        // `tokensReceived` hook. On the other hand, the `tokensToSend` hook, that is triggered before the transfer,
        // calls the vault, which is assumed not malicious.
        //
        // Conclusion: we need to do the transfer after the burn so that any reentrancy would happen after the
        // shares are burned and after the assets are transferred, which is a valid state.
        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(_asset()), receiver, assets);

        emit IERC4626.Withdraw(caller, receiver, owner, assets, shares);
    }
}
// end::ERC4626Storage[]
