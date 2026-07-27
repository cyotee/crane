# Wave B — Balancer V3 on BattleChain: runbook + X post

Single place to copy **deploy commands** and the **announcement post**.

| Item | Path |
|------|------|
| Plan | `docs/superpowers/plans/2026-07-23-bc-balancer-v3-wave-b.md` |
| Script | `scripts/foundry/Script_Promo_BC_BalancerV3.s.sol` |
| This runbook | `docs/deployment/WAVE_B_BALANCER_V3_RUNBOOK.md` |

---

## 0) Preconditions

- [ ] Wave A live on BC testnet (chain `627`): Create3Factory, diamond factory, WETH, Permit2  
  (`contracts/constants/networks/BC_TESTNET.sol`)
- [ ] Foundry account `deployer` unlocked (or use your keystore name)
- [ ] Deployer funded with BC testnet gas
- [ ] Security contact in script is **not** `REPLACE_BEFORE_BROADCAST@example.com`  
  (edit `_contacts()` in the script before public attack-mode)

### Troubleshooting: many “Transaction Failure” hashes

If explorer / forge reports many failed txs (often `deployFacet` to Create3Factory `0xC8E9…AD3A`):

| Check | What we saw |
|-------|-------------|
| Target | Create3Factory `deployFacet(bytes,bytes32)` |
| Pattern | `gasUsed / gasLimit ≈ 70%+` and status **failed** |
| Root cause | **Gas limit too low** for CREATE3 of larger facets on BattleChain |
| Evidence | eth_estimateGas for a failed Vault* facet ≈ **9–16M**; tx was sent with only **~4–7M** |
| Not the cause | Owner auth (deployer is factory owner); facet bytecode still under 24KB |

**Fix:** re-broadcast with `-g 400` (or higher). Already-successful salts are cheap to re-hit; failed salts need the higher gas.

Confirm estimate for a failed tx:

```bash
# example: replace TX with a failed hash
TX=0xada77fff1d8ed4168a0d8bb79a6057b17884699b7163735b0ce21e6141333d79
TO=$(cast tx $TX --rpc-url battlechain-sepolia --json | python3 -c "import sys,json; print(json.load(sys.stdin)['to'])")
DATA=$(cast tx $TX --rpc-url battlechain-sepolia --json | python3 -c "import sys,json; print(json.load(sys.stdin)['input'])")
FROM=$(cast tx $TX --rpc-url battlechain-sepolia --json | python3 -c "import sys,json; print(json.load(sys.stdin)['from'])")
cast estimate $TO $DATA --from $FROM --rpc-url battlechain-sepolia
cast tx $TX --rpc-url battlechain-sepolia | grep -E 'gasLimit|gas '
```

If estimate ≫ gasLimit → under-gassed CREATE3 (this failure mode).

### Attack mode / Safe Harbor (important)

Wave B scopes the **same Create3Factory** as Wave A (`0xC8E93C3c…AD3A`).

Wave A agreement `0xC0C17b7ffb394343A6B0Abfd4594C61AF47a08f1` already linked that factory for attack mode.

If you call `requestUnderAttack` on a **new** Wave B agreement that lists the same factory, AttackRegistry reverts:

```text
AttackRegistry__ContractAlreadyLinked(contractAddress, existingAgreement)
// selector 0x71cab4cb
// contractAddress   = Create3Factory  0xC8E93C3c…AD3A
// existingAgreement = Wave A          0xC0C17b7f…08f1
```

**What this means**

| Situation | Action |
|-----------|--------|
| Deploy already succeeded; only attack mode failed | **Do nothing** — Balancer diamonds under Create3Factory are covered by Wave A if scope is `ChildContractScope.All` |
| Re-run script | Script now **skips** `requestAttackMode` when factory is already linked |
| Announce attackable surface | Point attackers at **Wave A agreement** + new Balancer addresses |
| Want a separate Wave B agreement in AttackRegistry | Scope **only new top-level roots not already linked** (not Create3Factory again). Or wait until Wave A is `PRODUCTION` / `CORRUPTED` (re-link allowed from terminal states) |

Check factory linkage:

```bash
# AttackRegistry proxy (testnet) — from BC_TESTNET.ATTACK_REGISTRY
cast call 0x22134e878c409a0Eab7259d873b38e26Ca966d3C \
  "getAgreementForContract(address)(address)" \
  0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A \
  --rpc-url battlechain-sepolia

# Expect: 0xC0C17b7ffb394343A6B0Abfd4594C61AF47a08f1  (Wave A)
```

---

## 1) Deploy commands (copy-paste)

Open a terminal and run:

```bash
# From Crane repo root
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane

# Resolve broadcaster — REQUIRED (never omit --sender; avoids Foundry default 0x1804…)
export DEPLOYER=$(cast wallet address --account deployer)
echo "DEPLOYER=$DEPLOYER"

# Optional: confirm Wave A surfaces have code on BC
cast code 0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A --rpc-url battlechain-sepolia | head -c 20; echo
cast code 0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42 --rpc-url battlechain-sepolia | head -c 20; echo
cast code 0xe7f3Be59500DE7CA6c6180614F058B53350Eb179 --rpc-url battlechain-sepolia | head -c 20; echo
```

### 1a) Compile (can take a long time first run)

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane

forge build --contracts scripts/foundry/Script_Promo_BC_BalancerV3.s.sol
```

### 1b) Broadcast Wave B (live BattleChain testnet)

**Copy-paste source of truth:** [`WAVE_B_BALANCER_V3_COMMANDS.md`](./WAVE_B_BALANCER_V3_COMMANDS.md)

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane

export DEPLOYER=$(cast wallet address --account deployer)
echo "DEPLOYER=$DEPLOYER"

forge script scripts/foundry/Script_Promo_BC_BalancerV3.s.sol:Script_Promo_BC_BalancerV3 \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender "$DEPLOYER" \
  -g 400 \
  -vvvv
```

Must include: `--sender`, `--skip-simulation`, `-g 400`.  
If still failing: same command with `-g 500` or `-g 600`.  
Retries are mostly idempotent (CREATE3 salts already deployed return early).

### 1c) Dry-run only (no broadcast)

```bash
cd /Users/cyotee/Development/projects-defi/daosys/lib/indexedex/lib/crane
export DEPLOYER=$(cast wallet address --account deployer)

forge script scripts/foundry/Script_Promo_BC_BalancerV3.s.sol:Script_Promo_BC_BalancerV3 \
  --rpc-url battlechain-sepolia \
  --sender "$DEPLOYER" \
  -vvvv
```

---

## 2) After success

Script writes:

```
docs/deployment/addresses/battlechain-sepolia-balancer-v3.json
docs/deployment/addresses/battlechain-sepolia-balancer-v3.table.md
script/output/battlechain-sepolia/wave-b-balancer-v3.latest.json
```

Then:

```bash
# Peek addresses
cat docs/deployment/addresses/battlechain-sepolia-balancer-v3.json

# Explorer (chain 627)
open "https://explorer.testnet.battlechain.com"
```

Optional follow-up (agent or manual):

- Wire `BALANCER_V3_*` into `contracts/constants/networks/BC_TESTNET.sol`
- Refresh `docs/deployment/deployed-addresses.md` (addresses live on the docs site — not in the social post)

---

## 3) Verified X handles (searched 2026-07-23)

Use these orgs/people — **do not invent handles**.

### BattleChain / Cyfrin

| Handle | Account |
|--------|---------|
| `@battlechain` | Battlechain |
| `@cyfrin` | Cyfrin Audits |
| `@PatrickAlphaC` | Patrick Collins |
| `@CodeHawks` | Cyfrin CodeHawks |

### Balancer

| Handle | Account |
|--------|---------|
| `@Balancer` | Balancer (primary) |
| `@balancerlabs` | Balancer Labs |

### Optional

| Handle | Notes |
|--------|--------|
| `@CyfrinUpdraft` | Cyfrin education |
| `@trailofbits` | Security research |
| `@OpenZeppelin` | Contracts / patterns |

---

## 4) X announcement post

**When to post:** After deploy is live and addresses are on the Crane docs site (Deployed Addresses).  
**Do not paste contract addresses in the post** — point people at the docs.  
**Premium:** body can be long; first ~280 chars is the attention grab.

### Headline (first ~280 chars — start of the post)

```
Balancer V3 is live on @battlechain testnet — and ready to use.

Vault, routers, and pool types for anyone building on Balancer V3 before mainnet.

Addresses on our docs. Come build (or break it).

@Balancer @battlechain @cyfrin
```

### Full post (copy everything below into X)

```
Balancer V3 is live on @battlechain testnet — and ready to use.

Vault, routers, and pool types for anyone building on Balancer V3 before mainnet.

Addresses on our docs. Come build (or break it).

@Balancer @battlechain @cyfrin

—

We’ve deployed Balancer V3 on BattleChain testnet as part of Crane — so builders can integrate against a real V3 stack in an adversarial environment, not only on mainnet after the fact.

What’s available:
• Vault
• Routers
• Weighted, Stable, and Constant Product pools

If you’re shipping products, hooks, or strategies on Balancer V3, you can target this deployment on BattleChain testnet today.

Contract addresses and network details live on our documentation site under Deployed Addresses — we keep that page updated so posts don’t go stale with hex dumps.

https://cyotee.github.io/crane/

@Balancer @balancerlabs — programmable AMM infrastructure we’re proud to stand on.
@battlechain @cyfrin @PatrickAlphaC @CodeHawks — the adversarial testnet that makes “ready for use” mean something.

Build on it. Attack it. Tell us what breaks.
```

### Optional short reply (tags only)

```
@battlechain @cyfrin @PatrickAlphaC @CodeHawks @Balancer @balancerlabs
```

---

## 5) Post checklist

- [ ] Wave B broadcast succeeded  
- [ ] Addresses published on Crane Deployed Addresses (docs site)  
- [ ] Post links docs — no address list in the tweet  
- [ ] Headline is the first ~280 characters of the Premium post  

---

## 6) Quick reference — key Wave A addresses (inputs, not redeployed)

| Component | Address |
|-----------|---------|
| Create3Factory | `0xC8E93C3c1777dFD2a9bb2Cfd6639424a0987AD3A` |
| DiamondPackageCallBackFactory | `0x1DfBEbb39fa97DB8f83a95734C065869343792Ab` |
| WETH (BC-provided) | `0x4CAc28Fc96bb8fa0e6F94ef0E579384902142f42` |
| BetterPermit2 | `0xe7f3Be59500DE7CA6c6180614F058B53350Eb179` |
| RPC | `https://testnet.battlechain.com` (`battlechain-sepolia`) |
| Explorer | `https://explorer.testnet.battlechain.com` |
