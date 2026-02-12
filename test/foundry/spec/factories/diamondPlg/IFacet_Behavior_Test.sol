// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import "forge-std/Test.sol";
// import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {Behavior_IFacet} from "@crane/contracts/factories/diamondPkg/Behavior_IFacet.sol";

interface Behavior_IFacet_Good {
    function func0() external;

    function func1() external;

    function func2() external;
}

interface Behavior_IFacet_Bad {
    function funcBad() external;
}

contract Behavior_Stub_IFacet_Good is Behavior_IFacet_Good, IFacet {
    function func0() external {}

    function func1() external {}

    function func2() external {}

    function facetName() public pure virtual returns (string memory name) {
        return type(Behavior_Stub_IFacet_Good).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(Behavior_IFacet_Good).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = Behavior_IFacet_Good.func0.selector;
        facetFuncs_[1] = Behavior_IFacet_Good.func1.selector;
        facetFuncs_[2] = Behavior_IFacet_Good.func2.selector;
    }

    function facetMetadata()
        public
        pure
        virtual
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}

contract Behavior_Stub_IFacet_Bad is Behavior_IFacet_Bad, IFacet {
    function funcBad() external {}

    function facetName() public pure virtual returns (string memory name) {
        return type(Behavior_Stub_IFacet_Bad).name;
    }

    function facetInterfaces() public pure virtual returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(Behavior_IFacet_Bad).interfaceId;
    }

    function facetFuncs() public pure virtual returns (bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](1);
        facetFuncs_[0] = Behavior_IFacet_Bad.funcBad.selector;
    }

    function facetMetadata()
        public
        pure
        virtual
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}

contract Behavior_Stub_IFacet_Bad_Complex is Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad {

    function facetName() public pure virtual override(Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad) returns (string memory name) {
        return type(Behavior_Stub_IFacet_Bad_Complex).name;
    }

    function facetInterfaces()
        public
        pure
        virtual
        override(Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad)
        returns (bytes4[] memory facetInterfaces_)
    {
        facetInterfaces_ = new bytes4[](2);
        facetInterfaces_[0] = type(Behavior_IFacet_Good).interfaceId;
        facetInterfaces_[1] = type(Behavior_IFacet_Bad).interfaceId;
    }

    function facetFuncs()
        public
        pure
        override(Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad)
        returns (bytes4[] memory facetFuncs_)
    {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = Behavior_IFacet_Good.func0.selector;
        facetFuncs_[1] = Behavior_IFacet_Good.func1.selector;
        facetFuncs_[2] = Behavior_IFacet_Bad.funcBad.selector;
    }

    function facetMetadata()
        public
        pure
        virtual
        override(Behavior_Stub_IFacet_Good, Behavior_Stub_IFacet_Bad)
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
}

contract Behavior_IFacet_Test is Test {
    Behavior_Stub_IFacet_Good internal _goodFacet;

    function goodFacet() public returns (IFacet goodFacet_) {
        if (address(_goodFacet) == address(0)) {
            _goodFacet = new Behavior_Stub_IFacet_Good();
        }
        goodFacet_ = _goodFacet;
    }

    Behavior_Stub_IFacet_Bad internal _badFacet;

    function badFacet() public returns (IFacet badFacet_) {
        if (address(_badFacet) == address(0)) {
            _badFacet = new Behavior_Stub_IFacet_Bad();
        }
        badFacet_ = _badFacet;
    }

    Behavior_Stub_IFacet_Bad_Complex internal _badComplexFacet;

    function badComplexFacet() public returns (IFacet badComplexFacet_) {
        if (address(_badComplexFacet) == address(0)) {
            _badComplexFacet = new Behavior_Stub_IFacet_Bad_Complex();
        }
        badComplexFacet_ = _badComplexFacet;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function IFacet_control_facetInterfaces() public pure virtual returns (bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(Behavior_IFacet_Good).interfaceId;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function IFacet_control_facetFuncs() public pure virtual returns (bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = Behavior_IFacet_Good.func0.selector;
        facetFuncs_[1] = Behavior_IFacet_Good.func1.selector;
        facetFuncs_[2] = Behavior_IFacet_Good.func2.selector;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_goodFacet() public {
        assert(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Good).name, goodFacet().facetInterfaces(), IFacet_control_facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_goodFacet() public {
        assert(
            Behavior_IFacet.areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Good).name, goodFacet().facetFuncs(), IFacet_control_facetFuncs()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_badFacet() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Bad).name, badFacet().facetInterfaces(), IFacet_control_facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_badFacet() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Bad).name, badFacet().facetFuncs(), IFacet_control_facetFuncs()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_name_badFacetComplex() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Bad_Complex).name,
                badComplexFacet().facetInterfaces(),
                IFacet_control_facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_name_badFacetComplex() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Bad_Complex).name, badComplexFacet().facetFuncs(), IFacet_control_facetFuncs()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_goodFacet() public {
        assert(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                goodFacet(), goodFacet().facetInterfaces(), IFacet_control_facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_subject_goodFacet() public {
        assert(Behavior_IFacet.areValid_IFacet_facetFuncs(goodFacet(), goodFacet().facetFuncs(), IFacet_control_facetFuncs()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_badFacet() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(badFacet(), badFacet().facetInterfaces(), IFacet_control_facetInterfaces())
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_subject_badFacet() public {
        assertFalse(Behavior_IFacet.areValid_IFacet_facetFuncs(badFacet(), badFacet().facetFuncs(), IFacet_control_facetFuncs()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetInterfaces_subject_badFacetComplex() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetInterfaces(
                badComplexFacet(), badComplexFacet().facetInterfaces(), IFacet_control_facetInterfaces()
            )
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_areValid_IFacet_facetFuncs_subject_badFacetComplex() public {
        assertFalse(
            Behavior_IFacet.areValid_IFacet_facetFuncs(badComplexFacet(), badComplexFacet().facetFuncs(), IFacet_control_facetFuncs())
        );
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_goodFacet() public {
        Behavior_IFacet.expect_IFacet_facetInterfaces(goodFacet(), IFacet_control_facetInterfaces());
        assert(Behavior_IFacet.hasValid_IFacet_facetInterfaces(goodFacet()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_goodFacet() public {
        Behavior_IFacet.expect_IFacet_facetFuncs(goodFacet(), IFacet_control_facetFuncs());
        assert(Behavior_IFacet.hasValid_IFacet_facetFuncs(goodFacet()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_badFacet() public {
        Behavior_IFacet.expect_IFacet_facetInterfaces(badFacet(), IFacet_control_facetInterfaces());
        assertFalse(Behavior_IFacet.hasValid_IFacet_facetInterfaces(badFacet()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_badFacet() public {
        Behavior_IFacet.expect_IFacet_facetFuncs(badFacet(), IFacet_control_facetFuncs());
        assertFalse(Behavior_IFacet.hasValid_IFacet_facetFuncs(badFacet()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetInterfaces_subject_badFacetComplex() public {
        Behavior_IFacet.expect_IFacet_facetInterfaces(badComplexFacet(), IFacet_control_facetInterfaces());
        assertFalse(Behavior_IFacet.hasValid_IFacet_facetInterfaces(badComplexFacet()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IFacet_hasValid_IFacet_facetFuncs_subject_badFacetComplex() public {
        Behavior_IFacet.expect_IFacet_facetFuncs(badComplexFacet(), IFacet_control_facetFuncs());
        assertFalse(Behavior_IFacet.hasValid_IFacet_facetFuncs(badComplexFacet()));
    }
}
