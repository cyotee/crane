// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.35;

import {Vm} from "forge-std/Vm.sol";

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";
import {WETH} from "../tokens/WETH.sol";
import {DSTestPlus} from "./utils/DSTestPlus.sol";
import {MockERC20} from "./utils/mocks/MockERC20.sol";
import {MockAuthChild} from "./utils/mocks/MockAuthChild.sol";

import {CREATE3} from "../utils/CREATE3.sol";

contract Factory {
    function deploy(bytes32 salt) public returns (address deployed) {
        deployed = CREATE3.deploy(
            salt, abi.encodePacked(type(MockERC20).creationCode, abi.encode("Mock Token", "MOCK", 18)), 0
        );
    }
}

contract CREATE3Test is DSTestPlus {
    using BetterEfficientHashLib for bytes;

    Vm internal constant vm = Vm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function testDeployERC20() public {
        // bytes32 salt = keccak256(bytes("A salt!"));
        bytes32 salt = bytes("A salt!")._hash();
        MockERC20 deployed = MockERC20(
            CREATE3.deploy(
                salt, abi.encodePacked(type(MockERC20).creationCode, abi.encode("Mock Token", "MOCK", 18)), 0
            )
        );

        assertEq(address(deployed), CREATE3.getDeployed(salt));

        assertEq(deployed.name(), "Mock Token");
        assertEq(deployed.symbol(), "MOCK");
        assertEq(deployed.decimals(), 18);
    }

    function testPredictDeployERC20() public {
        // bytes32 salt = keccak256(bytes("A salt!"));
        bytes32 salt = bytes("A salt!")._hash();
        Factory factory = new Factory();

        MockERC20 deployed = MockERC20(factory.deploy(salt));

        assertEq(address(deployed), CREATE3.getDeployed(salt, address(factory)));
        assertTrue(address(deployed) != CREATE3.getDeployed(salt));

        assertEq(deployed.name(), "Mock Token");
        assertEq(deployed.symbol(), "MOCK");
        assertEq(deployed.decimals(), 18);
    }

    function test_RevertWhen_DoubleDeploySameBytecode() public {
        // bytes32 salt = keccak256(bytes("Salty..."));
        bytes32 salt = bytes("Salty...")._hash();

        CREATE3.deploy(salt, type(MockAuthChild).creationCode, 0);
        vm.expectRevert();
        CREATE3.deploy(salt, type(MockAuthChild).creationCode, 0);
    }

    function test_RevertWhen_DoubleDeployDifferentBytecode() public {
        // bytes32 salt = keccak256(bytes("and sweet!"));
        bytes32 salt = bytes("and sweet!")._hash();

        CREATE3.deploy(salt, type(WETH).creationCode, 0);
        vm.expectRevert();
        CREATE3.deploy(salt, type(MockAuthChild).creationCode, 0);
    }

    function testDeployERC20(bytes32 salt, string calldata name, string calldata symbol, uint8 decimals) public {
        MockERC20 deployed = MockERC20(
            CREATE3.deploy(salt, abi.encodePacked(type(MockERC20).creationCode, abi.encode(name, symbol, decimals)), 0)
        );

        assertEq(address(deployed), CREATE3.getDeployed(salt));

        assertEq(deployed.name(), name);
        assertEq(deployed.symbol(), symbol);
        assertEq(deployed.decimals(), decimals);
    }

    function test_RevertWhen_DoubleDeploySameBytecode(bytes32 salt, bytes calldata bytecode) public {
        // The CREATE3 proxy address depends only on the salt, so once a salt is used the
        // proxy CREATE2 collides and any redeploy at that salt reverts (DEPLOYMENT_FAILED)
        // before the creation code runs. Seed the salt with a known-good deployment first,
        // since arbitrary fuzzed creation code may not deploy successfully.
        CREATE3.deploy(salt, type(MockAuthChild).creationCode, 0);
        vm.expectRevert();
        CREATE3.deploy(salt, bytecode, 0);
    }

    function test_RevertWhen_DoubleDeployDifferentBytecode(
        bytes32 salt,
        bytes calldata,
        /* bytecode1 */
        bytes calldata bytecode2
    ) public {
        // Same salt-based collision as above; the second deploy reverts before executing
        // its creation code, so the fuzzed bytecode need not be valid creation code.
        CREATE3.deploy(salt, type(WETH).creationCode, 0);
        vm.expectRevert();
        CREATE3.deploy(salt, bytecode2, 0);
    }
}
