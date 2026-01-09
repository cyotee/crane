# Task: Aerodrome Slipstream Utils Library

## Objective

Create quoting and utility libraries for Aerodrome Slipstream, the Uniswap V3 fork deployed on Base.

## Scope

**You are responsible for:**
- Analyzing Slipstream code at `lib/slipstream/` for differences from Uniswap V3
- Creating `contracts/utils/math/SlipstreamUtils.sol`
- Creating `contracts/utils/math/SlipstreamQuoter.sol`
- Creating `contracts/utils/math/SlipstreamZapQuoter.sol`
- Porting Slipstream libraries to `contracts/protocols/dexes/aerodrome/slipstream/` if needed
- Creating tests in `test/foundry/spec/utils/math/slipstreamUtils/`

**You are NOT responsible for:**
- Modifying UniswapV3Utils or UniswapV3Quoter
- Creating V4 libraries (another agent handles that)
- Creating mainnet fork tests (another agent handles those)

## Inventory Check

Before starting, verify:
1. [ ] `lib/slipstream/` directory exists
2. [ ] Slipstream contracts compile with `forge build`
   - If not, document the pragma/import issues
3. [ ] Reference `contracts/utils/math/UniswapV3Utils.sol` exists to use as template
4. [ ] Reference `contracts/utils/math/UniswapV3Quoter.sol` exists
5. [ ] Reference `contracts/utils/math/UniswapV3ZapQuoter.sol` exists

If Slipstream contracts don't compile due to pragma issues:
1. Document which files have incompatible pragmas
2. Port required libraries to `contracts/protocols/dexes/aerodrome/slipstream/libraries/`
3. Use `unchecked` blocks for modular arithmetic (see Uniswap V3 ports as example)

If any critical check fails, output:
```
<promise>BLOCKED: [description of blocker]</promise>
```

## Slipstream Analysis Requirements

Before implementing, document in a `SLIPSTREAM_ANALYSIS.md` file:
1. Pragma versions used in Slipstream
2. Differences from Uniswap V3:
   - Tick spacing configurations
   - Fee structures
   - Any custom features (gauge integration, etc.)
3. Libraries that need porting vs. can be imported
4. Any Slipstream-specific math or behavior

## Implementation Requirements

### SlipstreamUtils.sol

Mirror `UniswapV3Utils.sol` functionality:
- `_quoteExactInputSingle()`
- `_quoteExactOutputSingle()`
- `_quoteAmountsForLiquidity()`
- `_quoteLiquidityForAmounts()`
- Tick/price conversion helpers

### SlipstreamQuoter.sol

Mirror `UniswapV3Quoter.sol` functionality:
- `quoteExactInput()` - tick-crossing
- `quoteExactOutput()` - tick-crossing
- Pool state reading (slot0, liquidity, tickBitmap, ticks)

### SlipstreamZapQuoter.sol

Mirror `UniswapV3ZapQuoter.sol` functionality:
- `quoteZapInSingleCore()`
- `quoteZapOutSingleCore()`
- Pool/PositionManager wrapper structs

### Tests

Create comprehensive tests:
```
test/foundry/spec/utils/math/slipstreamUtils/
├── SlipstreamUtils_quoteExactInput.t.sol
├── SlipstreamUtils_quoteExactOutput.t.sol
├── SlipstreamUtils_LiquidityAmounts.t.sol
├── SlipstreamQuoter_tickCrossing.t.sol
├── SlipstreamZapQuoter_ZapIn.t.sol
└── SlipstreamZapQuoter_ZapOut.t.sol
```

## File Structure

If porting is required:
```
contracts/protocols/dexes/aerodrome/slipstream/
├── libraries/
│   ├── FullMath.sol
│   ├── TickMath.sol
│   ├── SqrtPriceMath.sol
│   ├── SwapMath.sol
│   ├── TickBitmap.sol
│   ├── Tick.sol
│   └── ...
├── interfaces/
│   ├── ICLPool.sol
│   └── ...
└── test/bases/
    └── TestBase_Slipstream.sol
```

## Completion Criteria

- [ ] Slipstream analysis documented
- [ ] All required libraries ported (if needed)
- [ ] SlipstreamUtils.sol complete and tested
- [ ] SlipstreamQuoter.sol complete and tested
- [ ] SlipstreamZapQuoter.sol complete and tested
- [ ] All tests pass (recommended): `forge test --match-contract 'Slipstream'`

Notes on running tests:
- In this repo setup, `forge test --match-path ".../slipstreamUtils/*"` does not select tests reliably.
- `--match-path` works well with an exact file path, e.g.
   - `forge test --match-path test/foundry/spec/utils/math/slipstreamUtils/SlipstreamUtils_quoteExactInput.t.sol`
   - `forge test --match-path test/foundry/spec/utils/math/slipstreamUtils/SlipstreamQuoter_tickCrossing.t.sol`

## Completion Signal

When all criteria are met, output:
```
<promise>TASK_COMPLETE</promise>
```

If blocked, output:
```
<promise>TASK_BLOCKED: [specific issue]</promise>
```
