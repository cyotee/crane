// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPMarket {
    function getSyToken() external view returns (address);
    function getPTToken() external view returns (address);
    function getYTToken(address user) external view returns (address);
    function mint(address receiver, uint256 mintAmount) external returns (uint256, uint256, uint256);
    function burn(address receiver, uint256 burnAmount) external returns (uint256, uint256, uint256);
}
