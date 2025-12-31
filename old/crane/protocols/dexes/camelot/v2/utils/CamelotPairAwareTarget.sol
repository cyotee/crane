// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import {ICamelotFactory} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotPair} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "contracts/crane/interfaces/protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "contracts/crane/interfaces/BetterIERC20.sol";
import {ICamelotPairAware} from "contracts/crane/interfaces/ICamelotPairAware.sol";
import {CamelotPairAwareStorage} from "contracts/crane/protocols/dexes/camelot/v2/utils/CamelotPairAwareStorage.sol";

contract CamelotPairAwareTarget is CamelotPairAwareStorage, ICamelotPairAware {
    function camelotFactory() external view returns (ICamelotFactory) {
        return _camV2Factory();
    }

    function camV2Router() external view returns (ICamelotV2Router) {
        return _camV2Router();
    }

    function camV2Pair() external view returns (ICamelotPair) {
        return _camV2Pair();
    }

    function token0() external view returns (IERC20) {
        return _token0();
    }

    function token1() external view returns (IERC20) {
        return _token1();
    }

    function opTokenOfToken(IERC20 token) external view returns (IERC20) {
        return _opTokenOfToken(token);
    }

    function loadPair() external view returns (ICamelotPairAware.CamelotPair memory pair) {
        return _loadPair();
    }
}
