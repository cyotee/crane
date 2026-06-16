// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ITokenizationSpoke} from "@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ITokenizationSpoke.sol";
import {ISpoke} from "@crane/contracts/protocols/lending/aave/v4/spoke/interfaces/ISpoke.sol";
import {EIP712Hash} from "@crane/contracts/protocols/lending/aave/v4/spoke/libraries/EIP712Hash.sol";
import {Test} from "forge-std/Test.sol";
import {EIP712Types} from "@crane/test/foundry/spec/protocols/lending/aave/v4/helpers/mocks/EIP712Types.sol";

contract EIP712HashTest is Test {
    using EIP712Hash for *;

    function test_constants() public pure {
        assertEq(
            EIP712Hash.SET_USER_POSITION_MANAGERS_TYPEHASH,
            keccak256(
                "SetUserPositionManagers(address onBehalfOf,PositionManagerUpdate[] updates,uint256 nonce,uint256 deadline)PositionManagerUpdate(address positionManager,bool approve)"
            )
        );
        assertEq(EIP712Hash.SET_USER_POSITION_MANAGERS_TYPEHASH, vm.eip712HashType(EIP712Types.TYPE_SetUserPositionManagers));

        assertEq(
            EIP712Hash.POSITION_MANAGER_UPDATE, keccak256("PositionManagerUpdate(address positionManager,bool approve)")
        );
        assertEq(EIP712Hash.POSITION_MANAGER_UPDATE, vm.eip712HashType(EIP712Types.TYPE_PositionManagerUpdate));

        assertEq(
            EIP712Hash.TOKENIZED_DEPOSIT_TYPEHASH,
            keccak256(
                "TokenizedDeposit(address depositor,uint256 assets,address receiver,uint256 nonce,uint256 deadline)"
            )
        );
        assertEq(EIP712Hash.TOKENIZED_DEPOSIT_TYPEHASH, vm.eip712HashType(EIP712Types.TYPE_TokenizedDeposit));

        assertEq(
            EIP712Hash.TOKENIZED_MINT_TYPEHASH,
            keccak256("TokenizedMint(address depositor,uint256 shares,address receiver,uint256 nonce,uint256 deadline)")
        );
        assertEq(EIP712Hash.TOKENIZED_MINT_TYPEHASH, vm.eip712HashType(EIP712Types.TYPE_TokenizedMint));

        assertEq(
            EIP712Hash.TOKENIZED_WITHDRAW_TYPEHASH,
            keccak256("TokenizedWithdraw(address owner,uint256 assets,address receiver,uint256 nonce,uint256 deadline)")
        );
        assertEq(EIP712Hash.TOKENIZED_WITHDRAW_TYPEHASH, vm.eip712HashType(EIP712Types.TYPE_TokenizedWithdraw));

        assertEq(
            EIP712Hash.TOKENIZED_REDEEM_TYPEHASH,
            keccak256("TokenizedRedeem(address owner,uint256 shares,address receiver,uint256 nonce,uint256 deadline)")
        );
        assertEq(EIP712Hash.TOKENIZED_REDEEM_TYPEHASH, vm.eip712HashType(EIP712Types.TYPE_TokenizedRedeem));
    }

    function test_hash_setUserPositionManagers_fuzz(ISpoke.SetUserPositionManagers calldata params) public pure {
        bytes32[] memory updatesHashes = new bytes32[](params.updates.length);
        for (uint256 i = 0; i < updatesHashes.length; ++i) {
            updatesHashes[i] = params.updates[i].hash();
        }

        bytes32 expectedHash = keccak256(
            abi.encode(
                EIP712Hash.SET_USER_POSITION_MANAGERS_TYPEHASH,
                params.onBehalfOf,
                keccak256(abi.encodePacked(updatesHashes)),
                params.nonce,
                params.deadline
            )
        );

        assertEq(params.hash(), expectedHash);
        assertEq(params.hash(), vm.eip712HashStruct(EIP712Types.TYPE_SetUserPositionManagers, abi.encode(params)));
    }

    function test_hash_positionManagerUpdate_fuzz(ISpoke.PositionManagerUpdate calldata params) public pure {
        bytes32 expectedHash =
            keccak256(abi.encode(EIP712Hash.POSITION_MANAGER_UPDATE, params.positionManager, params.approve));

        assertEq(params.hash(), expectedHash);
        assertEq(params.hash(), vm.eip712HashStruct(EIP712Types.TYPE_PositionManagerUpdate, abi.encode(params)));
    }

    function test_hash_tokenizedDeposit_fuzz(ITokenizationSpoke.TokenizedDeposit calldata params) public pure {
        bytes32 expectedHash = keccak256(abi.encode(EIP712Hash.TOKENIZED_DEPOSIT_TYPEHASH, params));
        assertEq(params.hash(), expectedHash);
        assertEq(params.hash(), vm.eip712HashStruct(EIP712Types.TYPE_TokenizedDeposit, abi.encode(params)));
    }

    function test_hash_tokenizedMint_fuzz(ITokenizationSpoke.TokenizedMint calldata params) public pure {
        bytes32 expectedHash = keccak256(abi.encode(EIP712Hash.TOKENIZED_MINT_TYPEHASH, params));
        assertEq(params.hash(), expectedHash);
        assertEq(params.hash(), vm.eip712HashStruct(EIP712Types.TYPE_TokenizedMint, abi.encode(params)));
    }

    function test_hash_tokenizedWithdraw_fuzz(ITokenizationSpoke.TokenizedWithdraw calldata params) public pure {
        bytes32 expectedHash = keccak256(abi.encode(EIP712Hash.TOKENIZED_WITHDRAW_TYPEHASH, params));
        assertEq(params.hash(), expectedHash);
        assertEq(params.hash(), vm.eip712HashStruct(EIP712Types.TYPE_TokenizedWithdraw, abi.encode(params)));
    }

    function test_hash_tokenizedRedeem_fuzz(ITokenizationSpoke.TokenizedRedeem calldata params) public pure {
        bytes32 expectedHash = keccak256(abi.encode(EIP712Hash.TOKENIZED_REDEEM_TYPEHASH, params));
        assertEq(params.hash(), expectedHash);
        assertEq(params.hash(), vm.eip712HashStruct(EIP712Types.TYPE_TokenizedRedeem, abi.encode(params)));
    }
}
