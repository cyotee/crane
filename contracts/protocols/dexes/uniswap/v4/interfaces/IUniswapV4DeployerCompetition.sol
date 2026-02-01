// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title IUniswapV4DeployerCompetition
/// @notice Interface for the UniswapV4DeployerCompetition contract
/// @dev Ported from Uniswap V4 periphery for local compatibility
interface IUniswapV4DeployerCompetition {
    /// @notice Emitted when a new best address is found
    /// @param bestAddress The new best address
    /// @param submitter The address that submitted the winning salt
    /// @param score The vanity score of the address
    event NewAddressFound(address indexed bestAddress, address indexed submitter, uint256 score);

    /// @notice Thrown when the bytecode hash doesn't match the expected init code hash
    error InvalidBytecode();

    /// @notice Thrown when trying to deploy before the competition ends
    /// @param currentTime The current block timestamp
    /// @param deadline The competition deadline
    error CompetitionNotOver(uint256 currentTime, uint256 deadline);

    /// @notice Thrown when trying to submit after the competition ends
    /// @param currentTime The current block timestamp
    /// @param deadline The competition deadline
    error CompetitionOver(uint256 currentTime, uint256 deadline);

    /// @notice Thrown when a non-deployer tries to deploy during the exclusive period
    /// @param sender The address attempting to deploy
    /// @param deployer The authorized deployer address
    error NotAllowedToDeploy(address sender, address deployer);

    /// @notice Thrown when the new address doesn't have a better score
    /// @param newAddress The submitted address
    /// @param bestAddress The current best address
    /// @param newScore The score of the new address
    /// @param bestScore The score of the current best address
    error WorseAddress(address newAddress, address bestAddress, uint256 newScore, uint256 bestScore);

    /// @notice Thrown when the sender doesn't match the salt requirements
    /// @param salt The submitted salt
    /// @param sender The message sender
    error InvalidSender(bytes32 salt, address sender);

    /// @notice Updates the best address if the new address has a better vanity score
    /// @param salt The salt to use to compute the new address with CREATE2
    /// @dev The first 20 bytes of the salt must be either address(0) or msg.sender
    function updateBestAddress(bytes32 salt) external;

    /// @notice Deploys the Uniswap V4 PoolManager contract
    /// @param bytecode The bytecode of the Uniswap V4 PoolManager contract
    /// @dev The bytecode must match the initCodeHash
    function deploy(bytes memory bytecode) external;
}
