# Ethereum Staking Ports — Dependency Map

**Policy:** No new Foundry remappings. All imports use existing `@crane/...` paths only.  
**OZ pin:** OpenZeppelin Contracts **4.9.6** under `@crane/contracts/external/openzeppelin-contracts`.  
**OZ Upgradeable:** present under `@crane/contracts/external/openzeppelin-upgradeable` (gap-fill only if domain vendor needs missing symbols).  
**Solady:** `@crane/contracts/external/solady` (ether.fi domain only if needed).

## Upstream name → Crane import path

| Upstream / need | Existing `@crane/` path |
|-----------------|-------------------------|
| IERC20 / SafeERC20 | `@crane/contracts/interfaces/IERC20.sol`, `@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol` |
| IERC20Metadata | `@crane/contracts/interfaces/IERC20Metadata.sol` |
| IERC4626 | `@crane/contracts/interfaces/IERC4626.sol` |
| IRateProvider (Balancer shape) | `@crane/contracts/protocols/dexes/balancer/common/interfaces/IRateProvider.sol` |
| IWETH / WETH9 | `@crane/contracts/interfaces/protocols/tokens/wrappers/weth/v9/IWETH.sol` |
| OZ Math / Address / Context | `@crane/contracts/external/openzeppelin-contracts/contracts/...` |
| OZ Upgradeable Initializable etc. | `@crane/contracts/external/openzeppelin-upgradeable/...` |
| Solady utils | `@crane/contracts/external/solady/src/...` |
| FraxETH interfaces (existing) | `@crane/contracts/protocols/tokens/stable/frax/FraxETH/{IfrxETH,IfrxETHMinter,IsfrxETH}.sol` |
| Deposit contract (this package) | `@crane/contracts/protocols/staking/ethereum/common/interfaces/IDepositContract.sol` |
| forge-std (tests only) | Foundry / existing remaps — do not re-vendor |

## Service surface symbols (all present)

- `IERC20`, `BetterSafeERC20` (`safeTransfer` / `safeApprove` / `forceApprove` patterns)
- `IERC4626` for sfrxETH deposit/redeem previews
- `IRateProvider.getRate()` for rate helpers

## Explicitly deferred (not in this epic)

EigenLayer, Aragon OS, LayerZero weETH bridge, Uniswap V3 periphery for ether.fi, multi-version OZ 3.x/5.x trees, SSZ/BLS.

## Gap-fill rule

If a protocol domain file fails to compile due to a missing OZ-upgradeable or Solady **file**, copy that single file into the matching `external/` tree and keep imports on existing `@crane/contracts/external/...` paths. Never add remappings.
