// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import {console2} from "forge-std/console2.sol";
import {BCScript} from "battlechain-lib/BCScript.sol";
import {Contact} from "battlechain-lib/types/AgreementTypes.sol";

import {ICreate3FactoryProxy} from "@crane/contracts/interfaces/proxies/ICreate3FactoryProxy.sol";
import {IDiamondPackageCallBackFactory} from "@crane/contracts/interfaces/IDiamondPackageCallBackFactory.sol";
import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";

/// @notice Shared base for Crane BattleChain greenfield phase scripts.
/// @dev All product options are hardcoded in phase scripts; this base only guards and helpers.
abstract contract BCPhaseScriptBase is BCScript {
    /// @dev Foundry default msg.sender when `--sender` is omitted.
    address internal constant FOUNDRY_DEFAULT_SENDER = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;

    /// @dev Pre-greenfield Create3Factory — must never be the live bind target.
    address internal constant ABANDONED_CREATE3_FACTORY = BC_TESTNET.ABANDONED_CREATE3_FACTORY;

    string internal constant EXPLORER_BASE = "https://explorer.testnet.battlechain.com";

    ICreate3FactoryProxy public coreFactory;
    IDiamondPackageCallBackFactory public diamondFactory;
    address public weth;
    address public permit2;

    function _contacts() internal pure virtual override returns (Contact[] memory c) {
        c = new Contact[](1);
        c[0] = Contact({name: "Crane / IndexedEx Security", contact: "REPLACE_BEFORE_BROADCAST@example.com"});
    }

    function _recoveryAddress() internal view virtual override returns (address) {
        return msg.sender;
    }

    function _requireNotFoundryDefaultSender(address deployer) internal pure {
        require(
            deployer != FOUNDRY_DEFAULT_SENDER,
            "BCPhase: broadcaster is Foundry default sender; pass --sender $(cast wallet address --account deployer)"
        );
    }

    function _requireNotAbandonedFactory(address factory) internal pure {
        require(factory != address(0), "BCPhase: create3 factory is zero (set BC_TESTNET after Phase1 or use handoff)");
        require(factory != ABANDONED_CREATE3_FACTORY, "BCPhase: refused abandoned gen-1 Create3Factory");
    }

    /// @notice Bind Phase 1 surfaces from explicit addresses (FullStack handoff or post-deploy wiring).
    function _bindPhase1Addresses(
        address create3Factory_,
        address diamondFactory_,
        address weth_,
        address permit2_
    ) internal {
        _requireNotAbandonedFactory(create3Factory_);
        require(diamondFactory_ != address(0), "BCPhase: diamond factory is zero");
        require(weth_ != address(0), "BCPhase: weth is zero");
        require(permit2_ != address(0), "BCPhase: permit2 is zero");

        coreFactory = ICreate3FactoryProxy(create3Factory_);
        diamondFactory = IDiamondPackageCallBackFactory(diamondFactory_);
        weth = weth_;
        permit2 = permit2_;

        if (block.chainid == BC_TESTNET.CHAIN_ID) {
            require(address(coreFactory).code.length > 0, "BCPhase: CREATE3_FACTORY has no code");
            require(address(diamondFactory).code.length > 0, "BCPhase: DIAMOND_FACTORY has no code");
            require(weth.code.length > 0, "BCPhase: BC WETH has no code");
            require(permit2.code.length > 0, "BCPhase: Permit2 has no code");
        }
    }

    /// @notice Bind Phase 1 surfaces from BC_TESTNET greenfield constants (post-Phase-1 live update).
    /// @dev Reverts if CREATE3_FACTORY is zero or abandoned gen-1. Prefer FullStack handoff in-session.
    function _bindPhase1FromConstants() internal {
        _bindPhase1Addresses(
            BC_TESTNET.CREATE3_FACTORY,
            BC_TESTNET.DIAMOND_PACKAGE_CALLBACK_FACTORY,
            BC_TESTNET.WETH,
            BC_TESTNET.BETTER_PERMIT2
        );
    }

    function _requireCode(address target, string memory label) internal view {
        if (block.chainid == BC_TESTNET.CHAIN_ID) {
            require(target.code.length > 0, string.concat("BCPhase: no code at ", label));
        }
    }

    function _writeJsonAddr(string memory path, string memory key, address addr, bool last) internal {
        string memory comma = last ? "" : ",";
        vm.writeLine(path, string.concat('    "', key, '": "', vm.toString(addr), '"', comma));
    }

    function _writeTableRow(string memory path, string memory label, address addr) internal {
        vm.writeLine(path, string.concat("| ", label, " | `", vm.toString(addr), "` |"));
    }

    function _logDocsHandoff(string memory jsonPath, string memory tablePath, string memory runtimePath) internal pure {
        console2.log("=== Docs handoff ===");
        console2.log("JSON:", jsonPath);
        console2.log("Table:", tablePath);
        console2.log("Runtime:", runtimePath);
    }
}
