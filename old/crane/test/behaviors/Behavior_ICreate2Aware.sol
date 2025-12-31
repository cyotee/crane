// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import {betterconsole as console} from "contracts/crane/utils/vm/foundry/tools/betterconsole.sol";
import {BetterAddress as Address} from "contracts/crane/utils/BetterAddress.sol";
import {Bytes32} from "@crane/src/utils/Bytes32.sol";
import {BetterStrings as Strings} from "contracts/crane/utils/BetterStrings.sol";
import {UInt256} from "contracts/crane/utils/UInt256.sol";
import {Behavior} from "contracts/crane/test/behaviors/Behavior.sol";
import {ICreate2Aware} from "contracts/crane/interfaces/ICreate2Aware.sol";

/**
 * @title Behavior_ICreate2Aware
 * @notice Behavior contract for testing ICreate2Aware implementations
 * @dev Validates that contracts correctly implement the ICreate2Aware interface
 *      by checking ORIGIN, INITCODE_HASH, SALT, and CREATE2Metadata
 */
contract Behavior_ICreate2Aware is Behavior {
    /* ---------------------------- Library Usage --------------------------- */
    using Address for address;
    using Bytes32 for bytes32;
    using Strings for string;
    using UInt256 for uint256;

    /* ------------------------- State Variables ---------------------------- */
    // Storage for expectations
    mapping(address subject => mapping(bytes4 selector => address expectedOrigin)) private _expectedOrigins;
    mapping(address subject => mapping(bytes4 selector => bytes32 expectedHash)) private _expectedHashes;
    mapping(address subject => mapping(bytes4 selector => bytes32 expectedSalt)) private _expectedSalts;
    mapping(address subject => mapping(bytes4 selector => ICreate2Aware.CREATE2Metadata expectedMetadata)) private
        _expectedMetadata;

    /* ------------------------- Helper Functions --------------------------- */
    /// forge-lint: disable-next-line(mixed-case-function)
    function _ic2a_behaviorName() internal pure returns (string memory) {
        return type(Behavior_ICreate2Aware).name;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ic2a_errPrefixFunc(string memory testedFuncSig) internal view virtual returns (string memory) {
        return _errPrefixFunc(_ic2a_behaviorName(), testedFuncSig);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ic2a_errPrefix(string memory testedFuncSig, string memory subjectLabel)
        internal
        view
        virtual
        returns (string memory)
    {
        return string.concat(_ic2a_errPrefixFunc(testedFuncSig), subjectLabel);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function _ic2a_errPrefix(string memory testedFuncSig, address subject)
        internal
        view
        virtual
        returns (string memory)
    {
        return _ic2a_errPrefix(testedFuncSig, vm.getLabel(subject));
    }

    /* ---------------------------- ORIGIN() ------------------------------ */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_ICreate2Aware_ORIGIN() public pure returns (string memory) {
        return "ORIGIN()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_ICreate2Aware_ORIGIN() public pure returns (string memory) {
        return "origin address";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_ICreate2Aware_ORIGIN(string memory subjectLabel, address expected, address actual)
        public
        view
        returns (bool isValid)
    {
        console.logBehaviorEntry(_ic2a_behaviorName(), "isValid_ICreate2Aware_ORIGIN");

        isValid = expected == actual;
        if (!isValid) {
            console.logBehaviorError(
                _ic2a_behaviorName(),
                "isValid_ICreate2Aware_ORIGIN",
                _ic2a_errPrefix(funcSig_ICreate2Aware_ORIGIN(), subjectLabel),
                errSuffix_ICreate2Aware_ORIGIN()
            );
            console.logBehaviorCompare(_ic2a_behaviorName(), "isValid_ICreate2Aware_ORIGIN", "origin", expected, actual);
        }

        console.logBehaviorValidation(_ic2a_behaviorName(), "isValid_ICreate2Aware_ORIGIN", "origin", isValid);

        console.logBehaviorExit(_ic2a_behaviorName(), "isValid_ICreate2Aware_ORIGIN");
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_ICreate2Aware_ORIGIN(ICreate2Aware subject, address expected, address actual)
        public
        view
        returns (bool)
    {
        return isValid_ICreate2Aware_ORIGIN(vm.getLabel(address(subject)), expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_ICreate2Aware_ORIGIN(ICreate2Aware subject, address expected) public {
        console.logBehaviorEntry(_ic2a_behaviorName(), "expect_ICreate2Aware_ORIGIN");

        console.logBehaviorExpectation(
            _ic2a_behaviorName(), "expect_ICreate2Aware_ORIGIN", "origin", vm.getLabel(expected)
        );

        _expectedOrigins[address(subject)][ICreate2Aware.ORIGIN.selector] = expected;

        console.logBehaviorExit(_ic2a_behaviorName(), "expect_ICreate2Aware_ORIGIN");
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_ICreate2Aware_ORIGIN(ICreate2Aware subject) public view returns (address) {
        return _expectedOrigins[address(subject)][ICreate2Aware.ORIGIN.selector];
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_ICreate2Aware_ORIGIN(ICreate2Aware subject) public view returns (bool) {
        console.logBehaviorEntry(_ic2a_behaviorName(), "hasValid_ICreate2Aware_ORIGIN");

        bool isValid = isValid_ICreate2Aware_ORIGIN(subject, expected_ICreate2Aware_ORIGIN(subject), subject.ORIGIN());

        console.logBehaviorValidation(_ic2a_behaviorName(), "hasValid_ICreate2Aware_ORIGIN", "origin", isValid);

        console.logBehaviorExit(_ic2a_behaviorName(), "hasValid_ICreate2Aware_ORIGIN");
        return isValid;
    }

    /* -------------------------- INITCODE_HASH() --------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_ICreate2Aware_INITCODE_HASH() public pure returns (string memory) {
        return "INITCODE_HASH()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_ICreate2Aware_INITCODE_HASH() public pure returns (string memory) {
        return "initcode hash";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_ICreate2Aware_INITCODE_HASH(string memory subjectLabel, bytes32 expected, bytes32 actual)
        public
        view
        returns (bool isValid)
    {
        console.logBehaviorEntry(_ic2a_behaviorName(), "isValid_ICreate2Aware_INITCODE_HASH");

        isValid = expected == actual;
        if (!isValid) {
            console.logBehaviorError(
                _ic2a_behaviorName(),
                "isValid_ICreate2Aware_INITCODE_HASH",
                _ic2a_errPrefix(funcSig_ICreate2Aware_INITCODE_HASH(), subjectLabel),
                errSuffix_ICreate2Aware_INITCODE_HASH()
            );
            console.logBehaviorCompare(
                _ic2a_behaviorName(), "isValid_ICreate2Aware_INITCODE_HASH", "initcode hash", expected, actual
            );
        }

        console.logBehaviorValidation(
            _ic2a_behaviorName(), "isValid_ICreate2Aware_INITCODE_HASH", "initcode hash", isValid
        );

        console.logBehaviorExit(_ic2a_behaviorName(), "isValid_ICreate2Aware_INITCODE_HASH");
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_ICreate2Aware_INITCODE_HASH(ICreate2Aware subject, bytes32 expected, bytes32 actual)
        public
        view
        returns (bool)
    {
        return isValid_ICreate2Aware_INITCODE_HASH(vm.getLabel(address(subject)), expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_ICreate2Aware_INITCODE_HASH(ICreate2Aware subject, bytes32 expected) public {
        console.logBehaviorEntry(_ic2a_behaviorName(), "expect_ICreate2Aware_INITCODE_HASH");

        console.logBehaviorExpectation(
            _ic2a_behaviorName(), "expect_ICreate2Aware_INITCODE_HASH", "initcode hash", uint256(expected).toHexString()
        );

        _expectedHashes[address(subject)][ICreate2Aware.INITCODE_HASH.selector] = expected;

        console.logBehaviorExit(_ic2a_behaviorName(), "expect_ICreate2Aware_INITCODE_HASH");
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_ICreate2Aware_INITCODE_HASH(ICreate2Aware subject) public view returns (bytes32) {
        return _expectedHashes[address(subject)][ICreate2Aware.INITCODE_HASH.selector];
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_ICreate2Aware_INITCODE_HASH(ICreate2Aware subject) public view returns (bool) {
        console.logBehaviorEntry(_ic2a_behaviorName(), "hasValid_ICreate2Aware_INITCODE_HASH");

        bool isValid = isValid_ICreate2Aware_INITCODE_HASH(
            subject, expected_ICreate2Aware_INITCODE_HASH(subject), subject.INITCODE_HASH()
        );

        console.logBehaviorValidation(
            _ic2a_behaviorName(), "hasValid_ICreate2Aware_INITCODE_HASH", "initcode hash", isValid
        );

        console.logBehaviorExit(_ic2a_behaviorName(), "hasValid_ICreate2Aware_INITCODE_HASH");
        return isValid;
    }

    /* -------------------------------- SALT() ----------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_ICreate2Aware_SALT() public pure returns (string memory) {
        return "SALT()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_ICreate2Aware_SALT() public pure returns (string memory) {
        return "salt value";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_ICreate2Aware_SALT(string memory subjectLabel, bytes32 expected, bytes32 actual)
        public
        view
        returns (bool isValid)
    {
        isValid = expected == actual;
        if (!isValid) {
            console.log(
                string.concat(
                    _ic2a_errPrefix(funcSig_ICreate2Aware_SALT(), subjectLabel),
                    " UNEXPECTED ",
                    errSuffix_ICreate2Aware_SALT()
                )
            );
            console.logBytes32(expected);
            console.logBytes32(actual);
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function isValid_ICreate2Aware_SALT(ICreate2Aware subject, bytes32 expected, bytes32 actual)
        public
        view
        returns (bool)
    {
        return isValid_ICreate2Aware_SALT(vm.getLabel(address(subject)), expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_ICreate2Aware_SALT(ICreate2Aware subject, bytes32 expected) public {
        _expectedSalts[address(subject)][ICreate2Aware.SALT.selector] = expected;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_ICreate2Aware_SALT(ICreate2Aware subject) public view returns (bytes32) {
        return _expectedSalts[address(subject)][ICreate2Aware.SALT.selector];
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_ICreate2Aware_SALT(ICreate2Aware subject) public view returns (bool) {
        return isValid_ICreate2Aware_SALT(subject, expected_ICreate2Aware_SALT(subject), subject.SALT());
    }

    /* ------------------------------ METADATA() ---------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function funcSig_ICreate2Aware_METADATA() public pure returns (string memory) {
        return "METADATA()";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function errSuffix_ICreate2Aware_METADATA() public pure returns (string memory) {
        return "metadata struct";
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_ICreate2Aware_METADATA(
        string memory subjectLabel,
        ICreate2Aware.CREATE2Metadata memory expected,
        ICreate2Aware.CREATE2Metadata memory actual
    ) public view returns (bool isValid) {
        isValid = expected.origin == actual.origin && expected.initcodeHash == actual.initcodeHash
            && expected.salt == actual.salt;

        if (!isValid) {
            console.log(
                string.concat(
                    _ic2a_errPrefix(funcSig_ICreate2Aware_METADATA(), subjectLabel),
                    " UNEXPECTED ",
                    errSuffix_ICreate2Aware_METADATA()
                )
            );
            console.log("Expected origin:", expected.origin);
            console.log("Actual origin:", actual.origin);
            console.log("Expected initcodeHash:");
            console.logBytes32(expected.initcodeHash);
            console.log("Actual initcodeHash:");
            console.logBytes32(actual.initcodeHash);
            console.log("Expected salt:");
            console.logBytes32(expected.salt);
            console.log("Actual salt:");
            console.logBytes32(actual.salt);
        }
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function areValid_ICreate2Aware_METADATA(
        ICreate2Aware subject,
        ICreate2Aware.CREATE2Metadata memory expected,
        ICreate2Aware.CREATE2Metadata memory actual
    ) public view returns (bool) {
        return areValid_ICreate2Aware_METADATA(vm.getLabel(address(subject)), expected, actual);
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expect_ICreate2Aware_METADATA(ICreate2Aware subject, ICreate2Aware.CREATE2Metadata memory expected)
        public
    {
        _expectedMetadata[address(subject)][ICreate2Aware.METADATA.selector] = expected;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_ICreate2Aware_METADATA(ICreate2Aware subject)
        public
        view
        returns (ICreate2Aware.CREATE2Metadata memory)
    {
        return _expectedMetadata[address(subject)][ICreate2Aware.METADATA.selector];
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_ICreate2Aware_METADATA(ICreate2Aware subject) public view returns (bool) {
        return areValid_ICreate2Aware_METADATA(subject, expected_ICreate2Aware_METADATA(subject), subject.METADATA());
    }

    /* ---------------------------- Full Interface -------------------------- */

    /// forge-lint: disable-next-line(mixed-case-function)
    function hasValid_ICreate2Aware(ICreate2Aware subject) public view returns (bool) {
        console.logBehaviorEntry(_ic2a_behaviorName(), "hasValid_ICreate2Aware");

        bool isValid = hasValid_ICreate2Aware_ORIGIN(subject) && hasValid_ICreate2Aware_INITCODE_HASH(subject)
            && hasValid_ICreate2Aware_SALT(subject) && hasValid_ICreate2Aware_METADATA(subject);

        console.logBehaviorValidation(_ic2a_behaviorName(), "hasValid_ICreate2Aware", "full interface", isValid);

        console.logBehaviorExit(_ic2a_behaviorName(), "hasValid_ICreate2Aware");
        return isValid;
    }
}
