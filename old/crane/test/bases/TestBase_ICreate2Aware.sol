// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
// import { IFacet } from "contracts/crane/interfaces/IFacet.sol";
import {Behavior_ICreate2Aware} from "contracts/crane/test/behaviors/Behavior_ICreate2Aware.sol";
import {ICreate2Aware} from "contracts/crane/interfaces/ICreate2Aware.sol";

abstract contract TestBase_ICreate2Aware is Test_Crane, Behavior_ICreate2Aware {
    // TODO Implement common test logic for ICreate2Aware implementations
    // TODO Implement test_ICreate2Aware_ORIGIN()
    // TODO Implement test_ICreate2Aware_INITCODE_HASH()
    // TODO Implement test_ICreate2Aware_SALT()
    // TODO Implement test_ICreate2Aware_CREATE2Metadata()
    // TODO Implement test_ICreate2Aware_CREATE2Metadata()

    function setUp() public virtual override(Test_Crane) {
        owner(address(this));
        // Test_Crane.setUp();
    }

    function run() public virtual override(Test_Crane) {
        // Test_Crane.run();
    }

    function create2TestInstance() public virtual returns (ICreate2Aware);

    function controlOrigin() public virtual returns (address);

    function controlInitCodeHash() public virtual returns (bytes32);

    function controlSalt() public virtual returns (bytes32);

    function controlCreate2Metadata() public virtual returns (ICreate2Aware.CREATE2Metadata memory metaData) {
        metaData.origin = controlOrigin();
        metaData.initcodeHash = controlInitCodeHash();
        metaData.salt = controlSalt();
    }

    function test_ICreate2Aware_ORIGIN() public {
        isValid_ICreate2Aware_ORIGIN(create2TestInstance(), controlOrigin(), create2TestInstance().ORIGIN());
    }

    function test_ICreate2Aware_INITCODE_HASH() public {
        isValid_ICreate2Aware_INITCODE_HASH(
            create2TestInstance(), controlInitCodeHash(), create2TestInstance().INITCODE_HASH()
        );
    }

    function test_ICreate2Aware_SALT() public {
        isValid_ICreate2Aware_SALT(create2TestInstance(), controlSalt(), create2TestInstance().SALT());
    }

    function test_ICreate2Aware_CREATE2Metadata() public {
        areValid_ICreate2Aware_METADATA(
            create2TestInstance(), controlCreate2Metadata(), create2TestInstance().METADATA()
        );
    }
}
