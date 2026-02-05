// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import { IPermit2 } from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {Permit2AwareRepo} from "@crane/contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

library ERC4626Repo {
    bytes32 internal constant STORAGE_SLOT = keccak256("eip.erc.4626");

    struct Storage {
        IERC20 reserveAsset;
        uint8 reserveAssetDecimals;
        uint8 decimalOffset;
        uint256 lastTotalAssets;
    }

    function _layout(bytes32 slot) internal pure returns (Storage storage l) {
        assembly {
            l.slot := slot
        }
    }

    function _layout() internal pure returns (Storage storage l) {
        return _layout(STORAGE_SLOT);
    }

    function _initialize(
        Storage storage layout,
        IERC20 reserveAsset_,
        uint8 reserveAssetDecimals_,
        uint8 decimalOffset_
    ) internal {
        _setReserveAsset(layout, reserveAsset_, reserveAssetDecimals_);
        _setDecimalOffset(layout, decimalOffset_);
    }

    function _initialize(IERC20 reserveAsset_, uint8 reserveAssetDecimals_, uint8 decimalOffset_) internal {
        _initialize(_layout(), reserveAsset_, reserveAssetDecimals_, decimalOffset_);
    }

    function _setReserveAsset(Storage storage layout, IERC20 reserveAsset_, uint8 reserveAssetDecimals_)
        internal
    {
        layout.reserveAsset = reserveAsset_;
        layout.reserveAssetDecimals = reserveAssetDecimals_;
    }

    function _setDecimalOffset(Storage storage layout, uint8 decimalOffset_) internal {
        layout.decimalOffset = decimalOffset_;
    }

    function _setLastTotalAssets(Storage storage layout, uint256 lastTotalAssets_) internal {
        layout.lastTotalAssets = lastTotalAssets_;
    }

    function _setLastTotalAssets(uint256 lastTotalAssets_) internal {
        _setLastTotalAssets(_layout(), lastTotalAssets_);
    }

    function _reserveAsset(Storage storage layout) internal view returns (IERC20) {
        return layout.reserveAsset;
    }

    function _reserveAsset() internal view returns (IERC20) {
        return _layout().reserveAsset;
    }

    function _reserveAssetDecimals(Storage storage layout) internal view returns (uint8) {
        return layout.reserveAssetDecimals;
    }

    function _reserveAssetDecimals() internal view returns (uint8) {
        return _layout().reserveAssetDecimals;
    }

    function _decimalOffset(Storage storage layout) internal view returns (uint8) {
        return layout.decimalOffset;
    }

    function _decimalOffset() internal view returns (uint8) {
        return _layout().decimalOffset;
    }

    function _lastTotalAssets(Storage storage layout) internal view returns (uint256) {
        return layout.lastTotalAssets;
    }

    function _lastTotalAssets() internal view returns (uint256) {
        return _layout().lastTotalAssets;
    }
}
