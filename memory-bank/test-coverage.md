# Test Coverage Report

## Overview
This report summarizes the current test coverage for the main libraries and contracts in the codebase, based on both automated coverage tools and manual review of the code and test files. It highlights areas with full, partial, or no test coverage, and identifies priorities for achieving full coverage.

---

## Coverage Summary

### Libraries/Contracts with **0% Coverage** (No tests found)
- `ERC2612Repo.sol`
- `ERC2612Target.sol`
- `ERC2612Storage.sol`
- `ERC5267Target.sol`
- `ERC5267Storage.sol`
- `ERC20PermitDFPkg.sol`

*No test files or references found for these contracts/libraries in the current test suite. These are high-priority candidates for new test implementation.*

### Libraries/Contracts with **Partial Coverage** (Some tests, but not 100%)
- `ERC20PermitFacet.sol` (referenced in some test files, but coverage is not complete)
- `ERC20MintBurnOperableFacetDFPkg.sol` (referenced, but not fully covered)
- `ERC20Storage.sol` (referenced, but not fully covered)
- `ERC20PermitStorage.sol` (referenced, but not fully covered)

*These contracts/libraries have some test coverage, but additional tests are needed to reach 100%.*

### Libraries/Contracts with **Full Coverage** (100%)
- `OwnableTarget.sol` (see: `test/foundry/spec/access/ownable/types/OwnableTarget.t.sol`)
- `ERC20Repo.sol` (coverage confirmed by tool, but no direct test file found; may be covered indirectly)

*These contracts/libraries are well-covered and can serve as examples for test structure and thoroughness.*

---

## Notable Gaps & Observations
- Many of the 0% coverage contracts (especially ERC2612 and ERC5267 related) have no test files or references in the current suite. These are likely new or untested modules.
- Some contracts (e.g., `ERC20PermitFacet`, `ERC20MintBurnOperableFacetDFPkg`) are referenced in test files, but coverage is not complete. Review and expand these tests to cover all code paths.
- Some test references are found only in legacy or external test directories (e.g., `pachira-prod/test-old/rebuild/ApeChainLaunch.t.sol`). These may not be run as part of the main suite and should be reviewed for relevance.
- Utility and set libraries (e.g., `UInt256SetRepo`, `StringSetRepo`, etc.) have dedicated tests and appear to be well-covered.

---

## Next Steps
1. **Prioritize writing new tests** for all contracts/libraries with 0% coverage.
2. **Expand existing tests** for contracts/libraries with partial coverage to achieve 100%.
3. **Review legacy/external tests** to ensure they are included in the main test suite or migrated as needed.
4. Use well-covered contracts (like `OwnableTarget.sol`) as templates for new test files.

---

Analysing contracts...
Running tests...

Ran 2 tests for test/foundry/spec/test/stubs/counter/Counter.t.sol:CounterTest
[PASS] testIncrement() (gas: 31828)
[PASS] testSetNumber(uint256) (runs: 256, μ: 32065, ~: 32376)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 46.82ms (33.75ms CPU time)

Ran 3 tests for test/foundry/spec/protocols/balancer/v3/scaffold-eth/pools/ConstantSumFactory.t.sol:ConstantSumFactoryTest
[PASS] testCreatePoolWithDonation() (gas: 2856158)
[PASS] testCreatePoolWithoutDonation() (gas: 2709818)
[PASS] testFactoryPausedState() (gas: 8892)
Suite result: ok. 3 passed; 0 failed; 0 skipped; finished in 252.84ms (27.88ms CPU time)

Ran 11 tests for test/foundry/spec/access/ownable/types/OwnableTarget.t.sol:OwnableTargetTest
[PASS] test_IOwnable_acceptOwnership(address) (runs: 256, μ: 58520, ~: 58520)
[PASS] test_IOwnable_acceptOwnership_NotProposed(address) (runs: 256, μ: 28778, ~: 28778)
[PASS] test_IOwnable_acceptOwnership_NotProposed_address0() (gas: 27363)
[PASS] test_IOwnable_owner() (gas: 14808)
[PASS] test_IOwnable_proposedOwner(address) (runs: 256, μ: 52421, ~: 52421)
[PASS] test_IOwnable_renounceOwnership() (gas: 30630)
[PASS] test_IOwnable_renounceOwnership_proposed_owner(address) (runs: 256, μ: 56920, ~: 56920)
[PASS] test_IOwnable_transferOwnership(address) (runs: 256, μ: 54673, ~: 54673)
[PASS] test_IOwnable_transferOwnership_NotOwner(address,address) (runs: 256, μ: 29626, ~: 29626)
[PASS] test_IOwnable_transferOwnership_NotOwner_address0(address) (runs: 256, μ: 28208, ~: 28208)
[PASS] test_IOwnable_transferOwnership_NotProposed_address0() (gas: 28102)
Suite result: ok. 11 passed; 0 failed; 0 skipped; finished in 1.69s (1.67s CPU time)

Ran 2 tests for test/foundry/spec/protocols/dexes/camelot/v2/libs/CamelotV2Service.t.sol:CamelotV2ServiceTest
[PASS] test_deposit_first(uint256,uint256) (runs: 256, μ: 546343, ~: 545450)
[PASS] test_deposit_second_static() (gas: 711028)
Suite result: ok. 2 passed; 0 failed; 0 skipped; finished in 3.62s (1.38s CPU time)

Ran 8 tests for test/foundry/spec/utils/collections/sets/UInt256SetRepo.t.sol:UInt256SetRepoTest
[PASS] test_add(uint256) (runs: 256, μ: 92629, ~: 93253)
[PASS] test_add(uint256[]) (runs: 256, μ: 5488213, ~: 5259410)
[PASS] test_contains(uint256[]) (runs: 256, μ: 5426885, ~: 5119025)
[PASS] test_index(uint256[]) (runs: 256, μ: 5591382, ~: 5275403)
[PASS] test_indexOf(uint256[]) (runs: 256, μ: 5552787, ~: 5238746)
[PASS] test_length(uint256[]) (runs: 256, μ: 5369346, ~: 5064525)
[PASS] test_remove(uint256) (runs: 256, μ: 51460, ~: 51723)
[PASS] test_remove(uint256[]) (runs: 256, μ: 4689466, ~: 4426379)
Suite result: ok. 8 passed; 0 failed; 0 skipped; finished in 8.57s (12.18s CPU time)

Ran 9 tests for test/foundry/spec/utils/collections/sets/StringSetRepo.t.sol:StringSetRepoTest
[PASS] test_add(string) (runs: 256, μ: 97177, ~: 96372)
[PASS] test_add(string[]) (runs: 256, μ: 9389483, ~: 9777573)
[PASS] test_addExclusive(string) (runs: 256, μ: 97258, ~: 96456)
[PASS] test_contains(string[]) (runs: 256, μ: 8987645, ~: 9355577)
[PASS] test_index(string[]) (runs: 256, μ: 9331781, ~: 9723257)
[PASS] test_indexOf(string[]) (runs: 256, μ: 9179697, ~: 9561510)
[PASS] test_length(string[]) (runs: 256, μ: 8837833, ~: 9194688)
[PASS] test_remove(string) (runs: 256, μ: 74173, ~: 73632)
[PASS] test_remove(string[]) (runs: 256, μ: 8663347, ~: 9201808)
Suite result: ok. 9 passed; 0 failed; 0 skipped; finished in 11.66s (40.06s CPU time)

Ran 10 tests for test/foundry/spec/protocols/balancer/v3/vault/VaultFactory.t.sol:VaultFactoryTest
[PASS] testCreateMismatch() (gas: 251625)
[PASS] testCreateNotAuthorized() (gas: 195065)
[PASS] testCreateTwice() (gas: 57718178)
[PASS] testCreateVaultHardcodedSalt() (gas: 25077385)
[PASS] testCreateVaultHardcodedSaltWrongDeployer() (gas: 1930511)
[PASS] testCreateVault__Fuzz(bytes32) (runs: 100, μ: 28748516, ~: 28748516)
[PASS] testInvalidFeeController() (gas: 245835)
[PASS] testInvalidVaultAdminBytecode() (gas: 161436)
[PASS] testInvalidVaultBytecode() (gas: 104483)
[PASS] testInvalidVaultExtensionBytecode() (gas: 141059)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 49.21s (1.54s CPU time)

Ran 10 tests for test/foundry/spec/utils/collections/sets/Bytes32SetRepo.t.sol:Bytes32SetRepoTest
[PASS] test_add(bytes32) (runs: 256, μ: 71079, ~: 71079)
[PASS] test_add(bytes32[]) (runs: 256, μ: 5782229, ~: 6013146)
[PASS] test_addExclusive(bytes32) (runs: 256, μ: 71157, ~: 71157)
[PASS] test_addExclusive(bytes32[]) (runs: 256, μ: 19567778, ~: 12643448)
[PASS] test_contains(bytes32[]) (runs: 256, μ: 5664797, ~: 5870669)
[PASS] test_index(bytes32[]) (runs: 256, μ: 5822282, ~: 6033251)
[PASS] test_indexOf(bytes32[]) (runs: 256, μ: 5793079, ~: 6003094)
[PASS] test_length(bytes32[]) (runs: 256, μ: 5606141, ~: 5809966)
[PASS] test_remove(bytes32) (runs: 256, μ: 51706, ~: 51677)
[PASS] test_remove(bytes32[]) (runs: 256, μ: 4818924, ~: 4981222)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 49.21s (61.03s CPU time)

Ran 10 tests for test/foundry/spec/utils/collections/sets/Bytes4SetRepo.t.sol:Bytes4SetRepoTest
[PASS] test_add(bytes4) (runs: 256, μ: 62603, ~: 71387)
[PASS] test_add(bytes4[]) (runs: 256, μ: 2332695, ~: 1228603)
[PASS] test_addExclusive(bytes4) (runs: 256, μ: 62570, ~: 71354)
[PASS] test_addExclusive(bytes4[]) (runs: 256, μ: 31330373, ~: 23545231)
[PASS] test_contains(bytes4[]) (runs: 256, μ: 2284226, ~: 1184389)
[PASS] test_index(bytes4[]) (runs: 256, μ: 2489537, ~: 1412453)
[PASS] test_indexOf(bytes4[]) (runs: 256, μ: 2446001, ~: 1369799)
[PASS] test_length(bytes4[]) (runs: 256, μ: 2192100, ~: 1155465)
[PASS] test_remove(bytes4) (runs: 256, μ: 45264, ~: 52288)
[PASS] test_remove(bytes4[]) (runs: 256, μ: 2147650, ~: 1222023)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 84.69s (103.13s CPU time)

Ran 10 tests for test/foundry/spec/utils/collections/sets/AddressSetRepo.t.sol:AddressSetRepoTest
[PASS] test_add(address) (runs: 256, μ: 71194, ~: 71350)
[PASS] test_add(address[]) (runs: 256, μ: 5991338, ~: 5974924)
[PASS] test_addExclusive(address) (runs: 256, μ: 71270, ~: 71426)
[PASS] test_addExclusive(address[]) (runs: 256, μ: 31195126, ~: 20995581)
[PASS] test_contains(address[]) (runs: 256, μ: 5904545, ~: 5882458)
[PASS] test_index(address[]) (runs: 256, μ: 6130513, ~: 6108243)
[PASS] test_indexOf(address[]) (runs: 256, μ: 6075020, ~: 6052803)
[PASS] test_length(address[]) (runs: 256, μ: 5805379, ~: 5783365)
[PASS] test_remove(address) (runs: 256, μ: 51955, ~: 52064)
[PASS] test_remove(address[]) (runs: 256, μ: 5132373, ~: 5114035)
Suite result: ok. 10 passed; 0 failed; 0 skipped; finished in 86.09s (101.92s CPU time)

Ran 10 test suites in 86.10s (295.05s CPU time): 75 tests passed, 0 failed, 0 skipped (75 total tests)

╭-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------╮
| File                                                                                          | % Lines           | % Statements      | % Branches      | % Funcs           |
+=============================================================================================================================================================================+
| contracts/access/erc2612/libs/ERC2612Repo.sol                                                 | 0.00% (0/8)       | 0.00% (0/6)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/erc2612/storage/ERC2612Storage.sol                                           | 0.00% (0/14)      | 0.00% (0/12)      | 0.00% (0/1)     | 0.00% (0/5)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/erc2612/targets/ERC2612Target.sol                                            | 0.00% (0/13)      | 0.00% (0/14)      | 0.00% (0/2)     | 0.00% (0/3)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/erc5267/storage/ERC5267Storage.sol                                           | 0.00% (0/4)       | 0.00% (0/2)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/erc5267/targets/ERC5267Target.sol                                            | 0.00% (0/2)       | 0.00% (0/1)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/operable/facets/OperableEmbeddedOwnableFacet.sol                             | 0.00% (0/13)      | 0.00% (0/11)      | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/operable/facets/OperableFacet.sol                                            | 66.67% (6/9)      | 71.43% (5/7)      | 100.00% (0/0)   | 50.00% (1/2)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/operable/facets/OperableManagerFacet.sol                                     | 0.00% (0/7)       | 0.00% (0/5)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/operable/libs/OperableRepo.sol                                               | 25.00% (2/8)      | 16.67% (1/6)      | 100.00% (0/0)   | 25.00% (1/4)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/operable/modifiers/OperableModifiers.sol                                     | 16.67% (4/24)     | 20.83% (5/24)     | 0.00% (0/4)     | 25.00% (1/4)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/operable/storage/OperableStorage.sol                                         | 46.67% (14/30)    | 44.00% (11/25)    | 100.00% (0/0)   | 50.00% (6/12)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/operable/targets/OperableManagerTarget.sol                                   | 0.00% (0/4)       | 0.00% (0/4)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/operable/targets/OperableTarget.sol                                          | 0.00% (0/10)      | 0.00% (0/8)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/ownable/facets/OwnableFacet.sol                                              | 70.00% (7/10)     | 75.00% (6/8)      | 100.00% (0/0)   | 50.00% (1/2)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/ownable/libs/OwnableRepo.sol                                                 | 25.00% (2/8)      | 16.67% (1/6)      | 100.00% (0/0)   | 25.00% (1/4)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/ownable/modifiers/OwnableModifiers.sol                                       | 83.33% (5/6)      | 75.00% (3/4)      | 50.00% (1/2)    | 100.00% (2/2)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/ownable/storage/OwnableStorage.sol                                           | 97.14% (34/35)    | 96.67% (29/30)    | 75.00% (3/4)    | 100.00% (8/8)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/ownable/targets/OwnableTarget.sol                                            | 100.00% (10/10)   | 100.00% (8/8)     | 100.00% (0/0)   | 100.00% (5/5)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/ownable/test/stubs/OwnableTargetStub.sol                                     | 100.00% (2/2)     | 100.00% (1/1)     | 100.00% (0/0)   | 100.00% (1/1)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/reentrancy/facets/ReentrancyLockFacet.sol                                    | 0.00% (0/6)       | 0.00% (0/4)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/reentrancy/libs/ReentrancyLockRepo.sol                                       | 0.00% (0/8)       | 0.00% (0/6)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/reentrancy/modifiers/ReentrancyLockModifiers.sol                             | 0.00% (0/5)       | 0.00% (0/4)       | 0.00% (0/1)     | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/reentrancy/storage/ReentrancyLockStorage.sol                                 | 0.00% (0/8)       | 0.00% (0/5)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/access/reentrancy/targets/ReentrancyLockTarget.sol                                  | 0.00% (0/2)       | 0.00% (0/2)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/cryptography/ecdsa/ECDSA.sol                                                        | 0.00% (0/42)      | 0.00% (0/42)      | 0.00% (0/11)    | 0.00% (0/7)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/cryptography/eip712/libs/EIP712Repo.sol                                             | 0.00% (0/8)       | 0.00% (0/6)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/cryptography/eip712/storage/EIP712Storage.sol                                       | 0.00% (0/22)      | 0.00% (0/23)      | 0.00% (0/2)     | 0.00% (0/7)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/cryptography/hash/MessageHashUtils.sol                                              | 0.00% (0/15)      | 0.00% (0/12)      | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/aware/behaviors/ICreate2Aware_Behavior.sol                        | 0.00% (0/115)     | 0.00% (0/97)      | 0.00% (0/4)     | 0.00% (0/33)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/aware/targets/Create2AwareTarget.sol                              | 0.00% (0/2)       | 0.00% (0/1)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/callback/diamondPkg/behaviors/IDiamondFactoryPackage_Behavior.sol | 0.00% (0/229)     | 0.00% (0/221)     | 0.00% (0/18)    | 0.00% (0/37)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/callback/diamondPkg/behaviors/IFacet_Behavior.sol                 | 0.00% (0/59)      | 0.00% (0/47)      | 100.00% (0/0)   | 0.00% (0/17)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/callback/diamondPkg/facets/PostDeployAccountHookFacet.sol         | 66.67% (6/9)      | 66.67% (4/6)      | 100.00% (0/0)   | 66.67% (2/3)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/callback/diamondPkg/libs/utils/DiamondFactoryPackageAdaptor.sol   | 100.00% (8/8)     | 100.00% (7/7)     | 100.00% (0/0)   | 100.00% (3/3)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/callback/diamondPkg/libs/utils/FactoryCallBackAdaptor.sol         | 100.00% (3/3)     | 100.00% (3/3)     | 100.00% (0/0)   | 100.00% (1/1)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/callback/diamondPkg/targets/DiamondPackageCallBackFactory.sol     | 77.42% (48/62)    | 81.82% (45/55)    | 20.00% (1/5)    | 50.00% (5/10)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/callback/targets/Create2CallBackFactoryTarget.sol                 | 81.82% (18/22)    | 80.95% (17/21)    | 0.00% (0/2)     | 80.00% (4/5)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/factories/create2/callback/targets/Create2CallbackContract.sol                      | 100.00% (3/3)     | 100.00% (2/2)     | 100.00% (0/0)   | 100.00% (1/1)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/fixtures/CraneFixture.sol                                                           | 38.15% (66/173)   | 49.65% (70/141)   | 40.91% (9/22)   | 0.00% (0/38)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/fixtures/Fixture.sol                                                                | 16.13% (5/31)     | 27.78% (5/18)     | 100.00% (0/0)   | 0.00% (0/13)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc165/behaviors/IERC165_Behavior.sol                                 | 0.00% (0/45)      | 0.00% (0/44)      | 0.00% (0/2)     | 0.00% (0/12)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc165/libs/ERC165Repo.sol                                            | 100.00% (2/2)     | 100.00% (1/1)     | 100.00% (0/0)   | 100.00% (1/1)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc165/storage/ERC165Storage.sol                                      | 100.00% (5/5)     | 100.00% (6/6)     | 100.00% (0/0)   | 100.00% (2/2)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc165/targets/ERC165Target.sol                                       | 0.00% (0/2)       | 0.00% (0/1)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc2535/behaviors/IDiamondLoupe_Behavior.sol                          | 0.00% (0/112)     | 0.00% (0/118)     | 0.00% (0/6)     | 0.00% (0/31)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc2535/dfPkgs/DiamondCutFacetDFPkg.sol                               | 0.00% (0/41)      | 0.00% (0/32)      | 0.00% (0/3)     | 0.00% (0/10)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc2535/libs/ERC2535Repo.sol                                          | 100.00% (2/2)     | 100.00% (1/1)     | 100.00% (0/0)   | 100.00% (1/1)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc2535/storage/DiamondStorage.sol                                    | 46.55% (27/58)    | 43.08% (28/65)    | 36.36% (4/11)   | 54.55% (6/11)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc2535/targets/DiamondCutTarget.sol                                  | 0.00% (0/2)       | 0.00% (0/1)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/introspection/erc2535/targets/DiamondLoupeTarget.sol                                | 0.00% (0/8)       | 0.00% (0/4)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/networks/arbitrum/apechain/fixtures/ApeChainFixture.sol                             | 0.00% (0/17)      | 0.00% (0/13)      | 0.00% (0/5)     | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/networks/arbitrum/fixtures/ArbOSFixture.sol                                         | 0.00% (0/18)      | 0.00% (0/13)      | 0.00% (0/3)     | 0.00% (0/5)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/balancer/v3/pool-utils/BasePoolFactory.sol                          | 0.00% (0/59)      | 0.00% (0/52)      | 0.00% (0/3)     | 0.00% (0/14)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/balancer/v3/scaffold-eth/hooks/ExitFeeHookExample.sol               | 0.00% (0/29)      | 0.00% (0/30)      | 0.00% (0/4)     | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/balancer/v3/scaffold-eth/hooks/LotteryHookExample.sol               | 0.00% (0/49)      | 0.00% (0/50)      | 0.00% (0/10)    | 0.00% (0/8)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/balancer/v3/scaffold-eth/hooks/VeBALFeeDiscountHookExample.sol      | 0.00% (0/16)      | 0.00% (0/17)      | 0.00% (0/2)     | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/balancer/v3/scaffold-eth/pools/const-sum/ConstantSumFactory.sol     | 100.00% (3/3)     | 100.00% (2/2)     | 100.00% (0/0)   | 100.00% (1/1)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/balancer/v3/scaffold-eth/pools/const-sum/ConstantSumPool.sol        | 40.00% (6/15)     | 33.33% (3/9)      | 100.00% (0/0)   | 42.86% (3/7)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/balancer/v3/vault/BalancerPoolToken.sol                             | 0.00% (0/62)      | 0.00% (0/53)      | 0.00% (0/2)     | 0.00% (0/18)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/balancer/v3/vault/fixtures/BalancerV3VaultFixture.sol               | 0.00% (0/9)       | 0.00% (0/5)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/CamelotFactory.sol                                       | 0.00% (0/56)      | 0.00% (0/47)      | 0.00% (0/26)    | 0.00% (0/11)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/CamelotPair.sol                                          | 0.00% (0/210)     | 0.00% (0/255)     | 0.00% (0/77)    | 0.00% (0/24)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/CamelotRouter.sol                                        | 0.00% (0/108)     | 0.00% (0/122)     | 0.00% (0/27)    | 0.00% (0/19)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/UniswapV2ERC20.sol                                       | 0.00% (0/38)      | 0.00% (0/32)      | 0.00% (0/5)     | 0.00% (0/9)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/fixtures/CamelotV2Fixture.sol                            | 56.52% (13/23)    | 68.42% (13/19)    | 40.00% (4/10)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/libraries/Math.sol                                       | 0.00% (0/11)      | 0.00% (0/11)      | 0.00% (0/3)     | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/libraries/SafeMath.sol                                   | 0.00% (0/6)       | 0.00% (0/3)       | 0.00% (0/6)     | 0.00% (0/3)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/libraries/TransferHelper.sol                             | 0.00% (0/12)      | 0.00% (0/12)      | 0.00% (0/8)     | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/libraries/UQ112x112.sol                                  | 0.00% (0/4)       | 0.00% (0/2)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/libraries/UniswapV2Library.sol                           | 0.00% (0/21)      | 0.00% (0/22)      | 0.00% (0/10)    | 0.00% (0/5)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/libs/CamelotV2Service.sol                                | 8.16% (4/49)      | 6.12% (3/49)      | 100.00% (0/0)   | 11.11% (1/9)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/libs/CamelotV2Utils.sol                                  | 0.00% (0/83)      | 0.00% (0/114)     | 0.00% (0/17)    | 0.00% (0/17)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v2/tools/CamV2SwapRelayer.sol                               | 0.00% (0/9)       | 0.00% (0/7)       | 0.00% (0/1)     | 0.00% (0/3)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/camelot/v3/utils/CamelotV3Utils.sol                                 | 0.00% (0/13)      | 0.00% (0/18)      | 0.00% (0/3)     | 0.00% (0/3)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/Conversion.sol                                 | 0.00% (0/8)       | 0.00% (0/6)       | 0.00% (0/1)     | 0.00% (0/3)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/FixedPointWadMathLib.sol                       | 0.00% (0/82)      | 0.00% (0/84)      | 0.00% (0/16)    | 0.00% (0/8)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/Math.sol                                       | 0.00% (0/215)     | 0.00% (0/237)     | 0.00% (0/40)    | 0.00% (0/31)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/MathEx.sol                                     | 0.00% (0/165)     | 0.00% (0/185)     | 0.00% (0/18)    | 0.00% (0/27)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/SafeMath.sol                                   | 0.00% (0/37)      | 0.00% (0/35)      | 0.00% (0/6)     | 0.00% (0/13)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/TransferHelper.sol                             | 0.00% (0/12)      | 0.00% (0/12)      | 0.00% (0/8)     | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/UQ112x112.sol                                  | 0.00% (0/4)       | 0.00% (0/2)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/UniswapV2Library.sol                           | 0.00% (0/42)      | 0.00% (0/50)      | 0.00% (0/20)    | 0.00% (0/8)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/deps/libs/WadRayMath.sol                                 | 0.00% (0/31)      | 0.00% (0/35)      | 0.00% (0/6)     | 0.00% (0/10)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/libs/BetterUniV2Service.sol                              | 0.00% (0/56)      | 0.00% (0/59)      | 100.00% (0/0)   | 0.00% (0/9)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/libs/BetterUniV2Utils.sol                                | 0.00% (0/68)      | 0.00% (0/71)      | 0.00% (0/6)     | 0.00% (0/15)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/stubs/UniV2FactoryStub.sol                               | 0.00% (0/23)      | 0.00% (0/20)      | 0.00% (0/10)    | 0.00% (0/5)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/stubs/UniV2PairStub.sol                                  | 0.00% (0/138)     | 0.00% (0/152)     | 0.00% (0/40)    | 0.00% (0/23)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/stubs/UniV2Router02Stub.sol                              | 0.00% (0/162)     | 0.00% (0/175)     | 0.00% (0/47)    | 0.00% (0/28)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v2/utils/relayer/targets/SwapRelayer.sol                    | 0.00% (0/9)       | 0.00% (0/5)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/dexes/uniswap/v3/libs/BetterUniV3Utils.sol                                | 0.00% (0/13)      | 0.00% (0/18)      | 0.00% (0/3)     | 0.00% (0/3)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/launchpads/ape-express/stubs/MockDegenFactory.sol                         | 0.00% (0/5)       | 0.00% (0/3)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/protocols/tokens/wrappers/weth/v9/WETH9.sol                                         | 0.00% (0/27)      | 0.00% (0/23)      | 0.00% (0/7)     | 0.00% (0/7)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/proxies/MinimalDiamondCallBackProxy.sol                                             | 100.00% (8/8)     | 100.00% (7/7)     | 100.00% (0/0)   | 100.00% (2/2)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/proxies/Proxy.sol                                                                   | 81.82% (9/11)     | 76.92% (10/13)    | 0.00% (0/1)     | 100.00% (1/1)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/script/CraneScript.sol                                                              | 0.00% (0/10)      | 0.00% (0/8)       | 100.00% (0/0)   | 0.00% (0/5)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/script/networks/arbitrum/ArbOSScript.sol                                            | 0.00% (0/1)       | 100.00% (0/0)     | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/script/networks/arbitrum/apeChain/ApeChainScript.sol                                | 0.00% (0/1)       | 100.00% (0/0)     | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/CraneTest.sol                                                                  | 0.00% (0/40)      | 0.00% (0/46)      | 0.00% (0/2)     | 0.00% (0/11)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/behavior/Behavior.sol                                                          | 0.00% (0/6)       | 0.00% (0/6)       | 100.00% (0/0)   | 0.00% (0/3)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/comparators/Comparator.sol                                                     | 0.00% (0/8)       | 0.00% (0/6)       | 0.00% (0/2)     | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/comparators/erc2535/FacetsComparator.sol                                       | 0.00% (0/49)      | 0.00% (0/51)      | 0.00% (0/6)     | 0.00% (0/6)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/comparators/sets/AddressSetComparator.sol                                      | 0.00% (0/40)      | 0.00% (0/36)      | 0.00% (0/3)     | 0.00% (0/10)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/comparators/sets/Bytes4SetComparator.sol                                       | 0.00% (0/54)      | 0.00% (0/52)      | 0.00% (0/3)     | 0.00% (0/9)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/comparators/sets/SetComparator.sol                                             | 0.00% (0/26)      | 0.00% (0/18)      | 0.00% (0/4)     | 0.00% (0/6)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/fuzzing/constraints/AddressFuzzingConstraints.sol                              | 50.94% (27/53)    | 47.62% (20/42)    | 100.00% (0/0)   | 45.00% (9/20)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/networks/arbitrum/ArbOSTest.sol                                                | 0.00% (0/4)       | 0.00% (0/2)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/networks/arbitrum/apeChain/ApeChainTest.sol                                    | 0.00% (0/1)       | 100.00% (0/0)     | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/networks/arbitrum/apeChain/CurtisTest.sol                                      | 0.00% (0/1)       | 100.00% (0/0)     | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/networks/arbitrum/stubs/precompiles/ArbOwnerPublicStub.sol                     | 0.00% (0/48)      | 0.00% (0/31)      | 100.00% (0/0)   | 0.00% (0/19)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/stubs/counter/Counter.sol                                                      | 100.00% (4/4)     | 100.00% (2/2)     | 100.00% (0/0)   | 100.00% (2/2)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/stubs/greeter/dfPkgs/GreeterFacetDiamondFactoryPackage.sol                     | 0.00% (0/17)      | 0.00% (0/10)      | 100.00% (0/0)   | 0.00% (0/8)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/stubs/greeter/facets/GreeterFacet.sol                                          | 0.00% (0/7)       | 0.00% (0/5)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/stubs/greeter/libs/GreeterRepo.sol                                             | 0.00% (0/2)       | 0.00% (0/1)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/stubs/greeter/storage/GreeterStorage.sol                                       | 0.00% (0/5)       | 0.00% (0/4)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/stubs/greeter/stubs/GreeterStub.sol                                            | 0.00% (0/2)       | 0.00% (0/1)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/stubs/greeter/targets/GreeterTarget.sol                                        | 0.00% (0/6)       | 0.00% (0/4)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/test/stubs/lock/Lock.sol                                                            | 0.00% (0/9)       | 0.00% (0/7)       | 0.00% (0/6)     | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/dfPkgs/ERC20MintBurnOperableFacetDFPkg.sol                             | 91.67% (33/36)    | 100.00% (28/28)   | 100.00% (0/0)   | 66.67% (6/9)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/dfPkgs/ERC20PermitDFPkg.sol                                            | 0.00% (0/56)      | 0.00% (0/46)      | 0.00% (0/18)    | 0.00% (0/8)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/facets/ERC20PermitFacet.sol                                            | 75.00% (15/20)    | 77.78% (14/18)    | 100.00% (0/0)   | 50.00% (1/2)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/libs/ERC20Repo.sol                                                     | 100.00% (2/2)     | 100.00% (1/1)     | 100.00% (0/0)   | 100.00% (1/1)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/libs/SafeERC20.sol                                                     | 0.00% (0/25)      | 0.00% (0/26)      | 0.00% (0/7)     | 0.00% (0/7)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/storage/ERC20MintBurnOperableStorage.sol                               | 50.00% (6/12)     | 41.67% (5/12)     | 100.00% (1/1)   | 50.00% (1/2)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/storage/ERC20PermitStorage.sol                                         | 0.00% (0/6)       | 0.00% (0/4)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/storage/ERC20Storage.sol                                               | 50.00% (39/78)    | 53.85% (28/52)    | 14.29% (1/7)    | 46.43% (13/28)    |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/targets/ERC20MintBurnOperableTarget.sol                                | 50.00% (3/6)      | 50.00% (2/4)      | 100.00% (0/0)   | 50.00% (1/2)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/tokens/erc20/targets/ERC20Target.sol                                                | 46.67% (14/30)    | 47.37% (9/19)     | 100.00% (0/0)   | 45.45% (5/11)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/Creation.sol                                                                  | 81.82% (9/11)     | 85.71% (6/7)      | 50.00% (1/2)    | 75.00% (3/4)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/collections/Array.sol                                                         | 9.68% (3/31)      | 5.71% (2/35)      | 0.00% (0/11)    | 14.29% (1/7)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/collections/sets/AddressSetRepo.sol                                           | 46.84% (37/79)    | 39.33% (35/89)    | 31.25% (5/16)   | 60.00% (9/15)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/collections/sets/Bytes32SetRepo.sol                                           | 84.09% (37/44)    | 82.50% (33/40)    | 71.43% (5/7)    | 81.82% (9/11)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/collections/sets/Bytes4SetRepo.sol                                            | 68.52% (37/54)    | 68.00% (34/50)    | 71.43% (5/7)    | 64.29% (9/14)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/collections/sets/IERC20SetRepo.sol                                            | 0.00% (0/79)      | 0.00% (0/89)      | 0.00% (0/16)    | 0.00% (0/15)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/collections/sets/StringSetRepo.sol                                            | 82.50% (33/40)    | 81.08% (30/37)    | 57.14% (4/7)    | 80.00% (8/10)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/collections/sets/UInt256SetRepo.sol                                           | 60.00% (30/50)    | 60.87% (28/46)    | 50.00% (4/8)    | 53.85% (7/13)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/ABDKMath64x64.sol                                                        | 0.00% (0/358)     | 0.00% (0/491)     | 0.00% (0/191)   | 0.00% (0/27)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/BetterMath.sol                                                           | 20.35% (35/172)   | 19.32% (34/176)   | 34.78% (8/23)   | 4.88% (2/41)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/ConstProdUtils.sol                                                       | 6.40% (8/125)     | 6.29% (11/175)    | 6.25% (2/32)    | 5.56% (1/18)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/VirtBalConstProdUtils.sol                                                | 0.00% (0/67)      | 0.00% (0/76)      | 0.00% (0/9)     | 0.00% (0/16)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/power-calc/facets/PowerCalculatorAwareFacet.sol                          | 0.00% (0/6)       | 0.00% (0/4)       | 100.00% (0/0)   | 0.00% (0/2)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/power-calc/libs/PowerCalculatorAwareRepo.sol                             | 0.00% (0/2)       | 0.00% (0/1)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/power-calc/libs/PowerRepo.sol                                            | 0.00% (0/8)       | 0.00% (0/6)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/power-calc/storage/PowerCalculatorAwareStorage.sol                       | 0.00% (0/8)       | 0.00% (0/5)       | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/power-calc/storage/PowerStorage.sol                                      | 0.00% (0/275)     | 0.00% (0/365)     | 0.00% (0/31)    | 0.00% (0/9)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/power-calc/targets/PowerCalculator.sol                                   | 0.00% (0/16)      | 0.00% (0/15)      | 100.00% (0/0)   | 0.00% (0/8)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/math/power-calc/targets/PowerCalculatorAwareTarget.sol                        | 0.00% (0/2)       | 0.00% (0/2)       | 100.00% (0/0)   | 0.00% (0/1)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/primitives/Address.sol                                                        | 42.86% (18/42)    | 46.67% (14/30)    | 18.75% (3/16)   | 38.46% (5/13)     |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/primitives/Bytecode.sol                                                       | 8.47% (5/59)      | 6.35% (4/63)      | 12.50% (1/8)    | 6.25% (1/16)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/primitives/Bytes.sol                                                          | 0.00% (0/125)     | 0.00% (0/128)     | 0.00% (0/26)    | 0.00% (0/14)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/primitives/Bytes32.sol                                                        | 0.00% (0/13)      | 0.00% (0/14)      | 100.00% (0/0)   | 0.00% (0/3)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/primitives/Bytes4.sol                                                         | 0.00% (0/29)      | 0.00% (0/36)      | 0.00% (0/1)     | 0.00% (0/5)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/primitives/String.sol                                                         | 0.00% (0/14)      | 0.00% (0/10)      | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/primitives/UInt.sol                                                           | 25.00% (9/36)     | 29.55% (13/44)    | 25.00% (1/4)    | 16.67% (1/6)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/storage/ShortStrings.sol                                                      | 0.00% (0/29)      | 0.00% (0/33)      | 0.00% (0/8)     | 0.00% (0/6)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/storage/StorageSlot.sol                                                       | 0.00% (0/16)      | 0.00% (0/8)       | 100.00% (0/0)   | 0.00% (0/8)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/vm/arbOS/stubs/precompiles/ArbOwnerPublicStub.sol                             | 0.00% (0/48)      | 0.00% (0/31)      | 100.00% (0/0)   | 0.00% (0/19)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/vm/foundry/FoundryVM.sol                                                      | 0.00% (0/91)      | 0.00% (0/70)      | 0.00% (0/10)    | 0.00% (0/30)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/vm/foundry/tools/DeclaredAddrs.sol                                            | 45.45% (5/11)     | 55.56% (5/9)      | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/vm/foundry/tools/console/betterconsole.sol                                    | 5.48% (4/73)      | 4.35% (2/46)      | 0.00% (0/1)     | 6.90% (2/29)      |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| contracts/utils/vm/foundry/tools/terminal/terminal.sol                                        | 0.00% (0/19)      | 0.00% (0/18)      | 100.00% (0/0)   | 0.00% (0/4)       |
|-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------|
| Total                                                                                         | 12.13% (735/6059) | 10.74% (657/6118) | 6.03% (63/1044) | 12.17% (158/1298) |
╰-----------------------------------------------------------------------------------------------+-------------------+-------------------+-----------------+-------------------╯