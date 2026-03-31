// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

library SafeTransferLib {
    function transferETH(address to, uint256 amount) external pure;
    function transfer(ERC20 token, address to, uint256 amount) external pure;
}
