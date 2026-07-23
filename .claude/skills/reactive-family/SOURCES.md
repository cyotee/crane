# Reactive skill family — sources

Generated: 2026-07-22  
Root docs: https://dev.reactive.network/  
Demos: https://github.com/Reactive-Network/reactive-smart-contract-demos  
Lib: https://github.com/Reactive-Network/reactive-lib-omni  
Test lib: https://github.com/Reactive-Network/reactive-test-lib  

## Documentation pages (inventory)

| URL | Title / section | Consumed by skill(s) | Status |
|-----|-----------------|----------------------|--------|
| https://dev.reactive.network/ | Getting Started / Overview | reactive-architecture | done |
| https://dev.reactive.network/docs/ | Docs index (omni path) | reactive-architecture | done |
| https://dev.reactive.network/hyperlane | Hyperlane mailboxes | reactive-deployment, reactive-callbacks | done |
| https://dev.reactive.network/reactive-contracts | Reactive contracts (omni) | reactive-contracts, reactive-deployment | done |
| https://dev.reactive.network/reactive-mainnet | Mainnet & Lasna / faucet | reactive-deployment | done |
| https://dev.reactive.network/reactive-library | Library abstracts & interfaces | reactive-contracts, reactive-callbacks | done |
| https://dev.reactive.network/events-&-callbacks | LogRecord, requestCallback* | reactive-callbacks, reactive-contracts | done |
| https://dev.reactive.network/subscriptions | subscribe/unsubscribe rules | reactive-contracts | done |
| https://dev.reactive.network/rnk-rpc-methods | rnk_getFilters et al. | reactive-deployment | done |
| https://dev.reactive.network/legacy/origins-and-destinations | Origin/dest + proxy table | reactive-architecture, reactive-deployment | done |
| https://dev.reactive.network/legacy/reactvm | ReactVM dual-state | reactive-architecture, reactive-callbacks | done |
| https://dev.reactive.network/legacy/reactive-contracts | Dual deploy + verify | reactive-architecture, reactive-contracts | done |
| https://dev.reactive.network/legacy/economy | Funding, fees, debt | reactive-deployment | done |
| https://dev.reactive.network/legacy/debugging | Inactive, faucet, MetaMask | reactive-deployment, reactive-callbacks | done |
| https://dev.reactive.network/legacy/demos | Demo list | reactive-integrations | done |
| https://dev.reactive.network/legacy/testing | reactive-test-lib | reactive-integrations | done |
| https://dev.reactive.network/legacy/events-&-callbacks | Legacy events (overlap) | covered via omni + debugging | done (overlap) |
| https://dev.reactive.network/legacy/subscriptions | Legacy subs (overlap) | covered via omni | done (overlap) |
| https://dev.reactive.network/legacy/reactive-library | Legacy lib (overlap) | covered via omni | done (overlap) |
| https://dev.reactive.network/legacy/reactive-mainnet | Legacy network (overlap) | covered via omni + faucet | done (overlap) |
| https://dev.reactive.network/legacy/rnk-rpc-methods | Legacy RPC (overlap) | covered via omni | done (overlap) |
| https://dev.reactive.network/contacts/ | Support/community | family note only | done (minimal) |
| https://dev.reactive.network/search | Site search | out of scope | waived |
| https://dev.reactive.network/sitemap.xml | Discovery | inventory only | done |

## Demo / code sources

| Source | Consumed by |
|--------|-------------|
| demos README | reactive-integrations |
| `src/demos/*` catalog paths | reactive-integrations |
| BasicDemoReactiveContract.sol (pattern quote) | reactive-integrations |
| Subscriptions docs links to PingPong / Xfers micro-demos | reactive-contracts |
| Uniswap stop-order payload example | reactive-callbacks, reactive-architecture |

## Skills emitted

| Skill | Path under `.claude/skills/` |
|-------|------------------------------|
| reactive-architecture | `reactive-architecture/` |
| reactive-contracts | `reactive-contracts/` |
| reactive-callbacks | `reactive-callbacks/` |
| reactive-deployment | `reactive-deployment/` |
| reactive-integrations | `reactive-integrations/` |
