// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    /**
     * @custom:selector 0x017e7e58
     */
    function feeTo() external view returns (address);

    /**
     * @custom:selector 0x094b7415
     */
    function feeToSetter() external view returns (address);

    /**
     * @custom:selector 0xe6a43905
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @custom:selector 0x1e3dd18b
     */
    function allPairs(uint256) external view returns (address pair);

    /**
     * @custom:selector 0x574f2ba3
     */
    function allPairsLength() external view returns (uint256);

    /**
     * @custom:selector 0xc9c65396
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @custom:selector 0xf46901ed
     */
    function setFeeTo(address) external;

    /**
     * @custom:selector 0xa2e74af6
     */
    function setFeeToSetter(address) external;
}
