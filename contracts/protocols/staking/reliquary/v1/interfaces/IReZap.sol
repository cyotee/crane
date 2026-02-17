// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";

interface IReZap {
    enum JoinType {
        Swap,
        Weighted
    }

    struct Step {
        address startToken;
        address endToken;
        uint8 inIdx;
        uint8 outIdx;
        JoinType jT;
        bytes32 poolId;
        uint256 minAmountOut;
    }

    function zapIn(Step[] calldata steps, address crypt, uint256 tokenInAmount) external;

    function zapInETH(Step[] calldata steps, address crypt) external payable;

    function zapOut(Step[] calldata steps, address crypt, uint256 cryptAmount) external;

    function WETH() external view returns (address);
}
