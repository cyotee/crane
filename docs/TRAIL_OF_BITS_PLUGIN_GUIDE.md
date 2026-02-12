# Trail of Bits Plugin Integration Guide

This guide describes how to use Trail of Bits (ToB) security plugins within the `/backlog` workflow for smart contract development and auditing.

## Available Plugins

### Security Audit Skills

| Skill | Command | Description |
|-------|---------|-------------|
| Entry Point Analyzer | `/entry-point-analyzer` | Identifies state-changing entry points in smart contracts for security auditing |
| Audit Context Building | `/audit-context-building` | Ultra-granular line-by-line code analysis for deep architectural understanding |
| Differential Review | `/differential-review` | Security-focused review of PRs, commits, and diffs with blast radius analysis |
| Fix Review | `/fix-review` | Verifies security fixes don't introduce bugs or regressions |
| Spec-to-Code Compliance | `/spec-to-code-compliance` | Verifies code implements exactly what documentation/specs specify |
| Variant Analysis | `/variant-analysis` | Finds similar vulnerabilities using pattern-based analysis after initial bug discovery |
| Sharp Edges | `/sharp-edges` | Identifies error-prone APIs, footgun designs, and dangerous configurations |
| Property-Based Testing | `/property-based-testing` | Guidance for property-based and invariant testing across languages |

### Testing Handbook Skills

| Skill | Command | Description |
|-------|---------|-------------|
| Semgrep | `/testing-handbook-skills:semgrep` | Static analysis for finding bugs and enforcing code standards |
| CodeQL | `/testing-handbook-skills:codeql` | Complex data flow and interprocedural analysis |
| Harness Writing | `/testing-handbook-skills:harness-writing` | Techniques for writing effective fuzzing harnesses |
| Fuzzing Dictionary | `/testing-handbook-skills:fuzzing-dictionary` | Domain-specific tokens for guiding fuzzers |
| Coverage Analysis | `/testing-handbook-skills:coverage-analysis` | Code coverage measurement for fuzzing effectiveness |
| Fuzzing Obstacles | `/testing-handbook-skills:fuzzing-obstacles` | Techniques for patching code to overcome fuzzing blockers |
| Wycheproof | `/testing-handbook-skills:wycheproof` | Test vectors for validating cryptographic implementations |
| Cargo Fuzz | `/testing-handbook-skills:cargo-fuzz` | Fuzzing for Rust projects |
| LibFuzzer | `/testing-handbook-skills:libfuzzer` | Coverage-guided fuzzer for C/C++ |
| AFL++ | `/testing-handbook-skills:aflpp` | Multi-core fuzzing for C/C++ projects |
| Atheris | `/testing-handbook-skills:atheris` | Coverage-guided Python fuzzer |
| Constant-Time Testing | `/testing-handbook-skills:constant-time-testing` | Detect timing side channels in cryptographic code |

---

## Integration with /backlog Workflow

### Phase 1: Task Planning (`/design`)

When creating new tasks, use ToB skills to identify scope:

```bash
# Before creating security-related tasks
/entry-point-analyzer    # Map attack surface and state-changing functions

# For spec compliance tasks (ERC/EIP implementations)
/spec-to-code-compliance # Identify gaps between spec and implementation
```

**Task types that benefit:**
- Security audit tasks
- ERC/EIP implementation tasks
- Protocol integration tasks

### Phase 2: Task Launch (`/backlog:launch`)

Include ToB skill recommendations in PROMPT.md for agents:

| Task Category | Recommended Skills in PROMPT.md |
|--------------|--------------------------------|
| Bug fixes | `/fix-review` after implementation |
| EIP compliance | `/spec-to-code-compliance` before/during |
| Fuzz tests | `/property-based-testing`, `/testing-handbook-skills:harness-writing` |
| Invariant tests | `/property-based-testing` |
| Security fixes | `/fix-review`, `/variant-analysis` |

**Example PROMPT.md addition:**
```markdown
## Trail of Bits Plugin Integration

This task involves [security fix/testing/compliance]. Consider using:

- `/fix-review` - Verify fix is complete and doesn't regress
- `/variant-analysis` - Search for similar bugs in codebase
```

### Phase 3: Implementation (Agent Worktree)

Agents can invoke ToB skills during implementation:

**For Security Fixes:**
```bash
# After implementing fix
/fix-review              # Verify fix addresses the issue without introducing bugs
```

**For Test Writing:**
```bash
# When designing fuzz tests
/property-based-testing  # Get guidance on property design

# When writing harnesses
/testing-handbook-skills:harness-writing
```

**For EIP/Spec Work:**
```bash
# Verify implementation matches standard
/spec-to-code-compliance
```

### Phase 4: Code Review (`/backlog:review`)

Use ToB skills during code review for deeper analysis:

```bash
# Deep security analysis of changes
/audit-context-building

# Security-focused diff review
/differential-review

# After fixing security issues, find similar patterns
/variant-analysis
```

### Phase 5: Post-Completion

After completing security-related tasks:

```bash
# Hunt for similar bugs across codebase
/variant-analysis

# Identify remaining footguns
/sharp-edges
```

---

## Task-Specific Recommendations

### Security Bug Fixes (e.g., CRANE-020, CRANE-024, CRANE-051, CRANE-057)

| Stage | Skill | Purpose |
|-------|-------|---------|
| Before | `/audit-context-building` | Understand full context of bug |
| During | N/A | Implement fix |
| After | `/fix-review` | Verify fix is complete |
| After | `/variant-analysis` | Find similar bugs |

**Workflow:**
```bash
/backlog:launch CRANE-024
# Agent implements fix
/fix-review              # Verify fix
/variant-analysis        # Hunt similar issues
/backlog:review          # Code review
```

### EIP/ERC Compliance (e.g., CRANE-022, CRANE-023, CRANE-060)

| Stage | Skill | Purpose |
|-------|-------|---------|
| Before | `/spec-to-code-compliance` | Identify spec gaps |
| During | `/spec-to-code-compliance` | Verify as implementing |
| After | `/spec-to-code-compliance` | Final compliance check |

**Workflow:**
```bash
/spec-to-code-compliance # Check current compliance
/backlog:launch CRANE-023
# Agent implements
/spec-to-code-compliance # Verify compliance
/backlog:review
```

### Fuzz Testing (e.g., CRANE-032, CRANE-034, CRANE-038)

| Stage | Skill | Purpose |
|-------|-------|---------|
| Before | `/property-based-testing` | Design test properties |
| During | `/testing-handbook-skills:harness-writing` | Write effective harnesses |
| After | `/testing-handbook-skills:coverage-analysis` | Verify coverage |

**Workflow:**
```bash
/property-based-testing  # Design invariants
/backlog:launch CRANE-038
# Agent writes tests
/testing-handbook-skills:coverage-analysis  # Check coverage
/backlog:review
```

### Invariant Testing (e.g., CRANE-041, CRANE-049)

| Stage | Skill | Purpose |
|-------|-------|---------|
| Before | `/property-based-testing` | Identify key invariants |
| During | `/property-based-testing` | Refine properties |

**Workflow:**
```bash
/property-based-testing  # Identify invariants
/backlog:launch CRANE-049
# Agent implements
/backlog:review
```

### Protocol Integrations (e.g., CRANE-037, CRANE-055)

| Stage | Skill | Purpose |
|-------|-------|---------|
| Before | `/entry-point-analyzer` | Map integration surface |
| Before | `/spec-to-code-compliance` | Verify protocol spec understanding |
| After | `/sharp-edges` | Identify footgun APIs |

---

## Static Analysis Integration

For codebase-wide analysis, use:

```bash
# Quick bug scanning
/testing-handbook-skills:semgrep

# Complex data flow analysis
/testing-handbook-skills:codeql
```

**Best used:**
- Before major releases
- After completing a group of related tasks
- During security audits

---

## Example: Complete Security Task Workflow

```bash
# 1. Analyze the bug context
/audit-context-building

# 2. Launch the task
/backlog:launch CRANE-051

# 3. (Agent implements fix in worktree)

# 4. Verify the fix
/fix-review

# 5. Search for similar issues
/variant-analysis

# 6. Enter code review
/backlog:review

# 7. (Review with ToB skills)
/differential-review

# 8. Complete the task
/backlog:complete CRANE-051
```

---

## Quick Reference: Task Type to Skill Mapping

| Task Type | Primary Skills | Secondary Skills |
|-----------|---------------|------------------|
| Security bug fix | `/fix-review`, `/variant-analysis` | `/audit-context-building` |
| EIP compliance | `/spec-to-code-compliance` | - |
| Fuzz tests | `/property-based-testing` | `/testing-handbook-skills:harness-writing` |
| Invariant tests | `/property-based-testing` | - |
| Protocol integration | `/entry-point-analyzer` | `/sharp-edges`, `/spec-to-code-compliance` |
| API design | `/sharp-edges` | - |
| General review | `/differential-review` | `/audit-context-building` |
| Crypto code | `/testing-handbook-skills:constant-time-testing` | `/testing-handbook-skills:wycheproof` |

---

## Notes

- ToB skills are advisory - they provide guidance and analysis but don't modify code
- Use `/property-based-testing` for any test design involving invariants or fuzzing
- `/variant-analysis` is most effective after finding an initial bug
- `/spec-to-code-compliance` works best with well-documented standards (EIPs, protocol docs)
- For Solidity/smart contracts, `/entry-point-analyzer` is particularly valuable for mapping attack surface
