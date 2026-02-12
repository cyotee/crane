// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title Provides non-owners with info about the current chain owners.
 * @notice Precompiled contract that exists in every Arbitrum chain at 0x000000000000000000000000000000000000006b.
 */
interface IArbOwnerPublic {
    /* ---------------------------------------------------------------------- */
    /*                                 Events                                 */
    /* ---------------------------------------------------------------------- */

    event ChainOwnerRectified(address rectifiedOwner);

    /// @notice See if the user is a chain owner
    function isChainOwner(address addr) external view returns (bool);

    /**
     * @notice Rectify the list of chain owners
     * If successful, emits ChainOwnerRectified event
     * Available in ArbOS version 11
     */
    function rectifyChainOwner(address ownerToRectify) external;

    /**
     * @notice Retrieves the list of chain owners
     */
    function getAllChainOwners() external view returns (address[] memory);

    /**
     * @notice Gets the network fee collector
     */
    function getNetworkFeeAccount() external view returns (address);

    /**
     * @notice Get the infrastructure fee collector
     */
    function getInfraFeeAccount() external view returns (address);

    /**
     * @notice Get the Brotli compression level used for fast compression
     */
    function getBrotliCompressionLevel() external view returns (uint64);

    /**
     * @notice Get the next scheduled ArbOS version upgrade and its activation timestamp.
     * @notice Returns (0, 0) if no ArbOS upgrade is scheduled.
     * @notice Available in ArbOS version 20.
     */
    function getScheduledUpgrade() external view returns (uint64 arbosVersion, uint64 scheduledForTimestamp);

    // TODO Write NatSpec comment
    function getSharePrice() external view returns (uint64);

    // TODO Write NatSpec comment
    function getShareCount() external view returns (uint256);

    // TODO Write NatSpec comment
    function getApy() external view returns (uint64);
}
