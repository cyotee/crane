// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {Permit2AwareRepo} from "@crane/contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";

// tag::ERC4626Repo[]
/**
 * @title ERC4626Repo - Storage library for ERC-4626 vault token (reserve asset, decimal offset, last total assets tracking).
 * @author cyotee doge <not_cyotee@proton.me>
 * @dev Storage library (Repo) for ERC4626-specific vault state.
 * @dev Provides dual (parameterized + default) overloads for initialization and all storage accessors/mutators.
 * @dev Follows the gold standard from ERC2535Repo, OperableRepo, DeployedAddressesRepo, DiamondPackageCallBackFactoryAwareRepo, Create3FactoryAwareRepo
 *      (rich NatSpec, exact // tag:: / end:: include tags, @dev "The Storage struct to operate on.", ERC1967-compliant STORAGE_SLOT).
 * @dev Used by ERC4626 implementations for Diamond storage binding of vault token fields.
 */
library ERC4626Repo {
    // tag::STORAGE_SLOT[]
    /**
     * @dev ERC1967-compliant storage slot.
     *      Computed as bytes32(uint256(keccak256(abi.encode("eip.erc.4626"))) - 1).
     *      This follows the canonical pattern used by ERC2535Repo (eip.erc.2535), OperableRepo, MultiStepOwnableRepo,
     *      DeployedAddressesRepo, and other gold-standard Repos for collision-resistant deterministic storage binding.
     */
    bytes32 internal constant STORAGE_SLOT = bytes32(uint256(keccak256(abi.encode("eip.erc.4626"))) - 1);

    // end::STORAGE_SLOT[]

    // tag::Storage[]
    /**
     * @dev Standardized storage layout for ERC-4626 vault token.
     *      reserveAsset: The underlying ERC20 asset for the vault.
     *      reserveAssetDecimals: Decimals of the reserve asset.
     *      decimalOffset: Offset applied to share decimals vs asset.
     *      lastTotalAssets: Snapshot of total assets for fee/interest accounting.
     */
    struct Storage {
        IERC20 reserveAsset;
        uint8 reserveAssetDecimals;
        uint8 decimalOffset;
        uint256 lastTotalAssets;
    }

    // end::Storage[]

    // tag::_layoutStruct(bytes32)[]
    /**
     * @dev Argumented version of _layoutStruct to allow for custom storage slot usage.
     * @param slot_ The storage slot to bind.
     * @return layoutStruct The Storage struct bound to the provided slot.
     */
    function _layoutStruct(bytes32 slot_) internal pure returns (Storage storage layoutStruct) {
        assembly {
            layoutStruct.slot := slot_
        }
    }

    // end::_layoutStruct(bytes32)[]

    // tag::_layoutStruct()[]
    /**
     * @dev Default _layoutStruct binding to the canonical ERC1967 STORAGE_SLOT.
     * @return layoutStruct The Storage struct bound to STORAGE_SLOT.
     */
    function _layoutStruct() internal pure returns (Storage storage layoutStruct) {
        return _layoutStruct(STORAGE_SLOT);
    }

    // end::_layoutStruct()[]

    // tag::_initialize(Storage-IERC20-uint8-uint8)[]
    /**
     * @dev Argumented version of _initialize to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param reserveAsset_ The underlying reserve asset IERC20.
     * @param reserveAssetDecimals_ Decimals of the reserve asset.
     * @param decimalOffset_ The decimal offset for share tokens.
     */
    function _initialize(
        Storage storage layoutStruct,
        IERC20 reserveAsset_,
        uint8 reserveAssetDecimals_,
        uint8 decimalOffset_
    ) internal {
        _setReserveAsset(layoutStruct, reserveAsset_, reserveAssetDecimals_);
        _setDecimalOffset(layoutStruct, decimalOffset_);
    }

    // end::_initialize(Storage-IERC20-uint8-uint8)[]

    // tag::_initialize(IERC20-uint8-uint8)[]
    /**
     * @dev Default version of _initialize binding to the standard STORAGE_SLOT.
     * @param reserveAsset_ The underlying reserve asset IERC20.
     * @param reserveAssetDecimals_ Decimals of the reserve asset.
     * @param decimalOffset_ The decimal offset for share tokens.
     */
    function _initialize(IERC20 reserveAsset_, uint8 reserveAssetDecimals_, uint8 decimalOffset_) internal {
        _initialize(_layoutStruct(), reserveAsset_, reserveAssetDecimals_, decimalOffset_);
    }

    // end::_initialize(IERC20-uint8-uint8)[]

    // tag::_setReserveAsset(Storage-IERC20-uint8)[]
    /**
     * @dev Argumented version of _setReserveAsset to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param reserveAsset_ The underlying reserve asset IERC20.
     * @param reserveAssetDecimals_ Decimals of the reserve asset.
     */
    function _setReserveAsset(Storage storage layoutStruct, IERC20 reserveAsset_, uint8 reserveAssetDecimals_)
        internal
    {
        layoutStruct.reserveAsset = reserveAsset_;
        layoutStruct.reserveAssetDecimals = reserveAssetDecimals_;
    }

    // end::_setReserveAsset(Storage-IERC20-uint8)[]

    // tag::_setReserveAsset(IERC20-uint8)[]
    /**
     * @dev Default version of _setReserveAsset binding to the standard STORAGE_SLOT.
     * @param reserveAsset_ The underlying reserve asset IERC20.
     * @param reserveAssetDecimals_ Decimals of the reserve asset.
     */
    function _setReserveAsset(IERC20 reserveAsset_, uint8 reserveAssetDecimals_) internal {
        _setReserveAsset(_layoutStruct(), reserveAsset_, reserveAssetDecimals_);
    }

    // end::_setReserveAsset(IERC20-uint8)[]

    // tag::_setDecimalOffset(Storage-uint8)[]
    /**
     * @dev Argumented version of _setDecimalOffset to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param decimalOffset_ The decimal offset for share tokens.
     */
    function _setDecimalOffset(Storage storage layoutStruct, uint8 decimalOffset_) internal {
        layoutStruct.decimalOffset = decimalOffset_;
    }

    // end::_setDecimalOffset(Storage-uint8)[]

    // tag::_setDecimalOffset(uint8)[]
    /**
     * @dev Default version of _setDecimalOffset binding to the standard STORAGE_SLOT.
     * @param decimalOffset_ The decimal offset for share tokens.
     */
    function _setDecimalOffset(uint8 decimalOffset_) internal {
        _setDecimalOffset(_layoutStruct(), decimalOffset_);
    }

    // end::_setDecimalOffset(uint8)[]

    // tag::_setLastTotalAssets(Storage-uint256)[]
    /**
     * @dev Argumented version of _setLastTotalAssets to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @param lastTotalAssets_ Snapshot value of total assets.
     */
    function _setLastTotalAssets(Storage storage layoutStruct, uint256 lastTotalAssets_) internal {
        layoutStruct.lastTotalAssets = lastTotalAssets_;
    }

    // end::_setLastTotalAssets(Storage-uint256)[]

    // tag::_setLastTotalAssets(uint256)[]
    /**
     * @dev Default version of _setLastTotalAssets binding to the standard STORAGE_SLOT.
     * @param lastTotalAssets_ Snapshot value of total assets.
     */
    function _setLastTotalAssets(uint256 lastTotalAssets_) internal {
        _setLastTotalAssets(_layoutStruct(), lastTotalAssets_);
    }

    // end::_setLastTotalAssets(uint256)[]

    // tag::_reserveAsset(Storage)[]
    /**
     * @dev Argumented version of _reserveAsset to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return reserveAsset_ The stored reserve asset.
     */
    function _reserveAsset(Storage storage layoutStruct) internal view returns (IERC20 reserveAsset_) {
        return layoutStruct.reserveAsset;
    }

    // end::_reserveAsset(Storage)[]

    // tag::_reserveAsset()[]
    /**
     * @dev Default version of _reserveAsset binding to the standard STORAGE_SLOT.
     * @return reserveAsset_ The stored reserve asset.
     */
    function _reserveAsset() internal view returns (IERC20 reserveAsset_) {
        return _reserveAsset(_layoutStruct());
    }

    // end::_reserveAsset()[]

    // tag::_reserveAssetDecimals(Storage)[]
    /**
     * @dev Argumented version of _reserveAssetDecimals to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return decimals_ The stored reserve asset decimals.
     */
    function _reserveAssetDecimals(Storage storage layoutStruct) internal view returns (uint8 decimals_) {
        return layoutStruct.reserveAssetDecimals;
    }

    // end::_reserveAssetDecimals(Storage)[]

    // tag::_reserveAssetDecimals()[]
    /**
     * @dev Default version of _reserveAssetDecimals binding to the standard STORAGE_SLOT.
     * @return decimals_ The stored reserve asset decimals.
     */
    function _reserveAssetDecimals() internal view returns (uint8 decimals_) {
        return _reserveAssetDecimals(_layoutStruct());
    }

    // end::_reserveAssetDecimals()[]

    // tag::_decimalOffset(Storage)[]
    /**
     * @dev Argumented version of _decimalOffset to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return offset_ The stored decimal offset.
     */
    function _decimalOffset(Storage storage layoutStruct) internal view returns (uint8 offset_) {
        return layoutStruct.decimalOffset;
    }

    // end::_decimalOffset(Storage)[]

    // tag::_decimalOffset()[]
    /**
     * @dev Default version of _decimalOffset binding to the standard STORAGE_SLOT.
     * @return offset_ The stored decimal offset.
     */
    function _decimalOffset() internal view returns (uint8 offset_) {
        return _decimalOffset(_layoutStruct());
    }

    // end::_decimalOffset()[]

    // tag::_lastTotalAssets(Storage)[]
    /**
     * @dev Argumented version of _lastTotalAssets to allow direct Storage access.
     * @dev The Storage struct to operate on.
     * @param layoutStruct The Storage struct to operate on.
     * @return lastTotalAssets_ The stored last total assets snapshot.
     */
    function _lastTotalAssets(Storage storage layoutStruct) internal view returns (uint256 lastTotalAssets_) {
        return layoutStruct.lastTotalAssets;
    }

    // end::_lastTotalAssets(Storage)[]

    // tag::_lastTotalAssets()[]
    /**
     * @dev Default version of _lastTotalAssets binding to the standard STORAGE_SLOT.
     * @return lastTotalAssets_ The stored last total assets snapshot.
     */
    function _lastTotalAssets() internal view returns (uint256 lastTotalAssets_) {
        return _lastTotalAssets(_layoutStruct());
    }
    // end::_lastTotalAssets()[]
}
// end::ERC4626Repo[]
