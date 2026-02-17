// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

/// @notice Debug test to capture the exact factory error
contract Debug_FactoryError is Test {

    uint256 internal constant L2_FORK_BLOCK = 24_666_122;
    uint256 internal l2Fork;
    string internal constant L2_RPC_URL = "base_mainnet_infura";

    address internal constant FACTORY = 0xF10122D428B4bc8A9d050D06a2037259b4c4B83B;

    function setUp() public {
        l2Fork = vm.createFork(L2_RPC_URL, L2_FORK_BLOCK);
        vm.selectFork(l2Fork);
    }

    /// @notice Try calling factory and capture exact error
    function test_FactoryCallWithErrorCapture() public {
        // Use vm.expectRevert to capture the error
        vm.expectRevert();
        IOptimismMintableERC20Factory(FACTORY).createStandardOptimismMintableERC20(
            address(0x1234567890123456789012345678901234567890),
            "Test Token L2",
            "TSTL2",
            18
        );
    }

    /// @notice Try calling without expecting revert to see raw error
    function test_FactoryCallRaw() public {
        try IOptimismMintableERC20Factory(FACTORY).createStandardOptimismMintableERC20(
            address(0x1234567890123456789012345678901234567890),
            "Test Token L2",
            "TSTL2",
            18
        ) returns (address result) {
            console.log("Success! Token address:", result);
        } catch (bytes memory err) {
            console.log("Reverted with:");
            console.logBytes(err);
        }
    }
}

interface IOptimismMintableERC20Factory {
    function createStandardOptimismMintableERC20(
        address _remoteToken,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external returns (address);
}
