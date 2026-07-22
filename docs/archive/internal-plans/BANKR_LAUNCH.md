# BankrBot Token Launch for Crane / DAOSYS

**Goal**: Launch a token (CRANE / DAOSYS) via BankrBot fair launch on Base. Trading fees (95% to creator/fee recipient) sustain ongoing Crane framework development, porting of DeFi protocols, and the on-chain bounty board for agents.

See also: [GOVERNANCE.md](GOVERNANCE.md), [README.md](README.md), and Bankr docs at https://docs.bankr.bot/.

## Prerequisites (Professional Launch Standards)

Before launching the funding token, the framework must meet professional quality bars:

- Full NatSpec + AsciiDoc include-tags on all core interfaces, factories, DFPkgs, access, introspection, tokens, and key protocol surfaces (per `crane-natspec` skill and AGENTS.md).
- GitBook-friendly documentation (complete `docs/SUMMARY.md`, accurate getting-started, architecture, deployment, agent guides).
- Up-to-date, clean `.claude/skills/` covering:
  - Crane core (architecture, deployment, testing, code-style, natspec, access, tokens, utilities).
  - All major ported protocols (Balancer V3, Uniswap V2/V3/V4, Aerodrome+Slipstream, Aave v3/v4, Euler, etc.).
- Comprehensive examples and "building with Crane" guidance so other agents can:
  - Safely author new Facet-Target-Repo modules.
  - Create DFPkgs for reusable deployment.
  - Achieve low-cost deterministic cross-chain deploys.
  - Write rigorous tests (Behavior + invariants + handlers).
- Passing builds/tests, consistent formatting (`forge fmt`), and BattleChain pilots completed for core factories/DFPkgs.
- Security story documented: patterns + tests + BattleChain adversarial survival gate.

Only once the above are satisfactory do we proceed to token launch.

## BankrBot Mechanics (from https://docs.bankr.bot/)

- **Platform**: Primarily Base (Uniswap V4 pool created automatically).
- **Supply**: 100 billion fixed. 85% to liquidity pool, 15% creator vesting (90-day cliff, 2-year linear).
- **Fees**: 0.7% swap fee. 95% to creator/fee recipient, 5% to protocol.
- **Subscription**: Bankr Club (~$20/mo in BNKR or equivalent) or LLM credits required for launch capability.
- **CLI Launch**: `bankr launch` (interactive wizard or headless flags).
- **Fee Recipient**: Can route to X handle, Farcaster, ENS, or wallet. Set to the dev/agent treasury to capture fees.
- **Self-sustaining**: Agent wallets + trading fees pay for compute (LLM Gateway, etc.).
- **Limits**: Daily launch caps (higher for Club members). Gas often sponsored.

See full details:
- https://docs.bankr.bot/token-launching/overview
- https://docs.bankr.bot/cli (especially `bankr launch`, `bankr fees`, `bankr club`)

## Steps to Launch (Once Framework is Ready)

### 1. Fund & Prepare Agent Wallet

- Create/login a dedicated BankrBot agent wallet via `bankr login`.
- Transfer/pay subscription costs to the agent-linked account (BNKR for Club, or USDC/ETH via `bankr club signup`).
- Ensure the wallet has any required base assets (CLI can handle swaps for fees).

Example:
```bash
npm install -g @bankr/cli
bankr login          # Follow prompts (email, SIWE, or API key)
bankr whoami         # Verify wallet + Club status
bankr club signup --token BNKR --yes   # Or USDC
```

Transfer subscription or funding amounts from a treasury to this agent's address as needed.

### 2. Prepare Launch Metadata

- Name: e.g. "Crane" or "DAOSYS" (align with GOVERNANCE/README).
- Symbol: "CRANE" or "DAOSYS".
- Image URL (optional, hosted publicly).
- Website / social links (Crane repo, docs, X account).
- **Fee recipient**: Set to the dev/agent wallet (or treasury multisig) using `--fee <addr or @handle> --fee-type wallet|x`.

### 3. Execute Launch via CLI

Interactive (recommended first time):
```bash
bankr launch
```

Headless (for precision):
```bash
bankr launch \
  --name "Crane Framework" \
  --symbol "CRANE" \
  --image "https://..." \
  --website "https://..." \
  --fee "0xYourDevWalletOrTreasury" --fee-type wallet \
  --yes
```

Use `--simulate` first to validate.

After launch, note the token address and pool.

### 4. Post-Launch

- Verify on Base explorer and Bankr terminal.
- Monitor earnings: `bankr fees` or `bankr fees --token <addr>`.
- Claim: `bankr fees claim <tokenAddress>` (or claim-wallet for external keys).
- Announce + point developers/agents to the repo, skills, and bounty board.
- Route a portion of fees toward compute credits (`bankr llm credits add ...`).

### 5. Ongoing Funding Model

- Trading volume on the token generates WETH + token fees to the recipient.
- Fees pay for Bankr LLM usage, further development bounties, audits, etc.
- The on-chain bounty board (see GOVERNANCE.md) lets agents earn the work token by extending Crane.
- Agents sell earned tokens for more compute → flywheel.

## Alignment with Crane Values

The launch token itself should ideally be deployed **using Crane** (ERC20DFPkg or a custom governance-aware package) once BattleChain gate is passed for the token facets. This dogfoods the framework.

See pilot scripts in `scripts/foundry/` and `InitBcService`.

## References

- Bankr CLI & Token Launching: https://docs.bankr.bot/cli , https://docs.bankr.bot/token-launching/overview
- Project: README.md, GOVERNANCE.md, AGENTS.md
- Code: `contracts/tokens/ERC20/`, `contracts/factories/`

**Do not launch until the quality checklist above is satisfied.** The credibility of the token rests on the quality and reusability of the underlying Crane framework.
