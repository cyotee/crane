// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";

// tag::IUniswapV4ProtocolAware[]
/// @notice Stored Uniswap V4 architecture addresses for one diamond.
/// @dev One repo holds the protocol pair. It is not one repo per component.
interface IUniswapV4ProtocolAware {
    function poolManager() external view returns (IPoolManager);
    function positionDescriptor() external view returns (address);
    function positionManager() external view returns (address);
    function quoter() external view returns (address);
    function stateView() external view returns (address);
    function reservesLens() external view returns (address);
    function universalRouter() external view returns (address);
}
// end::IUniswapV4ProtocolAware[]
