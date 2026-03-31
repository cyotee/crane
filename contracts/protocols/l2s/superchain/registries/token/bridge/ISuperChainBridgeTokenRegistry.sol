// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from '@crane/contracts/interfaces/IERC20.sol';

/**
 * @title ISuperChainBridgeTokenRegistry
 * @notice Personal registry of SuperChain bridge remote tokens and their associated minimum gas limits for bridging.
 * @notice Remote token refers to the target token on another chain.
 * @notice When bridging, recipients receive the remote token.
 * @notice There is no canonical bridge token registry for the SuperChain.
 * @notice There is also no limit on the number of remote tokens.
 */
interface ISuperChainBridgeTokenRegistry {

    /**
     * @notice Get the remote token and minimum gas limit for a given local token and destination chain.
     * @param chainId The destination chain ID.
     * @param localToken The local token address.
     * @return remoteToken The remote token address.
     */
    function getRemoteToken(uint256 chainId, IERC20 localToken) external view returns (IERC20 remoteToken);

    /**
     * @notice Get the minimum gas limit for a given remote token and destination chain.
     * @param chainId The destination chain ID.
     * @param remoteToken The remote token address.
     * @return minGasLimit The minimum gas limit for bridging the remote token to the destination chain.
     */
    function getMinGasLimit(uint256 chainId, IERC20 remoteToken) external view returns (uint256 minGasLimit);

    /**
     * @notice Get the remote token and minimum gas limit for a given local token and destination chain.
     * @param chainId The destination chain ID.
     * @param localToken The local token address.
     * @return remoteToken The remote token address.
     * @return minGasLimit The minimum gas limit for bridging the local token to the remote token.
     */
    function getRemoteTokenAndLimit(uint256 chainId, IERC20 localToken) external view returns (IERC20 remoteToken, uint256 minGasLimit);

    /**
     * @notice Set the remote token and minimum gas limit for a given local token and destination chain.
     * @param chainId The destination chain ID.
     * @param localToken The local token address.
     * @param remoteToken The remote token address.
     * @param minGasLimit The minimum gas limit for bridging the local token to the remote token.
     * @return True if the remote token and minimum gas limit were successfully set, false otherwise.
     */
    function setRemoteToken(uint256 chainId, IERC20 localToken, IERC20 remoteToken, uint256 minGasLimit) external returns (bool);

    /**
     * @notice Set the minimum gas limit for a given remote token and destination chain.
     * @param chainId The destination chain ID.
     * @param remoteToken The remote token address.
     * @param minGasLimit The minimum gas limit for bridging the remote token to the destination chain.
     * @return True if the minimum gas limit was successfully set, false otherwise.
     */
    function setRemoteTokenMinGasLimit(uint256 chainId, IERC20 remoteToken, uint256 minGasLimit) external returns (bool);
}