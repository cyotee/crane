// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.20;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {BetterIERC20 as IERC20} from "../../BetterIERC20.sol";
import {BetterSafeERC20 as SafeERC20} from "../../utils/BetterSafeERC20.sol";

import {
    ERC20Storage
} from "../../utils/ERC20Storage.sol";

import {
    ERC4626Layout,
    ERC4626Repo
} from "./ERC4626Repo.sol";

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
    using SafeERC20 for IERC20;
    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */
  
    bytes32 private constant LAYOUT_ID
        = keccak256(abi.encode(type(ERC4626Repo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET
        = bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE
        // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
        // https://eips.ethereum.org/EIPS/eip-20
        = type(IERC4626).interfaceId;
    bytes32 private constant STORAGE_SLOT
        = keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    // tag::_erc4626()[]
    /**
     * @dev internal hook for the default storage range used by this library.
     * @dev Other services will use their default storage range to ensure consistent storage usage.
     * @return The default storage range used with repos.
     */
    function _erc4626()
    internal pure virtual returns(ERC4626Layout storage) {
        return STORAGE_SLOT.layout();
    }
    // end::_erc4626()[]

    /* ---------------------------------------------------------------------- */
    /*                             INITIALIZATION                             */
    /* ---------------------------------------------------------------------- */

    function _initERC4626(
        string memory name,
        string memory symbol,
        IERC20 asset,
        uint8 decimalsOffset
    ) internal {
        _erc4626().asset = asset;
        _erc4626().decimalsOffset = decimalsOffset;
        uint8 assetDecimals = asset.safeDecimals();
        _erc4626().assetDecimals = assetDecimals;
        _initERC20(
            name,
            symbol,
            assetDecimals
        );
    }

    function _initERC4626(
        ERC20StorageInit memory erc20Init,
        ERC4626StorageInit memory erc4626Init
    ) internal {
        _initERC4626(
            erc20Init.name,
            erc20Init.symbol,
            erc4626Init.asset,
            erc4626Init.decimalsOffset
        );
    }

    function _asset()
    internal view returns (IERC20) {
        return _erc4626().asset;
    }

    function _assetDecimals()
    internal view returns (uint8) {
        return _erc4626().assetDecimals;
    }

    function _decimalsOffset()
    internal view returns (uint8) {
        return _erc4626().decimalsOffset;
    }

}
// end::ERC4626Storage[]