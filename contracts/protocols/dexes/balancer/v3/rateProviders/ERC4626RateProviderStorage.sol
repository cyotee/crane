// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import { IERC4626 } from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { IERC4626RateProvider } from "contracts/interfaces/IERC4626RateProvider.sol";

struct ERC4626RateProviderLayout {
    IERC4626 erc4626Vault;
}

library ERC4626RateProviderRepo {

    // tag::_layout[]
    function _layout(
        bytes32 slot_
    ) internal pure returns (ERC4626RateProviderLayout storage layout_) {
        assembly {
            layout_.slot := slot_
        }
    }
    // end::_layout[]
    
}

contract ERC4626RateProviderStorage {

    /* ------------------------------ LIBRARIES ----------------------------- */

    using ERC4626RateProviderRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID =
        keccak256(abi.encode(type(ERC4626RateProviderRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET =
        bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE =
        type(IERC4626RateProvider).interfaceId;
    bytes32 private constant STORAGE_SLOT =
        keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    // tag::_erec4626RateProvider()[]
    /**
     * @dev internal hook for the default storage range used by this library.
     * @dev Other services will use their default storage range to ensure consistent storage usage.
     * @return The default storage range used with repos.
     */
    function _erec4626RateProvider()
    internal pure virtual returns (ERC4626RateProviderLayout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_erec4626RateProvider()[]

    /* ---------------------------------------------------------------------- */
    /*                             Initialization                             */
    /* ---------------------------------------------------------------------- */

    function _initERC4626RateProvider(
        IERC4626 erc4626Vault
    ) internal {
        _erec4626RateProvider().erc4626Vault = erc4626Vault;
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    function _erc4626Vault() internal view returns (IERC4626) {
        return _erec4626RateProvider().erc4626Vault;
    }

}