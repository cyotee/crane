// SPDX-License-Identifier: MIT

pragma solidity ^0.8.35;

import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@crane/contracts/external/openzeppelin-contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@crane/contracts/external/openzeppelin-contracts/interfaces/IERC5267.sol";

interface IBoldToken is IERC20Metadata, IERC20Permit, IERC5267 {
    function setBranchAddresses(
        address _troveManagerAddress,
        address _stabilityPoolAddress,
        address _borrowerOperationsAddress,
        address _activePoolAddress
    ) external;

    function setCollateralRegistry(address _collateralRegistryAddress) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender, address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount) external;
}
