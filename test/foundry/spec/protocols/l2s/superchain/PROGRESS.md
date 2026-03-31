# Superchain Token Transfer Relayer Test Progress

## Overview

Implementing a Foundry integration test for TokenTransferRelayer cross-chain flow using Optimism Superchain (L1 Ethereum → L2 Base).

## Test Files Created

### Main Test File
- `test/foundry/spec/protocols/l2s/superchain/TokenTransferRelayer_Superchain.t.sol` (627 lines)
  - Main integration test contract
  - TestBase with dual-fork setup (L1 Ethereum + L2 Base)
  - Mock contracts: TestERC20, TestERC4626Vault, TestTokenTransferRelayer, TestApprovedMessageSenderRegistry

### Debug Test Files (temporary)
- `test/foundry/spec/protocols/l2s/superchain/Debug_OptimismMintableERC20Factory.t.sol`
- `test/foundry/spec/protocols/l2s/superchain/Debug_FactoryError.t.sol`
- `test/foundry/spec/protocols/l2s/superchain/Debug_FactoryDiagnosis.t.sol`

## What Was Implemented

1. **TestERC20** - Full ERC20 mock with mint capability
2. **TestERC4626Vault** - Complete ERC4626 vault implementation with deposit/mint/withdraw/redeem
3. **TestTokenTransferRelayer** - Relayer mock with registry validation
4. **TestApprovedMessageSenderRegistry** - Message sender approval registry
5. **TestBase_SuperchainTokenTransferRelayer** - Abstract base with dual-fork setup using network constants
6. **Test Cases**:
   - `test_BridgeAndRelay_Success` - Main cross-chain flow
   - `test_UnauthorizedSender_Reverted` - Negative test
   - `test_ReplayProtection` - Stub for replay protection
   - `test_InsufficientGas` - Stub for gas requirements
   - `test_Setup_Configuration` - Configuration display

## Current Error Being Debugged

### Issue: IOptimismMintableERC20 mint not found

```
Error (9582): Member "mint" not found or not found or not visible after argument-dependent lookup in contract IOptimismMintableERC20.
```

**Location**: Line 544 in TokenTransferRelayer_Superchain.t.sol

**Context**: The test is calling `IOptimismMintableERC20(address(l2Token)).mint(relayer, depositAmount)` to simulate the bridge minting L2 tokens to the relayer.

**Fix Applied**: Added `mint` and `burn` functions to the `IOptimismMintableERC20` interface definition in the test file.

### User Feedback: L1 Token Should Be Minted First

The user corrected me: The test should mint the L1 token first, then bridge to L2 - not mint L2 tokens directly.

**Current test flow (wrong)**:
1. L1: alice transfers to bridge
2. L2: impersonate bridge to mint L2 tokens to relayer

**Correct test flow**:
1. L1: mint L1 tokens to alice (already done in setUpL1)
2. L1: alice bridges via L1StandardBridge (lock tokens)
3. L2: impersonate bridge to mint L2 tokens to relayer (representing the bridged tokens)

### Next Steps

1. Run the test after adding mint/burn to interface
2. Verify the L1 token is minted first (before bridging)
3. Clean up debug test files
4. Ensure all tests pass

## Key Addresses Used

### Ethereum Mainnet (L1)
- L1CrossDomainMessenger: `0x866E82a600A1414e583f7F13623F1aC5d58b0Afa`
- L1StandardBridge: `0x3154Cf16ccdb4C6d922629664174b904d80F2C35`

### Base Mainnet (L2)
- L2CrossDomainMessenger: `0x4200000000000000000000000000000000000007`
- L2StandardBridge: `0x4200000000000000000000000000000010`
- OptimismMintableERC20Factory: `0xF10122D428B4bc8A9d050D06a2037259b4c4B83B`

## Lessons Learned

1. **Wrong function name**: Initially used `createStandardOptimismMintableERC20` - correct function is `createOptimismMintableERC20` (no "Standard" in name)

2. **Factory access control**: The OptimismMintableERC20Factory requires specific permissions - works in tests but factory deployment itself succeeds

3. **Token access control**: The deployed OptimismMintableERC20 only allows the bridge to mint - need to impersonate the aliased bridge address to mint tokens

4. **Fork block**: L2_FORK_BLOCK in test was using wrong value - should use `BASE_MAIN.DEFAULT_FORK_BLOCK`
