// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {ICamelotPairAware} from "contracts/crane/interfaces/ICamelotPairAware.sol";
import {CamelotPairAwareLayout, CamelotPairAwareRepo} from "./CamelotPairAwareRepo.sol";

contract CamelotPairAwareStorage {
    /* ------------------------------ LIBRARIES ----------------------------- */

    using CamelotPairAwareRepo for bytes32;

    /* ---------------------------------------------------------------------- */
    /*                                 STORAGE                                */
    /* ---------------------------------------------------------------------- */

    /* -------------------------- STORAGE CONSTANTS ------------------------- */

    bytes32 private constant LAYOUT_ID = keccak256(abi.encode(type(CamelotPairAwareRepo).name));
    bytes32 private constant STORAGE_RANGE_OFFSET = bytes32(uint256(LAYOUT_ID) - 1);
    bytes32 private constant STORAGE_RANGE =
    // We XOR the two interfaces because the current ERC20 standard no longer states the metadata is optional.
    // https://eips.ethereum.org/EIPS/eip-20
    type(ICamelotPairAware).interfaceId;
    bytes32 private constant STORAGE_SLOT = (STORAGE_RANGE ^ STORAGE_RANGE_OFFSET);

    // tag::_camV2Aware()[]
    /**
     * @dev internal hook for the default storage range used by this contract.
     * @return The default storage range used with repos.
     */
    function _camV2Aware() internal pure virtual returns (CamelotPairAwareLayout storage) {
        return STORAGE_SLOT.layout();
    }
    // end::_camV2Aware()[]

    function _initCamelotPairAware(
        ICamelotFactory camelotFactory,
        ICamelotV2Router camV2Router,
        ICamelotPair camV2Pair,
        IERC20 token0,
        IERC20 token1
    ) internal {
        _camV2Aware().camelotFactory = camelotFactory;
        _camV2Aware().camV2Router = camV2Router;
        _camV2Aware().camV2Pair = camV2Pair;
        _camV2Aware().token0 = token0;
        _camV2Aware().token1 = token1;
        _camV2Aware().opTokenOfToken[token0] = token1;
        _camV2Aware().opTokenOfToken[token1] = token0;
    }

    function _camV2Factory() internal view returns (ICamelotFactory) {
        return _camV2Aware().camelotFactory;
    }

    function _camV2Router() internal view returns (ICamelotV2Router) {
        return _camV2Aware().camV2Router;
    }

    function _camV2Pair() internal view returns (ICamelotPair) {
        return _camV2Aware().camV2Pair;
    }

    function _token0() internal view returns (IERC20) {
        return _camV2Aware().token0;
    }

    function _token1() internal view returns (IERC20) {
        return _camV2Aware().token1;
    }

    function _opTokenOfToken(IERC20 token) internal view returns (IERC20) {
        return _camV2Aware().opTokenOfToken[token];
    }

    function _loadPair() internal view returns (ICamelotPairAware.CamelotPair memory pair) {
        pair.pool = _camV2Pair();
        pair.token0 = _token0();
        pair.token1 = _token1();
        (pair.token0Reserve, pair.token1Reserve, pair.token0SaleFee, pair.token1SaleFee) = pair.pool.getReserves();
    }
}
