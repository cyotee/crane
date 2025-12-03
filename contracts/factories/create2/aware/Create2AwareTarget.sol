// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {ICreate2Aware} from "contracts/interfaces/ICreate2Aware.sol";

/**
 * @title Create2AwareTarget
 * @author cyotee doge <doge.cyotee>
 * @notice A target contract that implements the ICreate2Aware interface.
 * @notice Intended to be used with a callback factory to retrieve metadata.
 * @dev Inherit this contract to declare the CREATE2 metadata for a contract.
 */
contract Create2AwareTarget is ICreate2Aware {
    /**
     * @inheritdoc ICreate2Aware
     */
    address public immutable ORIGIN;

    /**
     * @inheritdoc ICreate2Aware
     */
    bytes32 public immutable INITCODE_HASH;

    /**
     * @inheritdoc ICreate2Aware
     */
    bytes32 public immutable SALT;

    /**
     * @inheritdoc ICreate2Aware
     */
    function METADATA() public view returns (CREATE2Metadata memory) {
        return CREATE2Metadata({origin: ORIGIN, initcodeHash: INITCODE_HASH, salt: SALT});
    }
}
