# Operable

Granular operator permissions with support for global and per-function operators.

## Storage

`crane.access.operable`

## Layers

- `OperableRepo` — mappings for operators and function-specific operators; guard `_onlyOperator`.
- `OperableTarget`
- `OperableFacet`
- `OperableModifiers`

## Usage

Contracts inherit `OperableModifiers` to obtain the `onlyOperator` modifier.

Inside Repos and Targets, call `OperableRepo._onlyOperator()` directly for internal enforcement.

## Function Operators

An address can be granted operator rights for a specific selector via `setFunctionOperator`. The guard checks both global `isOperator` and the per-selector mapping before reverting.

This enables least-privilege operator roles without deploying separate role contracts for every function.
