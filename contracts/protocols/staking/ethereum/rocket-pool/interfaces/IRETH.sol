// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

/**
 * @title IRETH
 * @notice Rocket Pool rETH token.
 * @dev Mainnet: 0xae78736Cd615f374D3085123A210448E74Fc6393
 */
interface IRETH is IERC20 {
    function getExchangeRate() external view returns (uint256);

    function getEthValue(uint256 rethAmount) external view returns (uint256);

    function getRethValue(uint256 ethAmount) external view returns (uint256);

    function burn(uint256 rethAmount) external;
}
