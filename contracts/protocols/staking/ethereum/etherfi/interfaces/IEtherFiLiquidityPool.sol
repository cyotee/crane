// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IEtherFiLiquidityPool
 * @notice ether.fi LiquidityPool deposit surface.
 * @dev Mainnet: 0x308861A430be4cce5502d0A12724771Fc6DaF216
 *      No EigenLayer / Uni V3 / LayerZero in this interface.
 */
interface IEtherFiLiquidityPool {
    function deposit() external payable returns (uint256);

    function deposit(address referral) external payable returns (uint256);

    function eETH() external view returns (address);

    function getTotalPooledEther() external view returns (uint256);

    function getTotalEtherClaimOf(address user) external view returns (uint256);

    function sharesForAmount(uint256 amount) external view returns (uint256);

    function amountForShare(uint256 shares) external view returns (uint256);
}
