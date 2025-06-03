// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { Bytecode } from "../../../utils/Bytecode.sol";
import { ICreate2Aware } from "../../../interfaces/ICreate2Aware.sol";
import { ICreate3Aware } from "../../../interfaces/ICreate3Aware.sol";

contract Create3AwareContract is ICreate3Aware {

    address public immutable ORIGIN;

    bytes32 public constant INITCODE_HASH = Bytecode.CREATE3_PROXY_INITCODEHASH;

    bytes32 public immutable SALT;

    /**
     * @notice The initialization data of the contract.
     */
    bytes public initData;

    constructor(bytes memory initData_) {
        ORIGIN = msg.sender;
        CREATE3InitData memory decodedInitData = abi.decode(initData_, (CREATE3InitData));
        SALT = decodedInitData.salt;
        initData = decodedInitData.initData;
    }

    /**
     * @inheritdoc ICreate2Aware
     */
    function METADATA()
    public view returns(CREATE2Metadata memory) {
        return CREATE2Metadata({
            origin: ORIGIN,
            initcodeHash: INITCODE_HASH,
            salt: SALT
        });
    }

}