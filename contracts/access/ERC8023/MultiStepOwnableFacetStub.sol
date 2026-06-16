// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {MultiStepOwnableRepo} from "@crane/contracts/access/ERC8023/MultiStepOwnableRepo.sol";
import {MultiStepOwnableFacet} from "@crane/contracts/access/ERC8023/MultiStepOwnableFacet.sol";

// tag::MultiStepOwnableFacetStub[]
/**
 * @title MultiStepOwnableFacetStub - Test stub for MultiStepOwnableFacet.
 * @author cyotee doge <not_cyotee@proton.me>
 * @notice Test stub providing a concrete initialized instance of MultiStepOwnableFacet (which implements IFacet and IMultiStepOwnable) for use in tests.
 * @dev Not intended for production use. Initialization is performed directly in the constructor.
 *      Inherits full IFacet + IMultiStepOwnable surface; modeled on OperableTargetStub + recent closed stubs.
 */
contract MultiStepOwnableFacetStub is MultiStepOwnableFacet {
    // tag::constructor(address-uint256)[]
    /**
     * @notice Constructs the stub and initializes ownership via the Repo.
     * @dev Direct call to MultiStepOwnableRepo._initialize (for test setup convenience, not via package initAccount).
     * @param initialOwner The initial owner of the contract, set at deployment.
     * @param ownershipBufferPeriod Period (seconds) that must elapse between initiate and confirm.
     */
    constructor(address initialOwner, uint256 ownershipBufferPeriod) {
        MultiStepOwnableRepo._initialize(initialOwner, ownershipBufferPeriod);
    }
    // end::constructor(address-uint256)[]
}
// end::MultiStepOwnableFacetStub[]
