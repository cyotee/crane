# Deployed Addresses

Canonical on-chain deployments of Crane core and vendored protocol surfaces.

**Source of truth (machine-readable):** files under [`addresses/`](./addresses/).  
**Solidity constants:** `contracts/constants/networks/BC_TESTNET.sol`  
**Human tables:** generated markdown included below (do not hand-edit generated tables).

After a successful broadcast of `scripts/foundry/Script_Promo_BC_Launch.s.sol`, the script **overwrites**:

| File | Purpose |
|------|---------|
| [`addresses/battlechain-sepolia.json`](./addresses/battlechain-sepolia.json) | JSON for agents / tooling |
| [`addresses/battlechain-sepolia.table.md`](./addresses/battlechain-sepolia.table.md) | mdBook include table |

**Agent handoff:** when the operator says Wave A is deployed, read the JSON, confirm non-zero addresses, ensure this page reflects the table include, and update `status` / notes if needed.

---

## BattleChain Testnet (chain 627)

| Field | Value |
|-------|--------|
| Network alias | `battlechain-sepolia` |
| Chain ID | `627` |
| RPC | `https://testnet.battlechain.com` |
| Explorer | [explorer.testnet.battlechain.com](https://explorer.testnet.battlechain.com) |
| Deploy script | `scripts/foundry/Script_Promo_BC_Launch.s.sol` |
| Wave | **A** — Crane core + ERC20Permit + Uni V2/V4 + Permit2 + Safe Harbor |
| Policy | **Use BC-provided deps; do not replace** (WETH, Uni V3, …) |
| Deployer EOA | `0xF71ea560c6465727efFe07Cfb4e1a05B40520Dd7` |
| Deployed at block | `17158` |
| Status | **Deployed** (Wave A live) |

### Addresses (Wave A)

{{#include addresses/battlechain-sepolia.table.md}}

### Solidity import

```solidity
import {BC_TESTNET} from "@crane/contracts/constants/networks/BC_TESTNET.sol";

// Crane Wave A
address factory = BC_TESTNET.CREATE3_FACTORY;
address uniV2 = BC_TESTNET.UNISWAP_V2_FACTORY;

// BattleChain-provided (do not redeploy)
address weth = BC_TESTNET.WETH;
address uniV3 = BC_TESTNET.UNISWAP_V3_FACTORY;
```

### Notes

- **Safe Harbor root** is `Create3Factory` (`0xC8E9…AD3A`) with `ChildContractScope.All` — protocol stubs and diamonds are children by deployer lineage. Agreement: `0xC0C1…08f1`.
- **Sample permit token (CBCP)** is a demo ERC20Permit diamond; it is **not** mainnet RICH.
- **WETH** and **Uniswap V3** (factory, SwapRouter, NPM) are **BattleChain-provided** — Wave A binds to them and does **not** redeploy.
- Crane create3-deploys **Uni V2**, **Uni V4 PoolManager**, **Permit2**, and Crane core when not provided by BC.
- Canonical BC infrastructure + test tokens + mocks also live in `BC_TESTNET` for ready use.

### Operator broadcast (from Crane root)

```bash
export DEPLOYER=$(cast wallet address --account deployer)

forge script scripts/foundry/Script_Promo_BC_Launch.s.sol:Script_Promo_BC_Launch \
  --rpc-url battlechain-sepolia \
  --broadcast \
  --skip-simulation \
  --account deployer \
  --sender $DEPLOYER \
  -vv
```

Then commit updated `docs/deployment/addresses/battlechain-sepolia.*` and `contracts/constants/networks/BC_TESTNET.sol`.

---

## Other networks

No Base / Ethereum mainnet Crane deployment address book yet. Add a new JSON + table under `addresses/` and a section here when those land.

BattleChain **mainnet** (626) infrastructure constants: `contracts/constants/networks/BC_MAIN.sol` (no Crane Wave A deploy there yet).

---

## See also

- [BattleChain Security Gate](./battlechain.md)
- [CREATE3 & New Chain Setup](./create3.md)
- IndexedEx operator plan: `docs/BATTLECHAIN_DEPLOY_PLAN.md` (in the IndexedEx repo)
