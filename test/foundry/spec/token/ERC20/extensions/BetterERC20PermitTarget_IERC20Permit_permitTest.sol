// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./BetterERC20PermitTargetTest.sol";
import "forge-std/console.sol";

/**
 * @title BetterERC20PermitTarget_IERC20Permit_permitTest
 * @dev Test suite for the permit function of BetterERC20PermitTarget
 */
contract BetterERC20PermitTarget_IERC20Permit_permitTest is BetterERC20PermitTargetTest {
    // Test variables
    uint256 ownerPrivateKey;
    address owner;
    address spender;
    uint256 value;
    uint256 deadline;
    
    function setUp() public override {
        super.setUp();
        
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);
        spender = address(0xCAFE);
        value = 1e18;
        deadline = block.timestamp + 1 hours;
    }
    
    function test_IERC20Permit_permit() public {
        // Check initial allowance is zero
        assertEq(token.allowance(owner, spender), 0);
        
        // Get the current nonce
        uint256 nonce = token.nonces(owner);
        
        // Create the message hash to sign
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                nonce,
                deadline
            )
        );
        
        // Get the domain separator
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        
        // Create the digest to sign
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );
        
        // Create signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        
        // Call permit
        token.permit(owner, spender, value, deadline, v, r, s);
        
        // Check allowance was updated
        assertEq(token.allowance(owner, spender), value);
        
        // Check nonce was incremented
        assertEq(token.nonces(owner), nonce + 1);
    }
    
    function test_IERC20Permit_permit_ExpiredDeadline() public {
        // Set deadline in the past
        uint256 expiredDeadline = block.timestamp - 1;
        
        // Get the current nonce
        uint256 nonce = token.nonces(owner);
        
        // Create the message hash to sign
        bytes32 structHash = keccak256(
            abi.encode(
                keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                owner,
                spender,
                value,
                nonce,
                expiredDeadline
            )
        );
        
        // Get the domain separator
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        
        // Create the digest to sign
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );
        
        // Create signature
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        
        // Expect revert due to expired deadline
        vm.expectRevert();
        token.permit(owner, spender, value, expiredDeadline, v, r, s);
    }
} 