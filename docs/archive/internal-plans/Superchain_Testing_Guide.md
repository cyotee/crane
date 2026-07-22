Here is a consolidated, up-to-date summary of the **entire workflow** for your cross-chain vault system using the **native Standard Bridge** on Ethereum ↔ Base. This incorporates all corrections and refinements from our discussion (e.g., accurate contract addresses, single `_minGasLimit` parameter for `depositERC20To`, measurement-based gas constants, Foundry testing derivation, etc.). All addresses and processes reflect the current OP Stack / Base setup as of March 2026.

### Phase 0: Initial Token Setup (Permissionless, One-Time)
These steps enable canonical bridging of **your own ERC20** (the underlying reserve asset).

1. Deploy your standard ERC20 token on **Ethereum mainnet** (or Sepolia for testing).  
   - Verify on Etherscan.  
   - Record address: `L1_TOKEN_ADDRESS`.

2. Deploy the canonical bridged representation on **Base** using the pre-deployed factory:  
   - **Base mainnet OptimismMintableERC20Factory**: `0xF10122D428B4bc8A9d050D06a2037259b4c4B83B`  
   - **Base Sepolia**: `0x4200000000000000000000000000000000000012`  
   - Call `createStandardERC20` (or equivalent `createMintableERC20`):  
     - `_remoteToken`: `L1_TOKEN_ADDRESS`  
     - Name, symbol, decimals matching L1 token.  
   - Record returned address: `L2_TOKEN_ADDRESS` (canonical mintable ERC20 on Base).  
   - Verify on Basescan.

3. (Recommended) Submit token to Superchain token list:  
   - PR to https://github.com/ethereum-optimism/ethereum-optimism.github.io  
   - Add folder with `logo.svg` (SVG, square, 256x256 preferred) + `data.json` (metadata + L1/L2 addresses).

### Phase 1: Deploy Your Custom Contracts (Order Matters)
Deploy first on **Sepolia** (Ethereum Sepolia + Base Sepolia), test fully, then repeat on mainnet.

1. Deploy **Base Vault** on Base:  
   - ERC4626-style vault.  
   - Internal/protected `deposit` / `mintShares` function (callable only by Processor).  
   - Record: `BASE_VAULT_ADDRESS`.

2. Deploy **Processor** (intermediary handler) on Base:  
   - Receives minted tokens + relayed message atomically.  
   - Constructor or setter: pass `BASE_VAULT_ADDRESS` + L2CrossDomainMessenger (`0x4200000000000000000000000000000000000007`).  
   - Implement handler function (e.g., `handleMessage` or similar) with:  
     - `onlyFromMessenger` check.  
     - Verify sender is your L1 Vault.  
     - Transfer minted tokens to Base Vault.  
     - Call Base Vault mint → shares to recipient.  
   - Record: `PROCESSOR_ADDRESS`.

3. Deploy **Ethereum Vault** (L1) on Ethereum:  
   - ERC4626-style vault + new function `bridgeToBaseVault(uint256 shares, address recipientOnBase)`.  
   - Constructor/setter: pass  
     - L1StandardBridge: `0x3154Cf16ccdb4C6d922629664174b904d80F2C35` (mainnet)  
     - L1CrossDomainMessenger: `0x866E82a600A1414e583f7F13623F1aC5d58b0Afa` (mainnet)  
     - `L1_TOKEN_ADDRESS`, `L2_TOKEN_ADDRESS`, `PROCESSOR_ADDRESS`.  
   - Hardcode safe gas constants (measured + 20% buffer):  
     - `DEPOSIT_MIN_GAS_LIMIT` ≈ 250,000 (for `depositERC20To` mint).  
     - `PROCESSOR_MIN_GAS_LIMIT` ≈ 400,000–600,000 (for your Processor logic).

### Phase 2: Workflow (User Experience)
User interacts **only once** on Ethereum:

1. User calls `bridgeToBaseVault(shares, recipientOnBase)` on Ethereum Vault (single tx).  
2. Ethereum Vault (in same tx):  
   - Burn/lock shares proportionally.  
   - Withdraw underlying tokens from reserve.  
   - Approve L1StandardBridge.  
   - Call `depositERC20To(  
       _l1Token: L1_TOKEN_ADDRESS,  
       _l2Token: L2_TOKEN_ADDRESS,  
       _to: PROCESSOR_ADDRESS,  
       _amount,  
       _minGasLimit: DEPOSIT_MIN_GAS_LIMIT,  
       _extraData: ""  
     )` — mints tokens to Processor on Base.  
   - Immediately call `sendMessage(  
       _target: PROCESSOR_ADDRESS,  
       _message: abi.encode(recipientOnBase, amount, nonce),  
       _minGasLimit: PROCESSOR_MIN_GAS_LIMIT  
     )` — relays custom data.  

3. ~1–5 min later (Base finalization): **One atomic L2 tx**  
   - L2StandardBridge mints canonical tokens to Processor.  
   - L2CrossDomainMessenger relays message → calls Processor handler.  
4. Processor:  
   - Verifies origin (L1 Vault).  
   - Transfers tokens to Base Vault.  
   - Calls Base Vault mint → shares to recipient.

### Phase 3: Testing in Foundry (Pure Multi-Fork or Supersim)
Use **pure Foundry multi-fork** (fork Ethereum + Base state):

1. In `setUp()`:  
   - `l1Fork = vm.createSelectFork(ethereumRPC, blockNumber);`  
   - `baseFork = vm.createSelectFork(baseRPC, matchingBlockNumber);`

2. Deploy contracts on respective forks.

3. Test function (on L1 fork):  
   - Fund user, approve, call `bridgeToBaseVault`.  
   - Record pre-call nonce from L1CrossDomainMessenger.  
   - Derive relay params: `_nonce` (pre-call nonce), `_sender` (Ethereum Vault), `_target` (Processor), `_value` 0, `_minGasLimit` (your constant), `_message` (your encoded payload).

4. Switch to Base fork:  
   - Compute aliased L1 messenger: `AddressAliasHelper.applyL1ToL2Alias(L1CrossDomainMessenger)`.  
   - `vm.prank(aliasedAddress);`  
   - Call `L2CrossDomainMessenger.relayMessage(_nonce, _sender, _target, _value, _minGasLimit, _message)`.  
   - (For mint simulation: prank mint tokens to Processor or relay bridge's internal message if full realism needed.)  
   - Assert: tokens transferred, shares minted, events emitted, no reverts.

**Alternative**: Use **Supersim** for automatic relay simulation (forks + relays deposits/messages natively). Install from ethereum-optimism/supersim, run with fork flags, use its local RPCs.

### Key Gas Constants Recap
- `DEPOSIT_MIN_GAS_LIMIT` (depositERC20To): Measure `finalizeBridgeERC20` gas on Base fork → +20% buffer → ~250,000 safe default.  
- `PROCESSOR_MIN_GAS_LIMIT` (sendMessage): Measure Processor handler gas → +20% → ~400,000–600,000 typical.

This is the complete, self-contained, permissionless setup. No third-party bridges, no approvals, atomic on Base. Test thoroughly on Sepolia forks first.

If any address or step needs double-checking during your deployment, let me know the specifics!