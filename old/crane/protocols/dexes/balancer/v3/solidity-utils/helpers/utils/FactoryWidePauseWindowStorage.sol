// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {IFactoryWidePauseWindow} from "contracts/crane/interfaces/IFactoryWidePauseWindow.sol";

struct FactoryWidePauseWindowLayout {
    uint32 pauseWindowDuration;
    uint32 pauseWindowEndTime;
}

library FactoryWidePauseWindowRepo {
    // tag::_layout[]
    /**
     * @dev "Binds" this struct to a storage slot.
     * @param slot_ The first slot to use in the range of slots used by the struct.
     * @return layout_ A struct from a Layout library bound to the provided slot.
     */
    function _layout(bytes32 slot_) internal pure returns (FactoryWidePauseWindowLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
}

contract FactoryWidePauseWindowStorage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using FactoryWidePauseWindowRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(FactoryWidePauseWindowRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE =
    // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
    // https://eips.ethereum.org/EIPS/eip-20
    type(IFactoryWidePauseWindow).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_factoryPauseWindow()[]
    /**
     * @dev internal hook for the default storage range used by this contract.
     * @return The default storage range used with repos.
     */
    function _factoryPauseWindow() internal pure virtual returns (FactoryWidePauseWindowLayout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_factoryPauseWindow()[]

    /* ---------------------------------------------------------------------- */
    /*                             INITIALIZATION                             */
    /* ---------------------------------------------------------------------- */

    function _initFactoryWidePauseWindow(uint32 pauseWindowDuration_) internal {
        _factoryPauseWindow().pauseWindowDuration = pauseWindowDuration_;
        _factoryPauseWindow().pauseWindowEndTime = uint32(block.timestamp + pauseWindowDuration_);
    }

    function _getPauseWindowDuration() internal view returns (uint32) {
        return _factoryPauseWindow().pauseWindowDuration;
    }

    function _getOriginalPauseWindowEndTime() internal view returns (uint32) {
        return _factoryPauseWindow().pauseWindowEndTime;
    }

    function _getNewPoolPauseWindowEndTime() internal view returns (uint32) {
        // We know _poolsPauseWindowEndTime <= _MAX_TIMESTAMP (checked above).
        // Do not truncate timestamp; it should still return 0 after _MAX_TIMESTAMP.
        uint32 pauseWindowEndTime = _getOriginalPauseWindowEndTime();
        return (block.timestamp < pauseWindowEndTime) ? pauseWindowEndTime : 0;
    }
}
