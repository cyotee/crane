// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {CREATE3} from "@crane/contracts/protocols/dexes/uniswap/v4/external/solmate/utils/CREATE3.sol";
import {IPoolManager} from "@crane/contracts/protocols/dexes/uniswap/v4/interfaces/IPoolManager.sol";
import {Hooks} from "@crane/contracts/protocols/dexes/uniswap/v4/libraries/Hooks.sol";
import {HookMinerCreate3} from "@crane/contracts/protocols/dexes/uniswap/v4/hooks/public/utils/HookMinerCreate3.sol";
import {MockBlankHook} from "../mocks/MockBlankHook.sol";

contract HookMinerCreate3Test is Test {
    function test_hookMinerCreate3_find() public {
        _assertHookMinerCreate3Find(uint16(Hooks.BEFORE_SWAP_FLAG), 1);
        _assertHookMinerCreate3Find(
            uint16(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_SWAP_RETURNS_DELTA_FLAG), 42
        );
        _assertHookMinerCreate3Find(
            uint16(
                Hooks.BEFORE_INITIALIZE_FLAG | Hooks.AFTER_ADD_LIQUIDITY_FLAG
                    | Hooks.AFTER_ADD_LIQUIDITY_RETURNS_DELTA_FLAG
            ),
            type(uint128).max
        );
    }

    function _assertHookMinerCreate3Find(uint16 flags, uint256 number) private {
        bytes memory creationCode = type(MockBlankHook).creationCode;
        bytes memory ctorArgs = abi.encode(IPoolManager(address(0)), number, flags);

        (address predicted, bytes32 salt) = HookMinerCreate3.find(address(this), uint160(flags), creationCode, ctorArgs);

        address deployed = CREATE3.deploy(salt, abi.encodePacked(creationCode, ctorArgs), 0);

        assertEq(deployed, predicted, "CREATE3 deploy address must match the address predicted by find()");
        assertEq(
            uint160(deployed) & HookMinerCreate3.FLAG_MASK,
            flags & HookMinerCreate3.FLAG_MASK,
            "deployed address low 14 bits must equal requested hook flags"
        );

        MockBlankHook c = MockBlankHook(deployed);
        c.forceValidateAddress();
        assertEq(c.num(), number, "deployed hook must report the constructor-supplied number");
    }

    function test_hookMinerCreate3_findWithPrefix() public {
        uint16 flags = uint16(Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG);
        uint256 number = 42;
        bytes memory creationCode = type(MockBlankHook).creationCode;
        bytes memory ctorArgs = abi.encode(IPoolManager(address(0)), number, flags);

        (address predicted, bytes32 salt) =
            HookMinerCreate3.findWithPrefix(address(this), uint160(flags), creationCode, ctorArgs, "hook-");

        address deployed = CREATE3.deploy(salt, abi.encodePacked(creationCode, ctorArgs), 0);

        assertEq(deployed, predicted, "CREATE3 deploy address must match the address predicted by findWithPrefix()");
        assertEq(
            uint160(deployed) & HookMinerCreate3.FLAG_MASK,
            flags & HookMinerCreate3.FLAG_MASK,
            "deployed address low 14 bits must equal requested hook flags"
        );
        MockBlankHook(deployed).forceValidateAddress();
    }
}
