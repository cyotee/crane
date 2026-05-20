# Guard Functions and Modifiers

Access control logic resides in Repos. Modifiers are thin delegation wrappers.

## Guard Functions

Repos implement `_onlyXxx` functions that perform the check and revert with the appropriate custom error.

```solidity
function _onlyOperator(Storage storage layoutStruct) internal view {
    if (!_isOperator(layout, msg.sender) &&
        !_isFunctionOperator(layout, msg.sig, msg.sender)) {
        revert IOperable.NotOperator(msg.sender);
    }
}

function _onlyOperator() internal view {
    _onlyOperator(_layoutStruct());
}
```

All policy lives in the guard. There is a single source of truth for the condition.

## Modifiers

```solidity
abstract contract OperableModifiers {
    modifier onlyOperator() {
        OperableRepo._onlyOperator();
        _;
    }
}
```

Modifiers contain no logic. They exist only to provide the `modifier` syntax for contracts that inherit them.

## Direct Calls

Because the guard is a regular internal function, other Repo functions or Targets can call `_onlyOperator()` directly without going through a modifier. This is the preferred pattern inside library code.

## Function-Level Operators

The operable pattern supports both global operators and per-function operators. The guard checks both. Packages and facets that install operable logic automatically receive this granularity.

## Reentrancy Guards

Reentrancy protection uses transient storage (EIP-1153). The lock is acquired and released within the same transaction and does not require storage writes that persist.

See the reentrancy module for the concrete `ReentrancyLockRepo` and `ReentrancyLockModifiers` implementation.
