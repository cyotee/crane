# Progress Log: CRANE-202

## Current Checkpoint

**Last checkpoint:** Not started
**Next step:** Read TASK.md and begin implementation
**Build status:** ⏳ Not checked
**Test status:** ⏳ Not checked

---

## Session Log

### 2026-02-02 - Task Created

- Task designed via /design:design
- TASK.md populated with requirements for Uniswap V2 fork comparison tests
- Scope: Ethereum + Base mainnet forks comparing local stubs vs deployed contracts
- Test token approach: Deploy ERC20PermitMintableStub with 18 and 6 decimals
- Comparison method: Execute same operations on both, assert exact output match
- Ready for agent assignment via /backlog:launch

### Implementation Notes

**Key patterns to follow:**
- Reference `TestBase_UniswapV3Fork.sol` for fork test structure
- Reference `TestBase_SlipstreamFork.sol` for Base mainnet fork setup
- Use `deal()` to seed token balances
- Use `vm.skip(true)` when INFURA_KEY not set
- Label addresses with `vm.label()` for debugging

**Test token deployment:**
```solidity
ERC20PermitMintableStub tokenA = new ERC20PermitMintableStub(
    "TestToken18", "TT18", 18, address(this), 0
);
ERC20PermitMintableStub tokenB = new ERC20PermitMintableStub(
    "TestToken6", "TT6", 6, address(this), 0
);
```

**Pool creation on mainnet factory:**
```solidity
IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_V2_FACTORY);
address pair = factory.createPair(address(tokenA), address(tokenB));
```

**Comparison assertion pattern:**
```solidity
uint256 mainnetOutput = mainnetRouter.swapExactTokensForTokens(...);
uint256 stubOutput = stubRouter.swapExactTokensForTokens(...);
assertEq(mainnetOutput, stubOutput, "Swap outputs must match exactly");
```
