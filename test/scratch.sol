// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { Test_Crane } from "../contracts/test/Test_Crane.sol";
import { IGreeter } from "../contracts/test/stubs/greeter/IGreeter.sol";
import { GreeterStorage } from "../contracts/test/stubs/greeter/utils/GreeterStorage.sol";
import { GreeterTarget } from "../contracts/test/stubs/greeter/GreeterTarget.sol";
import { ICreate3Aware } from "../contracts/interfaces/ICreate3Aware.sol";
import { Creation } from "../contracts/utils/Creation.sol";

contract Create3Greeter
is
    GreeterTarget
{

    constructor(
        bytes memory initData
    ) {
        ICreate3Aware.CREATE3InitData memory decodedInitData = abi.decode(initData, (ICreate3Aware.CREATE3InitData));
        string memory message = abi.decode(decodedInitData.initData, (string));
        _initGreeter(message);
    }

}

contract scratch is Test_Crane {

    IGreeter greeter;

    function setUp() public override {
        // super.setUp();
        greeter = Create3Greeter(
            Creation._create3(
                abi.encodePacked(
                    type(Create3Greeter).creationCode,
                    abi.encode(
                        abi.encode(
                            ICreate3Aware.CREATE3InitData({salt: bytes32(0), initData: abi.encode("Hello, World!")})
                        )
                    )
                ),
                keccak256(abi.encode("Create3Greeter"))
            )
        );
    }

    function test() public {
        greeter.setMessage("Hello, World!");
        assertEq(greeter.getMessage(), "Hello, World!");
    }
}