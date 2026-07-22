# Security Policy

## Reporting a vulnerability

Please report security issues in Crane **privately** via GitHub Security Advisories on the public repository:

**https://github.com/cyotee/crane/security/advisories/new**

Do **not** open a public issue for unfixed vulnerabilities in contracts, factories, or deployment tooling.

Include:

- Affected component (path or interface if known)
- Description of the issue and impact
- Reproduction steps or a minimal PoC when possible
- Whether you have already disclosed the issue elsewhere

We will acknowledge reports as soon as practical and coordinate disclosure.

## Scope

In scope:

- Crane-native contracts under `contracts/` (excluding third-party vendored trees except where Crane wrappers introduce new risk)
- Deployment helpers and factory packages intended for production use
- Documentation that could cause unsafe deployment if followed literally

Out of scope (report upstream when appropriate):

- Purely vendored upstream protocol code under `contracts/external/` or `lib/` with no Crane modification
- Issues only present in experimental / incomplete protocol ports (see maturity notes in the docs)
- Social engineering, phishing, or issues requiring compromised developer machines

## BattleChain and production deploys

BattleChain adversarial testing may be used as a **deployment gate** for factories and packages. It is **not** a substitute for private vulnerability disclosure. Surviving BattleChain attack mode does not imply a formal audit of every port or every consumer Diamond.

## No public bounty (unless stated)

Unless a public bug bounty is announced separately, there is **no guaranteed payout** for reports. Responsible disclosure is still appreciated and credited when you want credit.

## Safe Harbor

If you research Crane under an explicit Safe Harbor or BattleChain agreement for a specific deployment, follow that agreement’s scope and rules. Default open-source use of this repository does not automatically grant permission to attack third-party production systems.
