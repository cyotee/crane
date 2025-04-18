// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title ICreate2CallbackContract
 * @author cyotee doge <doge.cyotee>
 * @notice Allows a contract to expose it's initialization data.
 */
interface ICreate2CallbackContract {

    /**
     * @return The initialization data of the contract.
     */
    function initData() external view returns(bytes memory);

}
