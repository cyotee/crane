// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";

import {BCPhaseScriptBase} from "scripts/foundry/bc/BCPhaseScriptBase.s.sol";
import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";

/// @dev Thin harness exposing base bind helpers for unit tests.
contract BCPhaseBindHarness is BCPhaseScriptBase {
    function _protocolName() internal pure override returns (string memory) {
        return "BCPhaseBindHarness";
    }

    function bindAddresses(address create3, address diamond, address weth_, address permit2_) external {
        _bindPhase1Addresses(create3, diamond, weth_, permit2_);
    }

    function bindFromConstants() external {
        _bindPhase1FromConstants();
    }
}

/// @notice Proves greenfield bind guards: refuse abandoned gen-1, refuse zero CREATE3, accept handoff.
contract BCPhaseScriptBase_Bind_Test is Test {
    BCPhaseBindHarness internal harness;

    address internal constant FAKE_CREATE3 = address(0xC3C3);
    address internal constant FAKE_DIAMOND = address(0xD1A0);
    address internal constant FAKE_WETH = address(0xEE77);
    address internal constant FAKE_PERMIT2 = address(0xB2B2);

    function setUp() public {
        harness = new BCPhaseBindHarness();
        // Local chain — code.length checks skipped except on chain 627.
        vm.etch(FAKE_CREATE3, hex"00");
        vm.etch(FAKE_DIAMOND, hex"00");
        vm.etch(FAKE_WETH, hex"00");
        vm.etch(FAKE_PERMIT2, hex"00");
    }

    function test_bindPhase1Addresses_acceptsHandoffFactories() public {
        harness.bindAddresses(FAKE_CREATE3, FAKE_DIAMOND, FAKE_WETH, FAKE_PERMIT2);
        assertEq(address(harness.coreFactory()), FAKE_CREATE3, "coreFactory from handoff");
        assertEq(address(harness.diamondFactory()), FAKE_DIAMOND, "diamondFactory from handoff");
        assertEq(harness.weth(), FAKE_WETH);
        assertEq(harness.permit2(), FAKE_PERMIT2);
    }

    function test_bindPhase1Addresses_revertsOnAbandonedGen1() public {
        vm.expectRevert(bytes("BCPhase: refused abandoned gen-1 Create3Factory"));
        harness.bindAddresses(
            BC_TESTNET.ABANDONED_CREATE3_FACTORY, FAKE_DIAMOND, FAKE_WETH, FAKE_PERMIT2
        );
    }

    function test_bindPhase1Addresses_revertsOnZeroFactory() public {
        vm.expectRevert(bytes("BCPhase: create3 factory is zero (set BC_TESTNET after Phase1 or use handoff)"));
        harness.bindAddresses(address(0), FAKE_DIAMOND, FAKE_WETH, FAKE_PERMIT2);
    }

    function test_bindPhase1FromConstants_revertsWhileCreate3Unset() public {
        // Greenfield CREATE3_FACTORY is address(0) until Phase 1 live updates constants.
        assertEq(BC_TESTNET.CREATE3_FACTORY, address(0), "precondition: greenfield CREATE3 unset");
        assertTrue(
            BC_TESTNET.CREATE3_FACTORY != BC_TESTNET.ABANDONED_CREATE3_FACTORY,
            "CREATE3_FACTORY must not equal abandoned gen-1"
        );
        vm.expectRevert(bytes("BCPhase: create3 factory is zero (set BC_TESTNET after Phase1 or use handoff)"));
        harness.bindFromConstants();
    }

    function test_abandonedConstant_isWaveAGen1() public {
        assertEq(
            BC_TESTNET.ABANDONED_CREATE3_FACTORY,
            BC_TESTNET.WAVE_A_CREATE3_FACTORY,
            "abandoned alias is Wave A gen-1"
        );
        assertEq(
            BC_TESTNET.ABANDONED_CREATE3_FACTORY,
            0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A
        );
    }
}
