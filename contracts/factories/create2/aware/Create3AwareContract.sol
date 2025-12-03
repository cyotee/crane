// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Bytecode} from "contracts/utils/Bytecode.sol";
import {ICreate2Aware} from "contracts/interfaces/ICreate2Aware.sol";
import {ICreate3Aware} from "contracts/interfaces/ICreate3Aware.sol";

contract Create3AwareContract is ICreate3Aware {
    address public immutable ORIGIN;

    bytes32 public constant INITCODE_HASH = Bytecode.CREATE3_PROXY_INITCODEHASH;

    bytes32 public immutable SALT;

    /**
     * @notice The initialization data of the contract.
     */
    bytes public initData;

    constructor(CREATE3InitData memory create3InitData) {
        ORIGIN = msg.sender;
        SALT = create3InitData.salt;
        initData = create3InitData.initData;
    }

    /**
     * @inheritdoc ICreate2Aware
     */
    function METADATA() public view returns (CREATE2Metadata memory) {
        return CREATE2Metadata({origin: ORIGIN, initcodeHash: INITCODE_HASH, salt: SALT});
    }
}
