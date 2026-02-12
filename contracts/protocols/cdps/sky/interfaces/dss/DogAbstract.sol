// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

// https://github.com/makerdao/dss/blob/master/src/dog.sol
interface DogAbstract {
    function wards(address) external view returns (uint256);
    function rely(address) external;
    function deny(address) external;
    function vat() external view returns (address);
    function ilks(bytes32) external view returns (address,uint256,uint256,uint256);
    function vow() external view returns (address);
    function live() external view returns (uint256);
    function Hole() external view returns (uint256);
    function Dirt() external view returns (uint256);
    function file(bytes32,address) external;
    function file(bytes32,uint256) external;
    function file(bytes32,bytes32,uint256) external;
    function file(bytes32,bytes32,address) external;
    function chop(bytes32) external view returns (uint256);
    function bark(bytes32,address,address) external returns (uint256);
    function digs(bytes32,uint256) external;
    function cage() external;
}
