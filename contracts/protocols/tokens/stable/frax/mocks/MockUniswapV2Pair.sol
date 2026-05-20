// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "@crane/contracts/protocols/tokens/stable/frax/ERC20/ERC20.sol";

/// @notice Minimal Uniswap V2 pair stub for StakingRewardsDualV5 tests
contract MockUniswapV2Pair is ERC20 {
    address public immutable token0;
    address public immutable token1;
    uint112 public reserve0;
    uint112 public reserve1;

    constructor(address token0_, address token1_, uint112 reserve0_, uint112 reserve1_)
        ERC20("Mock LP", "MLP")
    {
        token0 = token0_;
        token1 = token1_;
        reserve0 = reserve0_;
        reserve1 = reserve1_;
    }

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function setReserves(uint112 reserve0_, uint112 reserve1_) external {
        reserve0 = reserve0_;
        reserve1 = reserve1_;
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, uint32(block.timestamp));
    }
}