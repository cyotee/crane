// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {AddressSet, AddressSetRepo} from "@crane/src/utils/collections/sets/AddressSetRepo.sol";
import {ERC5115Layout, ERC5115Repo} from "contracts/crane/token/ERC5115/utils/ERC5115Repo.sol";
import {IERC5115} from "contracts/crane/interfaces/IERC5115.sol";

contract ERC5115Storage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using AddressSetRepo for AddressSet;
    using ERC5115Repo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(ERC5115Repo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE = type(IERC5115).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_erc5115()[]
    /**
     * @dev internal hook for the default storage range used by this library.
     * @dev Other services will use their default storage range to ensure consistent storage usage.
     * @return The default storage range used with repos.
     */
    function _erc5115() internal pure virtual returns (ERC5115Layout storage) {
        return STORAGE_SLOT._layout();
    }

    // end::_erc5115()[]

    /* ---------------------------------------------------------------------- */
    /*                             Initialization                             */
    /* ---------------------------------------------------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function _initERC5115(address yieldToken, address[] memory tokensIn, address[] memory tokensOut) internal {
        _erc5115().yieldToken = yieldToken;
        _erc5115().tokensIn._add(tokensIn);
        _erc5115().tokensOut._add(tokensOut);
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    function _yieldToken() internal view returns (address) {
        return _erc5115().yieldToken;
    }

    function _tokensIn() internal view returns (AddressSet storage) {
        return _erc5115().tokensIn;
    }

    function _tokensOut() internal view returns (AddressSet storage) {
        return _erc5115().tokensOut;
    }
}
