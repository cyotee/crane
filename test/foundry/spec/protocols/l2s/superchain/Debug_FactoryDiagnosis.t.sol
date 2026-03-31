// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// @notice Debug test to diagnose the factory issue
contract Debug_FactoryDiagnosis is Test {

    uint256 internal constant L2_FORK_BLOCK = 24_666_122;
    uint256 internal l2Fork;
    string internal constant L2_RPC_URL = "base_mainnet_infura";

    address internal constant FACTORY = 0xF10122D428B4bc8A9d050D06a2037259b4c4B83B;

    function setUp() public {
        l2Fork = vm.createFork(L2_RPC_URL, L2_FORK_BLOCK);
        vm.selectFork(l2Fork);
    }

    /// @notice Diagnose what contract is at the factory address
    function test_DiagnoseContract() public view {
        console.log("=== Contract Diagnosis ===");
        console.log("Factory address:", FACTORY);
        console.log("Code length:", FACTORY.code.length);
        
        // Try to get the first 4 bytes of the code to identify it
        bytes memory code = FACTORY.code;
        console.log("First 32 bytes:");
        for (uint i = 0; i < 32 && i < code.length; i++) {
            console.logBytes1(code[i]);
        }
    }

    /// @notice Try calling with maximum gas
    function test_MaxGas() public {
        console.log("=== Testing with different gas amounts ===");
        
        // Try with different gas amounts
        uint256[] memory gasAmounts = new uint256[](5);
        gasAmounts[0] = 100000;
        gasAmounts[1] = 500000;
        gasAmounts[2] = 1000000;
        gasAmounts[3] = 3000000;
        gasAmounts[4] = 10000000;
        
        for (uint i = 0; i < gasAmounts.length; i++) {
            (bool success, ) = FACTORY.call{ gas: gasAmounts[i] }(
                abi.encodeWithSignature(
                    "createStandardOptimismMintableERC20(address,string,string,uint8)",
                    address(0x1234),
                    "TST",
                    "TST",
                    18
                )
            );
            console.log("Gas:", gasAmounts[i], "Success:", success);
        }
    }

    /// @notice Try calling with a valid L1 token address
    function test_WithRealL1Token() public {
        // Try with a real L1 token that might already be bridged
        // Using a common token address
        address l1Token = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; // USDC on Ethereum
        
        console.log("Trying with L1 token:", l1Token);
        
        (bool success, bytes memory data) = FACTORY.call{ gas: 3000000 }(
            abi.encodeWithSignature(
                "createStandardOptimismMintableERC20(address,string,string,uint8)",
                l1Token,
                "Test Token",
                "TST",
                18
            )
        );
        
        console.log("Success:", success);
        if (success) {
            console.log("Token address:", abi.decode(data, (address)));
        } else {
            console.logBytes(data);
        }
    }
}
