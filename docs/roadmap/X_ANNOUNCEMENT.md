# Crane public announcement (X / Twitter)

Copy from the sections below. The **headline** is the first ~280 characters for the preview/attention grab.

---

## Headline (first post / first ~280 chars)

```
Announcing Crane: open-source Diamond-first (ERC-2535) Solidity for humans + AI agents.

Deploy once. Attach battle-tested facets. Modular DeFi without redeploying risk.

Docs + agent skills live 🧵
@OpenZeppelin @austingriffith @solidity_lang @gakonst
```

---

## Full post (paste as one long post, or headline then continue)

Announcing Crane: open-source Diamond-first (ERC-2535) Solidity for humans + AI agents.

Deploy once. Attach battle-tested facets. Modular DeFi without redeploying risk.

Docs + agent skills live 🧵
@OpenZeppelin @austingriffith @solidity_lang @gakonst

Crane is public.

It’s a Diamond-first smart contract framework: Facet-Target-Repo architecture, CREATE3 factories, DFPkgs, and Foundry-native TestBase/Behavior patterns—so teams and agents reuse verified logic instead of regenerating large surfaces of new bytecode every project.

Why this matters:
• Security: attach known-good facets via packages rather than “agent rewrote half the system”
• Cost: deploy once, compose many proxies
• Agents: skills + marketplaces so Claude/Codex/Grok-style tools load Crane patterns on demand

Docs: https://cyotee.github.io/crane/
Repo: https://github.com/cyotee/crane

AI tooling (build):
/plugin marketplace add cyotee/cyotee-claude-plugins
/plugin install crane@cyotee
→ https://github.com/cyotee/cyotee-claude-plugins

AI tooling (on-chain ops, testnet-first):
/plugin marketplace add cyotee/defi-agent-skills
→ https://github.com/cyotee/defi-agent-skills

Standing on open Ethereum infrastructure—thank you to the people and projects that make modular onchain work possible:

@OpenZeppelin — contracts, patterns, and the security bar the whole industry builds on
@austingriffith @buidlguidl — Scaffold-ETH / BuidlGuidl: make shipping on Ethereum approachable for builders (and AI)
@solidity_lang — the language we all still write in
@gakonst — Foundry (and the forge/cast/anvil loop Crane is built around)
@ethereum @ethereumfndn — the ecosystem this is for
@trailofbits — the security mindset that keeps frameworks honest

Honest scope: core factories / access / tokens / registries are the primary surface. Protocol ports vary—see maturity docs. CI proves framework core; ports are labeled.

If you build diamonds, ports, or agent-native Solidity workflows, try the docs path and yell at the repo. Contributions and adversarial feedback welcome.

AGPL-3.0 for Crane-native code · vendored deps keep their licenses

---

## Optional reply (tag pile / second tweet)

Also for the agent-native + tooling crowd:
@OpenZeppelin @austingriffith @buidlguidl @solidity_lang @gakonst @ethereum @ethereumfndn @trailofbits

Scaffold builders + AI: ethskills / Scaffold-ETH paths pair well with agent skills—Crane is the Diamond/factory layer for modular contracts.

---

## Handles reference

| Handle | Who |
|--------|-----|
| @OpenZeppelin | OpenZeppelin |
| @austingriffith | Austin Griffith |
| @buidlguidl | BuidlGuidl |
| @solidity_lang | Solidity |
| @gakonst | Georgios K. (Foundry) |
| @ethereum | Ethereum |
| @ethereumfndn | Ethereum Foundation |
| @trailofbits | Trail of Bits |
