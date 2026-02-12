// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";

/**
 * @title MockFacet
 * @notice A mock facet for testing Diamond Cut operations.
 * @dev Provides deterministic function selectors for testing add/replace/remove.
 */
contract MockFacet is IFacet {
    function facetName() external pure returns (string memory) {
        return "MockFacet";
    }

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](0);
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = this.mockFunctionA.selector;
        funcs[1] = this.mockFunctionB.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = "MockFacet";
        interfaces = new bytes4[](0);
        functions = new bytes4[](2);
        functions[0] = this.mockFunctionA.selector;
        functions[1] = this.mockFunctionB.selector;
    }

    function mockFunctionA() external pure returns (uint256) {
        return 1;
    }

    function mockFunctionB() external pure returns (uint256) {
        return 2;
    }
}

/**
 * @title MockFacetV2
 * @notice A second version of MockFacet for testing Replace operations.
 */
contract MockFacetV2 is IFacet {
    function facetName() external pure returns (string memory) {
        return "MockFacetV2";
    }

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](0);
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](2);
        funcs[0] = MockFacet.mockFunctionA.selector;
        funcs[1] = MockFacet.mockFunctionB.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = "MockFacetV2";
        interfaces = new bytes4[](0);
        functions = new bytes4[](2);
        functions[0] = MockFacet.mockFunctionA.selector;
        functions[1] = MockFacet.mockFunctionB.selector;
    }

    function mockFunctionA() external pure returns (uint256) {
        return 100;
    }

    function mockFunctionB() external pure returns (uint256) {
        return 200;
    }
}

/**
 * @title MockFacetC
 * @notice A third mock facet with different functions for testing multiple facets.
 */
contract MockFacetC is IFacet {
    function facetName() external pure returns (string memory) {
        return "MockFacetC";
    }

    function facetInterfaces() external pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](0);
    }

    function facetFuncs() external pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](1);
        funcs[0] = this.mockFunctionC.selector;
    }

    function facetMetadata()
        external
        pure
        returns (string memory name, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name = "MockFacetC";
        interfaces = new bytes4[](0);
        functions = new bytes4[](1);
        functions[0] = this.mockFunctionC.selector;
    }

    function mockFunctionC() external pure returns (uint256) {
        return 3;
    }
}

/**
 * @title MockInitTarget
 * @notice A mock init target for testing initialization during diamond cut.
 */
contract MockInitTarget {
    event Initialized(uint256 value);

    uint256 public lastInitValue;

    function init(uint256 value) external {
        lastInitValue = value;
        emit Initialized(value);
    }

    function initRevert() external pure {
        revert("MockInitTarget: forced revert");
    }
}
