// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;


import { IUniswapV2Factory } from "../../../../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Factory.sol";
import { IUniswapV2Router } from    "../../../../../interfaces/protocols/dexes/uniswap/v2/IUniswapV2Router.sol";
import {
    UniswapV2AwareLayout,
    UniswapV2AwareRepo
} from "./UniswapV2AwareRepo.sol";
import { IUniswapV2Aware } from "../../../../../interfaces/IUniswapV2Aware.sol";

contract UniswapV2AwareStorage {

    /* ------------------------------ LIBRARIES ----------------------------- */

    using UniswapV2AwareRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID =
        keccak256(abi.encode(type(UniswapV2AwareRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET =
        bytes32(uint256(keccak256(abi.encode(LAYOUT_ID))) - 1);
    bytes32 private constant STORAGE_RANGE =
        type(IUniswapV2Aware).interfaceId;
    bytes32 private constant STORAGE_SLOT =
        keccak256(abi.encode(STORAGE_RANGE, STORAGE_RANGE_OFFSET));

    // tag::_uniswapV2Aware()[]
    /**
     * @dev internal hook for the default storage range used by this library.
     * @dev Other services will use their default storage range to ensure consistent storage usage.
     * @return The default storage range used with repos.
     */
    function _uniswapV2Aware()
    internal pure virtual returns (UniswapV2AwareLayout storage) {
        return STORAGE_SLOT._layout();
    }
    // end::_uniswapV2Aware()[]

    /* ---------------------------------------------------------------------- */
    /*                             Initialization                             */
    /* ---------------------------------------------------------------------- */

    function _initUniswapV2Aware(
        IUniswapV2Factory factory,
        IUniswapV2Router router
    ) internal {
        _uniswapV2Aware().factory = factory;
        _uniswapV2Aware().router = router;
    }

    /* ---------------------------------------------------------------------- */
    /*                                  Logic                                 */
    /* ---------------------------------------------------------------------- */

    function _uniV2Factory() internal view returns (IUniswapV2Factory) {
        return _uniswapV2Aware().factory;
    }

    function _uniV2Router() internal view returns (IUniswapV2Router) {
        return _uniswapV2Aware().router;
    }

}