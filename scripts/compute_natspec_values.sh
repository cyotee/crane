#!/bin/bash
# Central NatSpec Computation Pass for Crane
# Usage: ./scripts/compute_natspec_values.sh [symbol1] [symbol2] ...
#
# PRIMARY (LR-1): Use the dedicated Foundry Script:
#   forge script scripts/foundry/ComputeNatSpecValues.s.sol --sig "run()" -vvv
#   This uses compiler (type(I).interfaceId + keccak) for selectors/IDs/topic0. Reproducible, CI friendly.
#
# This bash helper remains for quick ad-hoc selector/topic0 via cast (cast sig / cast keccak are equivalent to compiler for those).
# Always cross-check final values by running the .s.sol script or including in a Foundry test.
# Values feed CENTRALLY_COMPUTED_NATSPEC_VALUES.md (use ONLY those in docs/sources).

echo "=== Crane Central NatSpec Value Calculator ==="
echo "Computes @custom:selector, @custom:signature, @custom:topiczero"
echo ""

if [ $# -gt 0 ]; then
  for item in "$@"; do
    if echo "$item" | grep -q '('; then
      if echo "$item" | grep -qi '^event:'; then
        sig="${item#event:}"
        val=$(cast keccak "$sig" 2>/dev/null || echo "ERROR")
        echo "topic0($sig) = $val"
      else
        val=$(cast sig "$item" 2>/dev/null || echo "ERROR")
        echo "selector($item) = $val"
      fi
    else
      echo "Other: $item (use Solidity type(I).interfaceId for IDs)"
    fi
  done
else
  echo "No args provided. Computing common ones from PRD and gold standard (ERC8023 + Factories)..."
  echo ""
  
  # ERC8023 gold standard
  for s in "initiateOwnershipTransfer(address)" "confirmOwnershipTransfer(address)" "cancelPendingOwnershipTransfer()" "acceptOwnershipTransfer()" "owner()" "pendingOwner()" "preConfirmedOwner()" "getOwnershipTransferBuffer()"; do
    val=$(cast sig "$s" 2>/dev/null || echo "ERROR")
    echo "selector($s) = $val"
  done
  
  echo ""
  for e in "OwnershipTransferInitiated(address,address)" "OwnershipTransferConfirmed(address,address)" "OwnershipTransferred(address,address)"; do
    val=$(cast keccak "$e" 2>/dev/null || echo "ERROR")
    echo "topic0($e) = $val"
  done
  
  echo ""
  # IDiamondFactoryPackage / IFacet
  for s in "packageName()" "facetInterfaces()" "facetAddresses()" "packageMetadata()" "facetCuts()" "diamondConfig()" "calcSalt(bytes)" "processArgs(bytes)" "updatePkg(address,bytes)" "initAccount(bytes)" "postDeploy(address)" "facetName()" "facetFuncs()" "facetMetadata()"; do
    val=$(cast sig "$s" 2>/dev/null || echo "ERROR")
    echo "selector($s) = $val"
  done
  
  echo ""
  echo "For full interfaceId (mandatory per LR-1): run the dedicated Foundry Script:"
  echo "  forge script scripts/foundry/ComputeNatSpecValues.s.sol --sig \"run()\" -vvv"
  echo "  (Uses type(I).interfaceId in compiled script for accuracy; see script source for more.)"
fi

echo ""
echo "=== Use values (from script or this) + CENTRALLY_COMPUTED_NATSPEC_VALUES.md to populate gap reports and NatSpec ==="
