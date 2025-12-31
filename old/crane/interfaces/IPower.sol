// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

interface IPower {
    /**
     * @custom:selector 0x32833d51
     */
    function power(uint256 _baseN, uint256 _baseD, uint32 _expN, uint32 _expD) external view returns (uint256, uint8);

    /**
     * @custom:selector 0x4c3eea9e
     */
    function generalLog(uint256 _x) external pure returns (uint256);

    /**
     * @custom:selector 0x45b8bafc
     */
    function floorLog2(uint256 _n) external pure returns (uint8);

    /**
     * @custom:selector 0xce784564
     */
    function findPositionInMaxExpArray(uint256 _x) external view returns (uint8);

    /**
     * @custom:selector 0x29576c82
     */
    function generalExp(uint256 _x, uint8 _precision) external pure returns (uint256);

    /**
     * @custom:selector 0xa324cca0
     */
    function optimalLog(uint256 x) external pure returns (uint256);

    /**
     * @custom:selector 0x95050862
     */
    function optimalExp(uint256 x) external pure returns (uint256);
}
