// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/**
 * @title IOsETH
 * @notice StakeWise V3 osETH (OsToken) surface.
 * @dev Mainnet: 0xf1C9acDc66974dFB6dEcB12aA385b9cD01190E38
 */
interface IOsETH is IERC20 {
    function controllers(address account) external view returns (bool);

    function burnController(address account) external;

    function mintShares(address account, uint256 shares) external;

    function burnShares(address account, uint256 shares) external;
}
