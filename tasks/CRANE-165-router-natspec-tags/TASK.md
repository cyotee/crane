# Task CRANE-165: Add NatSpec Custom Tags to Router Contracts

**Repo:** Crane Framework
**Status:** Ready
**Created:** 2026-01-29
**Dependencies:** CRANE-142
**Worktree:** `docs/router-natspec-tags`
**Origin:** Code review finding 9 from CRANE-142

---

## Description

Add required NatSpec custom tags and AsciiDoc include-tags to all Balancer V3 Router diamond contracts per AGENTS.md documentation standards.

**Required Tags:**

Functions:
- `@custom:signature` - Full function signature
- `@custom:selector` - 4-byte selector hex

Errors:
- `@custom:signature` - Full error signature
- `@custom:selector` - 4-byte selector hex

Events:
- `@custom:signature` - Full event signature
- `@custom:topiczero` - Topic zero (keccak256 of signature)

AsciiDoc Include Tags:
- `// tag::MySymbol[]` at start of code block
- `// end::MySymbol[]` at end of code block

(Created from code review of CRANE-142)

## Dependencies

- CRANE-142: Refactor Balancer V3 Router as Diamond Facets (parent task) - Complete

## User Stories

### US-CRANE-165.1: Add Function NatSpec Tags

As a developer, I want function NatSpec tags so that documentation can be auto-generated.

**Acceptance Criteria:**
- [ ] All public/external functions have `@custom:signature`
- [ ] All public/external functions have `@custom:selector`
- [ ] Selectors match actual computed values
- [ ] Build succeeds

### US-CRANE-165.2: Add Error and Event Tags

As a developer, I want error and event NatSpec tags so that documentation is complete.

**Acceptance Criteria:**
- [ ] All custom errors have `@custom:signature` and `@custom:selector`
- [ ] All events have `@custom:signature` and `@custom:topiczero`
- [ ] Values match actual computed values
- [ ] Build succeeds

### US-CRANE-165.3: Add AsciiDoc Include Tags

As a developer, I want AsciiDoc include-tags so that code can be embedded in documentation.

**Acceptance Criteria:**
- [ ] Key structs, functions, and interfaces have include-tags
- [ ] Tags follow `// tag::SymbolName[]` pattern
- [ ] Build succeeds

## Files to Create/Modify

**Modified Files:**
- All files in `contracts/protocols/dexes/balancer/v3/router/diamond/`
- All files in `contracts/protocols/dexes/balancer/v3/router/diamond/facets/`

## Inventory Check

Before starting, verify:
- [ ] CRANE-142 is complete
- [ ] Review AGENTS.md NatSpec requirements
- [ ] Review existing Crane contracts for tag examples

## Completion Criteria

- [ ] All acceptance criteria met
- [ ] All functions, errors, events have required tags
- [ ] AsciiDoc include-tags added to key symbols
- [ ] Build succeeds

---

**When complete, output:** `<promise>TASK_COMPLETE</promise>`

**If blocked, output:** `<promise>TASK_BLOCKED: [reason]</promise>`
