// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
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

    function _layoutStruct(bytes32 slot) internal pure returns (Storage storage l) {
        assembly {
            l.slot := slot
        }
    }

    function _layoutStruct() internal pure returns (Storage storage l) {
        return _layoutStruct(STORAGE_SLOT);
    }

    function _initialize(
        Storage storage layoutStruct,
        IERC20 reserveAsset_,
        uint8 reserveAssetDecimals_,
        uint8 decimalOffset_
    ) internal {
        _setReserveAsset(layoutStruct, reserveAsset_, reserveAssetDecimals_);
        _setDecimalOffset(layoutStruct, decimalOffset_);
    }

    function _initialize(IERC20 reserveAsset_, uint8 reserveAssetDecimals_, uint8 decimalOffset_) internal {
        _initialize(_layoutStruct(), reserveAsset_, reserveAssetDecimals_, decimalOffset_);
    }

    function _setReserveAsset(Storage storage layoutStruct, IERC20 reserveAsset_, uint8 reserveAssetDecimals_) internal {
        layoutStruct.reserveAsset = reserveAsset_;
        layoutStruct.reserveAssetDecimals = reserveAssetDecimals_;
    }

    function _setDecimalOffset(Storage storage layoutStruct, uint8 decimalOffset_) internal {
        layoutStruct.decimalOffset = decimalOffset_;
    }

    function _setLastTotalAssets(Storage storage layoutStruct, uint256 lastTotalAssets_) internal {
        layoutStruct.lastTotalAssets = lastTotalAssets_;
    }

    function _setLastTotalAssets(uint256 lastTotalAssets_) internal {
        _setLastTotalAssets(_layoutStruct(), lastTotalAssets_);
    }

    function _reserveAsset(Storage storage layoutStruct) internal view returns (IERC20) {
        return layoutStruct.reserveAsset;
    }

    function _reserveAsset() internal view returns (IERC20) {
        return _layoutStruct().reserveAsset;
    }

    function _reserveAssetDecimals(Storage storage layoutStruct) internal view returns (uint8) {
        return layoutStruct.reserveAssetDecimals;
    }

    function _reserveAssetDecimals() internal view returns (uint8) {
        return _layoutStruct().reserveAssetDecimals;
    }

    function _decimalOffset(Storage storage layoutStruct) internal view returns (uint8) {
        return layoutStruct.decimalOffset;
    }

    function _decimalOffset() internal view returns (uint8) {
        return _layoutStruct().decimalOffset;
    }

    function _lastTotalAssets(Storage storage layoutStruct) internal view returns (uint256) {
        return layoutStruct.lastTotalAssets;
    }

    function _lastTotalAssets() internal view returns (uint256) {
        return _layoutStruct().lastTotalAssets;
    }
}
