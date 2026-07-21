// SPDX-FileCopyrightText: 2021 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
// Vendored interface from lidofinance/core contracts/0.6.12/interfaces/IStETH.sol
// Adapted: pragma 0.6.12 → ^0.8.0; IERC20 from Crane OZ.

pragma solidity ^0.8.0;

import {IERC20} from "@crane/contracts/external/openzeppelin-contracts/token/ERC20/IERC20.sol";

interface IStETH is IERC20 {
    function getPooledEthByShares(uint256 _sharesAmount) external view returns (uint256);

    function getSharesByPooledEth(uint256 _pooledEthAmount) external view returns (uint256);

    function submit(address _referral) external payable returns (uint256);
}
