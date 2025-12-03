// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/**
 * @title ICreate2Aware
 * @author cyotee doge <doge.cyotee>
 * @notice Declares the CREATE2 metadata for a contract.
 * @notice Intended to be used with a callback factory to retrieve metadata.
 */
interface ICreate2Aware {
    /**
     * @param origin The origin of the contract.
     * @param initcodeHash The initcode hash of the contract.
     * @param salt The salt of the contract.
     */
    struct CREATE2Metadata {
        address origin;
        bytes32 initcodeHash;
        bytes32 salt;
    }

    /**
     * @return The origin of the contract.
     * @custom:selector 0xb29c192b
     */
    function ORIGIN() external view returns (address);

    /**
     * @return The initcode hash of the contract.
     * @custom:selector 0xf8461884
     */
    function INITCODE_HASH() external view returns (bytes32);

    /**
     * @return The salt of the contract.
     * @custom:selector 0xba9a91a5
     */
    function SALT() external view returns (bytes32);

    /**
     * @notice Optimizes gas for retrieving all the CREATE2 metadata of the contract.
     * @return All the CREATE2 metadata of the contract.
     * @custom:selector 0x38c3df07
     */
    function METADATA() external view returns (CREATE2Metadata memory);
}
