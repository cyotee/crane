# ERC20

Crane provides a complete ERC20 implementation (including metadata, permit, and supply controls) as a Diamond Factory Package.

## Package

`ERC20DFPkg`

Constructor receives the pre-deployed `ERC20Facet`.

Deployment arguments (`PkgArgs`):

- name, symbol, decimals
- totalSupply
- recipient (initial holder)
- optionalSalt (for address customization)

The package installs the ERC20 facet and executes initialization that writes name/symbol/decimals and mints the initial supply to the recipient.

## Storage

- `eip.erc.20` for balances, allowances, and metadata.
- `eip.erc.2612` for nonces when the permit facet is installed.

## Reuse

A single `ERC20Facet` deployment is referenced by every ERC20 proxy created from `ERC20DFPkg`. The facet contains the logic for `transfer`, `approve`, `permit`, etc. Each proxy holds only its own balance and allowance mappings under its isolated storage slot.

## Extensions

- `ERC20PermitDFPkg` adds EIP-2612 permit support.
- `ERC4626*DFPkg` variants provide tokenized vault implementations on the same pattern.

All token packages follow the same DFPkg lifecycle: facets are deployed once; packages produce many proxies at deterministic addresses.
