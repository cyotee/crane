// SPDX-License-Identifier: MIT
pragma solidity >=0.8.24;

import {ReEnablerGracePeriodTestBase} from "@crane/test/foundry/spec/protocols/tokens/stable/olympus/v2/bases/ReEnablerGracePeriod/ReEnablerGracePeriodTestBase.sol";

// Interfaces
import {IERC165} from "@crane/contracts/external/openzeppelin-contracts-v5/interfaces/IERC165.sol";
import {IEnabler} from "@crane/contracts/protocols/tokens/stable/olympus/v2/periphery/interfaces/IEnabler.sol";
import {IEnablerV2} from "@crane/contracts/protocols/tokens/stable/olympus/v2/bases/interfaces/IEnablerV2.sol";
import {IGracePeriod} from "@crane/contracts/protocols/tokens/stable/olympus/v2/bases/interfaces/IGracePeriod.sol";
import {IReEnabler} from "@crane/contracts/protocols/tokens/stable/olympus/v2/bases/interfaces/IReEnabler.sol";

// Libraries
import {ERC165Helper} from "@crane/test/foundry/spec/protocols/tokens/stable/olympus/v2/lib/ERC165.sol";

/// @dev Tests for `ReEnablerGracePeriod.supportsInterface`. The mix-in must advertise its
///      own interface identifier in addition to every identifier inherited from
///      `ReEnabler` and `EnablerV2`.
contract ReEnablerGracePeriodTests_SupportsInterface is ReEnablerGracePeriodTestBase {
    function test_supportsInterface_validatesIERC165Self() external view {
        ERC165Helper.validateSupportsInterface(address(harness));
    }

    function test_supportsInterface_returnsTrueForIERC165() external view {
        assertTrue(harness.supportsInterface(type(IERC165).interfaceId), "IERC165 not advertised");
    }

    function test_supportsInterface_returnsTrueForIEnabler() external view {
        assertTrue(
            harness.supportsInterface(type(IEnabler).interfaceId),
            "IEnabler not advertised"
        );
    }

    function test_supportsInterface_returnsTrueForIEnablerV2() external view {
        assertTrue(
            harness.supportsInterface(type(IEnablerV2).interfaceId),
            "IEnablerV2 not advertised"
        );
    }

    function test_supportsInterface_returnsTrueForIReEnabler() external view {
        assertTrue(
            harness.supportsInterface(type(IReEnabler).interfaceId),
            "IReEnabler not advertised"
        );
    }

    function test_supportsInterface_returnsTrueForIGracePeriod() external view {
        assertTrue(
            harness.supportsInterface(type(IGracePeriod).interfaceId),
            "IGracePeriod not advertised"
        );
    }

    function test_supportsInterface_returnsFalseForUnknownInterface() external view {
        assertFalse(harness.supportsInterface(bytes4(0xffffffff)), "sentinel must be unsupported");
        assertFalse(harness.supportsInterface(bytes4(0x12345678)), "arbitrary id must be false");
    }
}
