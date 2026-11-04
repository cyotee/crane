// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {PoolKey} from "@crane/contracts/protocols/dexes/uniswap/v4/types/PoolKey.sol";

// tag::IUniswapV4SinglePositionAware[]
/// @notice One pool key and one position, reusable by vaults with different ranges.
interface IUniswapV4SinglePositionAware {
    function poolKey() external view returns (PoolKey memory);
    function tickLower() external view returns (int24);
    function tickUpper() external view returns (int24);
    function positionSalt() external view returns (bytes32);
    function positionLiquidity() external view returns (uint128);
}
// end::IUniswapV4SinglePositionAware[]
