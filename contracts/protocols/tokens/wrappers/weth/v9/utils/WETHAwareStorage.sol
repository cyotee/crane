// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { IWETH } from "@balancer-labs/v3-interfaces/contracts/solidity-utils/misc/IWETH.sol";
import { IWETHAware } from "contracts/interfaces/IWETHAware.sol";

struct WETHAwareLayout {
    IWETH weth;
}

library WETHAwareRepo {

    function _layout(
        bytes32 storageRange
    ) internal pure returns(WETHAwareLayout storage layout_) {
        assembly{layout_.slot := storageRange}
    }

}

contract WETHAwareStorage {

    /* ------------------------------ LIBRARIES ----------------------------- */

    using WETHAwareRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(WETHAwareRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        = type(IWETHAware).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    function _wethAware() internal pure returns (WETHAwareLayout storage) {
        return STORAGE_SLOT._layout();
    }

    function _initWethAware(
        IWETH weth
    ) internal {
        _wethAware().weth = weth;
    }

    function _weth() internal view returns (IWETH) {
        return _wethAware().weth;
    }
    
}