// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// @notice Debug test to diagnose OptimismMintableERC20Factory call
contract Debug_OptimismMintableERC20Factory is Test {

    uint256 internal constant L2_FORK_BLOCK = 24_666_122;
    uint256 internal l2Fork;
    string internal constant L2_RPC_URL = "base_mainnet_infura";

    address internal constant FACTORY = 0xF10122D428B4bc8A9d050D06a2037259b4c4B83B;

    function setUp() public {
        l2Fork = vm.createFork(L2_RPC_URL, L2_FORK_BLOCK);
        vm.selectFork(l2Fork);
    }

    /// @notice Try calling with high gas
    function test_CallWithHighGas() public {
        // Try calling with very high gas
        (bool success, bytes memory data) = FACTORY.call{ gas: 5000000 }(
            abi.encodeWithSignature("createStandardOptimismMintableERC20(address,string,string,uint8)",
                address(0x1234567890123456789012345678901234567890),
                "Test Token",
                "TST", 
                18
            )
        );
        
        console.log("High gas call success:", success);
        if (!success) {
            console.log("Error:");
            console.logBytes(data);
        } else {
            console.log("Token address:", abi.decode(data, (address)));
        }
    }

    /// @notice Try a simple view call to see if the contract responds at all
    function test_SimpleViewCall() public view {
        // Try calling a view function that should exist on every contract
        (bool success, bytes memory data) = FACTORY.staticcall(abi.encodeWithSignature("version()"));
        console.log("version() success:", success);
        if (success) {
            console.logBytes(data);
        }
        
        (success, data) = FACTORY.staticcall(abi.encodeWithSignature("name()"));
        console.log("name() success:", success);
        if (success) {
            console.logBytes(data);
        }
    }
}
