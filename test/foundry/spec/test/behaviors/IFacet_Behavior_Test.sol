// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

import { CraneTest } from "../../../../../contracts/test/CraneTest.sol";
import { IFacet } from "../../../../../contracts/interfaces/IFacet.sol";

interface IFacet_Behavior_Good {

    function func0() external;

    function func1() external;

    function func2() external;

}

interface IFacet_Behavior_Bad {

    function funcBad() external;

}


contract Behavior_Stub_IFacet_Good
is
IFacet_Behavior_Good,
IFacet
{
    function func0() external {}

    function func1() external {}

    function func2() external {}

    function facetInterfaces()
    external pure virtual
    returns(bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(IFacet_Behavior_Good).interfaceId;
    }

    function facetFuncs()
    external pure virtual
    returns(bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = IFacet_Behavior_Good.func0.selector;
        facetFuncs_[1] = IFacet_Behavior_Good.func1.selector;
        facetFuncs_[2] = IFacet_Behavior_Good.func2.selector;
    }

}

contract Behavior_Stub_IFacet_Bad
is
IFacet_Behavior_Bad,
IFacet
{
    function funcBad() external {}

    function facetInterfaces()
    external pure virtual
    returns(bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(IFacet_Behavior_Bad).interfaceId;
    }

    function facetFuncs()
    external pure virtual
    returns(bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](1);
        facetFuncs_[0] = IFacet_Behavior_Bad.funcBad.selector;
    }
}

contract Behavior_Stub_IFacet_Bad_Complex
is
Behavior_Stub_IFacet_Good,
Behavior_Stub_IFacet_Bad
{

    function facetInterfaces()
    external pure virtual
    override(
        Behavior_Stub_IFacet_Good,
        Behavior_Stub_IFacet_Bad
    )
    returns(bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](2);
        facetInterfaces_[0] = type(IFacet_Behavior_Good).interfaceId;   
        facetInterfaces_[1] = type(IFacet_Behavior_Bad).interfaceId;
    }

    function facetFuncs()
    external pure
    override(
        Behavior_Stub_IFacet_Good,
        Behavior_Stub_IFacet_Bad
    )
    returns(bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = IFacet_Behavior_Good.func0.selector;
        facetFuncs_[1] = IFacet_Behavior_Good.func1.selector;
        facetFuncs_[2] = IFacet_Behavior_Bad.funcBad.selector;
    }
}

contract IFacet_Behavior_Test
is
CraneTest
{
    Behavior_Stub_IFacet_Good internal _goodFacet;

    function goodFacet() public returns(IFacet goodFacet_) {
        if(address(_goodFacet) == address(0)) {
            _goodFacet = new Behavior_Stub_IFacet_Good();
        }
        goodFacet_ = _goodFacet;
    }

    Behavior_Stub_IFacet_Bad internal _badFacet;

    function badFacet() public returns(IFacet badFacet_) {
        if(address(_badFacet) == address(0)) {
            _badFacet = new Behavior_Stub_IFacet_Bad();
        }
        badFacet_ = _badFacet;
    }
    
    Behavior_Stub_IFacet_Bad_Complex internal _badComplexFacet;

    function badComplexFacet() public returns(IFacet badComplexFacet_) {
        if(address(_badComplexFacet) == address(0)) {
            _badComplexFacet = new Behavior_Stub_IFacet_Bad_Complex();
        }
        badComplexFacet_ = _badComplexFacet;
    }


    function IFacet_control_facetInterfaces()
    public pure virtual
    returns(bytes4[] memory facetInterfaces_) {
        facetInterfaces_ = new bytes4[](1);
        facetInterfaces_[0] = type(IFacet_Behavior_Good).interfaceId;
    }

    function IFacet_control_facetFuncs()
    public pure virtual
    returns(bytes4[] memory facetFuncs_) {
        facetFuncs_ = new bytes4[](3);
        facetFuncs_[0] = IFacet_Behavior_Good.func0.selector;
        facetFuncs_[1] = IFacet_Behavior_Good.func1.selector;
        facetFuncs_[2] = IFacet_Behavior_Good.func2.selector;
    }


    function setUp() public virtual override {
        // super.setUp();
    }

    function test_IFacet_Behavior_areValid_IFacet_facetInterfaces_name_goodFacet() public {
        assert(
            areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Good).name,
                goodFacet().facetInterfaces(),
                IFacet_control_facetInterfaces()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetFuncs_name_goodFacet() public {
        assert(
            areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Good).name,
                goodFacet().facetFuncs(),
                IFacet_control_facetFuncs()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetInterfaces_name_badFacet() public {
        assertFalse(
            areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Bad).name,
                badFacet().facetInterfaces(),
                IFacet_control_facetInterfaces()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetFuncs_name_badFacet() public {
        assertFalse(
            areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Bad).name,
                badFacet().facetFuncs(),
                IFacet_control_facetFuncs()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetInterfaces_name_badFacetComplex() public {
        assertFalse(
            areValid_IFacet_facetInterfaces(
                type(Behavior_Stub_IFacet_Bad_Complex).name,
                badComplexFacet().facetInterfaces(),
                IFacet_control_facetInterfaces()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetFuncs_name_badFacetComplex() public {
        assertFalse(
            areValid_IFacet_facetFuncs(
                type(Behavior_Stub_IFacet_Bad_Complex).name,
                badComplexFacet().facetFuncs(),
                IFacet_control_facetFuncs()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetInterfaces_subject_goodFacet() public {
        assert(
            areValid_IFacet_facetInterfaces(
                goodFacet(),
                goodFacet().facetInterfaces(),
                IFacet_control_facetInterfaces()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetFuncs_subject_goodFacet() public {
        assert(
            areValid_IFacet_facetFuncs(
                goodFacet(),
                goodFacet().facetFuncs(),
                IFacet_control_facetFuncs()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetInterfaces_subject_badFacet() public {
        assertFalse(
            areValid_IFacet_facetInterfaces(
                badFacet(),
                badFacet().facetInterfaces(),
                IFacet_control_facetInterfaces()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetFuncs_subject_badFacet() public {
        assertFalse(
            areValid_IFacet_facetFuncs(
                badFacet(),
                badFacet().facetFuncs(),
                IFacet_control_facetFuncs()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetInterfaces_subject_badFacetComplex() public {
        assertFalse(
            areValid_IFacet_facetInterfaces(
                badComplexFacet(),
                badComplexFacet().facetInterfaces(),
                IFacet_control_facetInterfaces()
            )
        );
    }

    function test_IFacet_Behavior_areValid_IFacet_facetFuncs_subject_badFacetComplex() public {
        assertFalse(
            areValid_IFacet_facetFuncs(
                badComplexFacet(),
                badComplexFacet().facetFuncs(),
                IFacet_control_facetFuncs()
            )
        );
    }

    function test_IFacet_Behavior_hasValid_IFacet_facetInterfaces_subject_goodFacet() public {
        expect_IFacet_facetInterfaces(
            goodFacet(),
            IFacet_control_facetInterfaces()
        );
        assert(
            hasValid_IFacet_facetInterfaces(
                goodFacet()
            )
        );
    }

    function test_IFacet_Behavior_hasValid_IFacet_facetFuncs_subject_goodFacet() public {
        expect_IFacet_facetFuncs(
            goodFacet(),
            IFacet_control_facetFuncs()
        );
        assert(
            hasValid_IFacet_facetFuncs(
                goodFacet()
            )
        );
    }

    function test_IFacet_Behavior_hasValid_IFacet_facetInterfaces_subject_badFacet() public {
        expect_IFacet_facetInterfaces(
            badFacet(),
            IFacet_control_facetInterfaces()
        );
        assertFalse(
            hasValid_IFacet_facetInterfaces(
                badFacet()
            )
        );
    }

    function test_IFacet_Behavior_hasValid_IFacet_facetFuncs_subject_badFacet() public {
        expect_IFacet_facetFuncs(
            badFacet(),
            IFacet_control_facetFuncs()
        );
        assertFalse(
            hasValid_IFacet_facetFuncs(
                badFacet()
            )
        );
    }

    function test_IFacet_Behavior_hasValid_IFacet_facetInterfaces_subject_badFacetComplex() public {
        expect_IFacet_facetInterfaces(
            badComplexFacet(),
            IFacet_control_facetInterfaces()
        );
        assertFalse(
            hasValid_IFacet_facetInterfaces(
                badComplexFacet()
            )
        );
    }
    
    function test_IFacet_Behavior_hasValid_IFacet_facetFuncs_subject_badFacetComplex() public {
        expect_IFacet_facetFuncs(
            badComplexFacet(),
            IFacet_control_facetFuncs()
        );
        assertFalse(
            hasValid_IFacet_facetFuncs(
                badComplexFacet()
            )
        );
    }   
    
}