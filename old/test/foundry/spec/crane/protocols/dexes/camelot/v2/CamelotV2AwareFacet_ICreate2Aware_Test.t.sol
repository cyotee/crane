// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import { console } from "forge-std/console.sol";

// import { Test_Crane } from "contracts/crane/test/Test_Crane.sol";
// import { Script_Crane } from "contracts/crane/script/Script_Crane.sol";
// Base test contracts
import {TestBase_ICreate2Aware} from "contracts/crane/test/bases/TestBase_ICreate2Aware.sol";
// import { TestBase_Indexedex } from "contracts/crane/test/bases/TestBase_Indexedex.sol";

// Target contracts
import {ICreate2Aware} from "contracts/crane/interfaces/ICreate2Aware.sol";
import {CamelotV2AwareFacet} from "contracts/crane/protocols/dexes/camelot/v2/CamelotV2AwareFacet.sol";
// import "contracts/crane/constants/Indexedex_INITCODE.sol";
import {CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH} from "contracts/crane/constants/CraneINITCODE.sol";

contract CamelotV2AwareFacet_ICreate2Aware_Test is TestBase_ICreate2Aware {
    // CamelotV2AwareFacet public camelotV2AwareFacetInstance;

    // address controlOrigin_;
    // bytes32 controlInitCodeHash_;
    // bytes32 controlSalt_;

    function setUp() public override(TestBase_ICreate2Aware) {
        super.setUp();
        // camelotV2AwareFacetInstance = camelotV2AwareFacet();

        // controlOrigin_ = address(factory());
        // controlInitCodeHash_ = CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH;
        // controlSalt_ = keccak256(abi.encode(type(CamelotV2AwareFacet).name));
    }

    function run() public override(TestBase_ICreate2Aware) {
        // super.run(); // Comment out for performance - don't deploy unnecessary components
    }

    // --- Implementation of TestBase_ICreate2Aware ---

    function create2TestInstance() public override returns (ICreate2Aware) {
        return ICreate2Aware(address(camelotV2AwareFacet()));
    }

    function controlOrigin() public override returns (address) {
        return address(factory());
    }

    function controlInitCodeHash() public pure override returns (bytes32) {
        return CAMELOT_V2_AWARE_FACET_INIT_CODE_HASH;
    }

    function controlSalt() public pure override returns (bytes32) {
        return keccak256(abi.encode(type(CamelotV2AwareFacet).name));
    }
}
