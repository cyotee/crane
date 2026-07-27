# Skipped MetaMorpho upstream tests

| File | Reason | Replacement |
|------|--------|-------------|
| ReentrancyTest.sol | Needs OZ IERC777 / IERC1820 which Crane does not vendor under openzeppelin-contracts | Crane MetaMorphoLifecycle + Blue reentrancy not applicable (vault holds assets; add later if IERC777 expanded) |
| UrdTest.sol | Depends on Universal Rewards Distributor (P2, out of first merge unless needed) | Skip until URD vendored |
| ERC4626ComplianceTest.sol | Needs erc4626-tests harness wiring under morpho_port | Partial coverage via ERC4626Test.sol + Crane MetaMorphoLifecycle |

