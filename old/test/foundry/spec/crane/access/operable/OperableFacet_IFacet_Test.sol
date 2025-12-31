// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// import {Test_Crane} from "contracts/crane/test/Test_Crane.sol";
import {IFacet} from "contracts/crane/interfaces/IFacet.sol";
import {IOperable} from "contracts/crane/interfaces/IOperable.sol";
// import {OperableFacet} from "contracts/crane/access/operable/OperableFacet.sol";
import {TestBase_IFacet} from "contracts/crane/test/bases/TestBase_IFacet.sol";

contract OperableFacet_IFacet_Test is TestBase_IFacet {
    function facetTestInstance() public virtual override returns (IFacet) {
        return operableFacet();
    }

    function controlFacetInterfaces() public view virtual override returns (bytes4[] memory controlInterfaces) {
        controlInterfaces = new bytes4[](1);
        controlInterfaces[0] = type(IOperable).interfaceId;
        return controlInterfaces;
    }

    function controlFacetFuncs() public view virtual override returns (bytes4[] memory controlFuncs) {
        controlFuncs = new bytes4[](4);
        controlFuncs[0] = IOperable.isOperator.selector;
        controlFuncs[1] = IOperable.isOperatorFor.selector;
        controlFuncs[2] = IOperable.setOperator.selector;
        controlFuncs[3] = IOperable.setOperatorFor.selector;
        return controlFuncs;
    }

    // function test_IFacet_facetInterfaces_OperableFacet() public {
    //     bytes4[] memory expectedInterfaces = new bytes4[](1);
    //     expectedInterfaces[0] = type(IOperable).interfaceId;

    //     expect_IFacet_facetInterfaces(
    //         IFacet(address(operableFacet())),
    //         expectedInterfaces
    //     );

    //     assertTrue(
    //         hasValid_IFacet_facetInterfaces(
    //             IFacet(address(operableFacet()))
    //         ),
    //         "OperableFacet should expose correct interface IDs"
    //     );
    // }

    // function test_IFacet_facetFuncs_OperableFacet() public {
    //     bytes4[] memory expectedFuncs = new bytes4[](4);
    //     expectedFuncs[0] = IOperable.isOperator.selector;
    //     expectedFuncs[1] = IOperable.isOperatorFor.selector;
    //     expectedFuncs[2] = IOperable.setOperator.selector;
    //     expectedFuncs[3] = IOperable.setOperatorFor.selector;

    //     expect_IFacet_facetFuncs(
    //         IFacet(address(operableFacet())),
    //         expectedFuncs
    //     );

    //     assertTrue(
    //         hasValid_IFacet_facetFuncs(
    //             IFacet(address(operableFacet()))
    //         ),
    //         "OperableFacet should expose correct function selectors"
    //     );
    // }
}
