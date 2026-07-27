// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    Create2Utils,
    Create2UtilsWrapper
} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/deployments/libraries/Create2UtilsWrapper.sol";
import {Create2TestHelper} from "@crane/test/foundry/spec/protocols/lending/aave/v4/utils/Create2TestHelper.sol";
import {
    TransparentUpgradeableProxy
} from "@crane/contracts/external/openzeppelin-contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract Dummy {
    constructor() {}
}

contract Create2UtilsTest is Create2TestHelper {
    Create2UtilsWrapper internal _create2UtilsWrapper;

    function setUp() public {
        _create2UtilsWrapper = new Create2UtilsWrapper();
    }

    /// @notice Path B when Path A is empty: real CREATE (or BC Deployer) factory — never etch at 0x914d.
    function testCreate2Deploy_pathB_realFactoryWhenPathAMissing() public {
        assertEq(Create2Utils.CREATE2_FACTORY.code.length, 0, "Path A empty precondition");

        address factory = _create2UtilsWrapper.ensureCreate2Factory();
        assertTrue(factory.code.length > 0, "Path B factory has code");
        assertTrue(factory != Create2Utils.CREATE2_FACTORY, "Path B must not be the empty Path A address");
        // Proves we did not etch the canonical Safe Singleton address.
        assertEq(Create2Utils.CREATE2_FACTORY.code.length, 0, "must not etch Path A");

        bytes32 salt = bytes32(uint256(1));
        bytes memory bytecode = type(Dummy).creationCode;
        address deployed = _create2UtilsWrapper.create2Deploy(salt, bytecode);
        assertTrue(deployed.code.length > 0, "CREATE2 deploy succeeded after Path B");
        assertEq(
            deployed,
            _create2UtilsWrapper.computeCreate2Address(salt, keccak256(bytecode), factory),
            "CREATE2 address uses Path B factory"
        );
        assertEq(_create2UtilsWrapper.getFactory(), factory, "getFactory resolves Path B");
    }

    function testCreate2Deploy_revertsWith_create2AddressDerivationFailure(bytes32 salt) public {
        vm.assume(salt != bytes32(0));
        vm.etch(
            Create2Utils.CREATE2_FACTORY,
            hex"600060005260206000f3" // runtime: mstore(0,0); return(0,32)
        );
        bytes memory bytecode = type(Dummy).creationCode;
        vm.expectRevert(Create2Utils.Create2AddressDerivationFailure.selector);
        _create2UtilsWrapper.create2Deploy(salt, bytecode);
    }

    function testCreate2Deploy_revertsWith_failedCreate2FactoryCall(bytes32 salt) public {
        vm.assume(salt != bytes32(0));
        _etchCreate2Factory();
        bytes memory bytecode = hex"fd";
        vm.expectRevert(Create2Utils.FailedCreate2FactoryCall.selector);
        _create2UtilsWrapper.create2Deploy(salt, bytecode);
    }

    function testCreate2Deploy_revertsWith_contractAlreadyDeployed(bytes32 salt) public {
        vm.assume(salt != bytes32(0));
        _etchCreate2Factory();
        bytes memory bytecode = type(Dummy).creationCode;
        _create2UtilsWrapper.create2Deploy(salt, bytecode);

        // after already deployed, it should now revert
        vm.expectRevert(Create2Utils.ContractAlreadyDeployed.selector);
        _create2UtilsWrapper.create2Deploy(salt, bytecode);
    }

    function testCreate2Deploy_fuzz(bytes32 salt) public {
        vm.assume(salt != bytes32(0));
        _etchCreate2Factory();
        bytes memory bytecode = type(Dummy).creationCode;

        assertEq(
            _create2UtilsWrapper.create2Deploy(salt, bytecode),
            _create2UtilsWrapper.computeCreate2Address(salt, keccak256(bytecode))
        );
    }

    function testProxify_fuzz(bytes32 salt, address initialOwner) public {
        vm.assume(salt != bytes32(0));
        vm.assume(initialOwner != address(0));
        _etchCreate2Factory();
        address logic = address(new Dummy());
        bytes memory initData = bytes("");
        assertEq(
            _create2UtilsWrapper.proxify(salt, logic, initialOwner, initData),
            _create2UtilsWrapper.computeCreate2Address(
                salt,
                keccak256(
                    abi.encodePacked(
                        type(TransparentUpgradeableProxy).creationCode, abi.encode(logic, initialOwner, initData)
                    )
                )
            )
        );
    }

    function testIsContractDeployed_fuzz(address addr) public view {
        vm.assume(addr != address(0));
        assumeUnusedAddress(addr);
        assertFalse(_create2UtilsWrapper.isContractDeployed(addr));
    }

    function testIsContractDeployed() public {
        address deployed = address(new Dummy());
        assertTrue(_create2UtilsWrapper.isContractDeployed(deployed));
    }

    function testComputeCreate2Address_fuzz(bytes32 salt, bytes32 initcode) public view {
        vm.assume(salt != bytes32(0));
        vm.assume(initcode != bytes32(0));
        address expected = _create2UtilsWrapper.computeCreate2Address(salt, initcode);
        assertEq(_create2UtilsWrapper.computeCreate2Address(salt, initcode), expected);
    }

    function testComputeCreate2Address_fuzz(bytes32 salt, bytes memory bytecode) public view {
        vm.assume(salt != bytes32(0));
        vm.assume(bytecode.length > 0);
        address expected = _create2UtilsWrapper.computeCreate2Address(salt, keccak256(abi.encodePacked(bytecode)));
        assertEq(_create2UtilsWrapper.computeCreate2Address(salt, bytecode), expected);
    }

    function testAddressFromLast20Bytes_fuzz(bytes32 bytesValue) public view {
        vm.assume(bytesValue != bytes32(0));
        assertEq(_create2UtilsWrapper.addressFromLast20Bytes(bytesValue), address(uint160(uint256(bytesValue))));
    }
}
