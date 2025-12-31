// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ICamelotFactory} from "./protocols/dexes/camelot/v2/ICamelotFactory.sol";
import {ICamelotPair} from "./protocols/dexes/camelot/v2/ICamelotPair.sol";
import {ICamelotV2Router} from "./protocols/dexes/camelot/v2/ICamelotV2Router.sol";
import {BetterIERC20 as IERC20} from "./BetterIERC20.sol";

interface ICamelotPairAware {
    struct CamelotPair {
        ICamelotPair pool;
        IERC20 token0;
        uint256 token0Reserve;
        uint256 token0SaleFee;
        IERC20 token1;
        uint256 token1Reserve;
        uint256 token1SaleFee;
    }

    /**
     * @custom:selector 0xb8085bb8
     */
    function camelotFactory() external view returns (ICamelotFactory);

    /**
     * @custom:selector 0x0182a95f
     */
    function camV2Router() external view returns (ICamelotV2Router);

    /**
     * @custom:selector 0x1752417f
     */
    function camV2Pair() external view returns (ICamelotPair);

    /**
     * @custom:selector 0x0dfe1681
     */
    function token0() external view returns (IERC20);

    /**
     * @custom:selector 0xd21220a7
     */
    function token1() external view returns (IERC20);

    /**
     * @custom:selector 0x6184f565
     */
    function opTokenOfToken(IERC20 token) external view returns (IERC20);

    /**
     * @custom:selector 0x9752e5e8
     */
    function loadPair() external view returns (CamelotPair memory pair);
}
