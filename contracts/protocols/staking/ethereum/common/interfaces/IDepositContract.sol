// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title IDepositContract
 * @notice Ethereum 2.0 deposit contract interface (mainnet 0x00000000219ab540356cBB839Cbe05303d7705Fa).
 * @dev Shared by Lido / Rocket Pool / ether.fi / StakeWise / Frax minter paths when interacting with the beacon deposit root.
 */
interface IDepositContract {
    event DepositEvent(bytes pubkey, bytes withdrawal_credentials, bytes amount, bytes signature, bytes index);

    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    function get_deposit_root() external view returns (bytes32);

    function get_deposit_count() external view returns (bytes memory);
}
