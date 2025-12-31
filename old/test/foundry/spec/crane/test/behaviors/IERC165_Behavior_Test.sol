// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/* -------------------------------------------------------------------------- */
/*                                Open Zeppelin                               */
/* -------------------------------------------------------------------------- */

import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/* -------------------------------------------------------------------------- */
/*                                    Crane                                   */
/* -------------------------------------------------------------------------- */

// import { Test_Crane } from "contracts/crane/test/Test_Crane.sol";
import {TestBase_IERC165} from "contracts/crane/test/bases/TestBase_IERC165.sol";

// Mock interfaces for testing
interface IERC165_Good {
    function func0() external;
    function func1() external;
}

interface IERC165_Bad {
    function funcBad() external;
}

// Good implementation stub
contract Behavior_Stub_IERC165_Good is IERC165_Good, IERC165 {
    function func0() external {}
    function func1() external {}

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165_Good).interfaceId || interfaceId == type(IERC165).interfaceId;
    }
}

// Bad implementation stub
contract Behavior_Stub_IERC165_Bad is IERC165_Bad, IERC165 {
    function funcBad() external {}

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(IERC165_Bad).interfaceId;
    }
}

contract Behavior_IERC165_Test is TestBase_IERC165 {
    Behavior_Stub_IERC165_Good internal _goodImpl;
    Behavior_Stub_IERC165_Bad internal _badImpl;

    function goodImpl() public returns (IERC165) {
        if (address(_goodImpl) == address(0)) {
            _goodImpl = new Behavior_Stub_IERC165_Good();
            declareAddr(address(_goodImpl), "Behavior_Stub_IERC165_Good");
        }
        return _goodImpl;
    }

    function badImpl() public returns (IERC165) {
        if (address(_badImpl) == address(0)) {
            _badImpl = new Behavior_Stub_IERC165_Bad();
            declareAddr(address(_badImpl), "Behavior_Stub_IERC165_Bad");
        }
        return _badImpl;
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function IERC165_control_interfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IERC165_Good).interfaceId;
        interfaces[1] = type(IERC165).interfaceId;
    }

    function setUp() public virtual override {
        // Do not call super.setUp() - Fixture functions will handle deploying needed instances
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function erc165_subject() public view virtual override returns (IERC165 subject_) {}

    /// forge-lint: disable-next-line(mixed-case-function)
    function expected_IERC165_interfaces() public view virtual override returns (bytes4[] memory expectedInterfaces_) {}

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_IERC165_supportsInterface() public virtual override {
        // hasValid_IERC165_supportsInterface(erc165_subject());
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IERC165_areValid_supportsInterface_goodImpl() public {
        expect_IERC165_supportsInterface(goodImpl(), IERC165_control_interfaces());
        assert(hasValid_IERC165_supportsInterface(goodImpl()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IERC165_areValid_supportsInterface_badImpl() public {
        expect_IERC165_supportsInterface(badImpl(), IERC165_control_interfaces());
        assertFalse(hasValid_IERC165_supportsInterface(badImpl()));
    }

    /// forge-lint: disable-next-line(mixed-case-function)
    function test_Behavior_IERC165_isValid_supportsInterface_goodImpl() public {
        assert(
            isValid_IERC165_supportsInterfaces(
                goodImpl(), true, goodImpl().supportsInterface(type(IERC165_Good).interfaceId)
            )
        );
    }

    function test_Behavior_IERC165_isValid_supportsInterface_badImpl() public {
        assertFalse(
            isValid_IERC165_supportsInterfaces(
                badImpl(), true, badImpl().supportsInterface(type(IERC165_Good).interfaceId)
            )
        );
    }
}
