// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.35;

/// @notice Port of `lib/frax-solidity/src/hardhat/test/Fraxoracle/StateRootOracle.js` (operator quorum).
/// @dev Full `proofStateRoot` + RLP header encoding needs `eth_getBlock` JSON; covered via fork integration separately.

import {Test} from "forge-std/Test.sol";
import {OperatorBlockhashProvider} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/provider/OperatorBlockhashProvider.sol";
import {StateRootOracle} from "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/StateRootOracle.sol";
import {IBlockhashProvider} from
    "@crane/contracts/protocols/tokens/stable/frax/Fraxoracle/interface/IBlockhashProvider.sol";

contract StateRootOracle_Test is Test {
    OperatorBlockhashProvider internal provider1;
    OperatorBlockhashProvider internal provider2;
    OperatorBlockhashProvider internal provider3;
    StateRootOracle internal stateRootOracle;

    address internal op1;
    address internal op2;
    address internal op3;

    function setUp() public {
        op1 = makeAddr("oracleOp1");
        op2 = makeAddr("oracleOp2");
        op3 = makeAddr("oracleOp3");

        provider1 = new OperatorBlockhashProvider(op1);
        provider2 = new OperatorBlockhashProvider(op2);
        provider3 = new OperatorBlockhashProvider(op3);

        IBlockhashProvider[] memory providers = new IBlockhashProvider[](3);
        providers[0] = provider1;
        providers[1] = provider2;
        providers[2] = provider3;

        stateRootOracle = new StateRootOracle(providers, 2);
    }

    function test_setupContracts() public view {
        assertTrue(address(stateRootOracle) != address(0));
    }

    function test_operators_storeBlockHash_quorum() public {
        bytes32 blockHash = blockhash(block.number);

        vm.prank(op1);
        provider1.receiveBlockHash(blockHash);
        vm.prank(op2);
        provider2.receiveBlockHash(blockHash);

        assertTrue(provider1.hashStored(blockHash));
        assertTrue(provider2.hashStored(blockHash));
        assertFalse(provider3.hashStored(blockHash));
    }
}