// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "./TestBase_OpenGSNFork.sol";

/**
 * @title OpenGSNForwarder_Fork
 * @notice Fork parity tests comparing ported Forwarder to upstream OpenGSN
 * @dev Tests verify that our ported Forwarder behaves equivalently to upstream
 *
 * Parity assertions cover:
 * - Domain separator / EIP-712 domain values
 * - getNonce(from) behavior
 * - verify(request, signature) - valid and invalid cases
 * - execute(request, signature) - success and revert paths
 * - Appended sender semantics on recipient side
 */
contract OpenGSNForwarder_Fork is TestBase_OpenGSNFork {
    /* -------------------------------------------------------------------------- */
    /*                          Domain Separator Parity                           */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify domain separators are computed correctly
     * @dev Both forwarders should produce valid domain separators when registered
     */
    function test_domainSeparator_registration() public view {
        // Both forwarders should have their domain separators registered
        assertTrue(portedForwarder.domains(portedDomainSeparator), "Ported domain not registered");
        assertTrue(upstreamForwarder.domains(upstreamDomainSeparator), "Upstream domain not registered");
    }

    /**
     * @notice Verify EIP-712 domain computation matches expected format
     */
    function test_domainSeparator_computation() public view {
        // Manually compute expected domain separators
        bytes32 expectedPorted = _computeDomainSeparator(address(portedForwarder));
        bytes32 expectedUpstream = _computeDomainSeparator(address(upstreamForwarder));

        assertEq(portedDomainSeparator, expectedPorted, "Ported domain mismatch");
        assertEq(upstreamDomainSeparator, expectedUpstream, "Upstream domain mismatch");
    }

    /**
     * @notice Verify type hashes are registered after construction
     */
    function test_requestTypeHash_registered() public view {
        assertTrue(portedForwarder.typeHashes(portedRequestTypeHash), "Ported type hash not registered");
        // Both forwarders are the same contract, so they share the same auto-registered type hash
        assertTrue(upstreamForwarder.typeHashes(upstreamRequestTypeHash), "Upstream type hash not registered");
    }

    /* -------------------------------------------------------------------------- */
    /*                              getNonce Parity                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify getNonce returns 0 for new addresses
     */
    function test_getNonce_initial() public {
        address newUser = makeAddr("newUser");

        uint256 portedNonce = portedForwarder.getNonce(newUser);
        uint256 upstreamNonce = upstreamForwarder.getNonce(newUser);

        assertEq(portedNonce, 0, "Ported initial nonce should be 0");
        assertEq(upstreamNonce, 0, "Upstream initial nonce should be 0");
        assertEq(portedNonce, upstreamNonce, "Initial nonce parity mismatch");
    }

    /**
     * @notice Verify nonce increments after successful execute
     */
    function test_getNonce_incrementsAfterExecute() public {
        // Build and sign requests
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        IUpstreamForwarder.ForwardRequest memory upstreamReq =
            _buildUpstreamRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory upstreamSig = _signUpstreamRequest(upstreamReq, SIGNER_PK);

        // Execute on both
        portedForwarder.execute(portedReq, portedDomainSeparator, portedRequestTypeHash, "", portedSig);
        upstreamForwarder.execute(
            upstreamReq, upstreamDomainSeparator, upstreamRequestTypeHash, "", upstreamSig
        );

        // Both should have incremented nonce
        uint256 portedNonce = portedForwarder.getNonce(signer);
        uint256 upstreamNonce = upstreamForwarder.getNonce(signer);

        assertEq(portedNonce, 1, "Ported nonce should be 1");
        assertEq(upstreamNonce, 1, "Upstream nonce should be 1");
        assertEq(portedNonce, upstreamNonce, "Nonce parity mismatch after execute");
    }

    /* -------------------------------------------------------------------------- */
    /*                              verify() Parity                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify valid signature passes verification
     */
    function test_verify_validSignature() public view {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        IUpstreamForwarder.ForwardRequest memory upstreamReq =
            _buildUpstreamRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory upstreamSig = _signUpstreamRequest(upstreamReq, SIGNER_PK);

        // Both should pass verification without reverting
        portedForwarder.verify(portedReq, portedDomainSeparator, portedRequestTypeHash, "", portedSig);
        upstreamForwarder.verify(
            upstreamReq, upstreamDomainSeparator, upstreamRequestTypeHash, "", upstreamSig
        );
    }

    /**
     * @notice Verify invalid signature reverts
     */
    function test_verify_invalidSignature_reverts() public {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory badSig = _signPortedRequest(portedReq, 0xBAD); // Wrong key

        IUpstreamForwarder.ForwardRequest memory upstreamReq =
            _buildUpstreamRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory upstreamBadSig = _signUpstreamRequest(upstreamReq, 0xBAD);

        // Both should revert with signature mismatch
        vm.expectRevert("FWD: signature mismatch");
        portedForwarder.verify(portedReq, portedDomainSeparator, portedRequestTypeHash, "", badSig);

        vm.expectRevert("FWD: signature mismatch");
        upstreamForwarder.verify(
            upstreamReq, upstreamDomainSeparator, upstreamRequestTypeHash, "", upstreamBadSig
        );
    }

    /**
     * @notice Verify wrong nonce reverts
     */
    function test_verify_wrongNonce_reverts() public {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        // Build request with nonce 999 (should be 0)
        IForwarder.ForwardRequest memory portedReq = IForwarder.ForwardRequest({
            from: signer,
            to: address(recipient),
            value: 0,
            gas: 100_000,
            nonce: 999, // Wrong nonce
            data: callData,
            validUntilTime: block.timestamp + 1 hours
        });
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        IUpstreamForwarder.ForwardRequest memory upstreamReq = IUpstreamForwarder.ForwardRequest({
            from: signer,
            to: address(recipient),
            value: 0,
            gas: 100_000,
            nonce: 999,
            data: callData,
            validUntilTime: block.timestamp + 1 hours
        });
        bytes memory upstreamSig = _signUpstreamRequest(upstreamReq, SIGNER_PK);

        // Both should revert with nonce mismatch
        vm.expectRevert("FWD: nonce mismatch");
        portedForwarder.verify(portedReq, portedDomainSeparator, portedRequestTypeHash, "", portedSig);

        vm.expectRevert("FWD: nonce mismatch");
        upstreamForwarder.verify(
            upstreamReq, upstreamDomainSeparator, upstreamRequestTypeHash, "", upstreamSig
        );
    }

    /**
     * @notice Verify unregistered domain separator reverts
     */
    function test_verify_unregisteredDomain_reverts() public {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        bytes32 fakeDomain = keccak256("fake domain");

        vm.expectRevert("FWD: unregistered domain sep.");
        portedForwarder.verify(portedReq, fakeDomain, portedRequestTypeHash, "", portedSig);
    }

    /**
     * @notice Verify unregistered type hash reverts
     */
    function test_verify_unregisteredTypeHash_reverts() public {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        bytes32 fakeTypeHash = keccak256("FakeRequest(address from)");

        vm.expectRevert("FWD: unregistered typehash");
        portedForwarder.verify(portedReq, portedDomainSeparator, fakeTypeHash, "", portedSig);
    }

    /* -------------------------------------------------------------------------- */
    /*                              execute() Parity                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify execute success path
     */
    function test_execute_success() public {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 200_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        (bool success, bytes memory ret) =
            portedForwarder.execute(portedReq, portedDomainSeparator, portedRequestTypeHash, "", portedSig);

        assertTrue(success, "Execute should succeed");
        assertTrue(ret.length > 0, "Should return data");
    }

    /**
     * @notice Verify execute with target revert returns failure
     */
    function test_execute_targetReverts() public {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubRevert.selector, "Test revert");

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 100_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        (bool success,) =
            portedForwarder.execute(portedReq, portedDomainSeparator, portedRequestTypeHash, "", portedSig);

        assertFalse(success, "Execute should return failure for reverted call");
    }

    /**
     * @notice Verify execute with ETH value transfer
     */
    function test_execute_withValue() public {
        vm.deal(address(this), 1 ether);

        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubValue.selector);

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0.1 ether, 100_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        (bool success, bytes memory ret) =
            portedForwarder.execute{value: 0.1 ether}(portedReq, portedDomainSeparator, portedRequestTypeHash, "", portedSig);

        assertTrue(success, "Execute with value should succeed");
        uint256 receivedValue = abi.decode(ret, (uint256));
        assertEq(receivedValue, 0.1 ether, "Recipient should receive ETH value");
    }

    /* -------------------------------------------------------------------------- */
    /*                         Appended Sender Semantics                          */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify Forwarder appends sender address to calldata
     * @dev The recipient should be able to extract the original sender
     */
    function test_appendedSender_semantics() public {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 200_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        (bool success, bytes memory ret) =
            portedForwarder.execute(portedReq, portedDomainSeparator, portedRequestTypeHash, "", portedSig);

        assertTrue(success, "Execute should succeed");

        // Decode return values
        (address msgSender, address extractedFrom,) = abi.decode(ret, (address, address, bytes));

        // msg.sender should be the forwarder
        assertEq(msgSender, address(portedForwarder), "msg.sender should be forwarder");

        // Extracted 'from' should be the original signer
        assertEq(extractedFrom, signer, "Extracted sender should be original signer");
    }

    /**
     * @notice Verify appended sender parity between ported and upstream
     */
    function test_appendedSender_parity() public {
        bytes memory callData = abi.encodeWithSelector(RecipientStub.stubCall.selector, uint256(42));

        // Execute on ported
        IForwarder.ForwardRequest memory portedReq =
            _buildPortedRequest(signer, address(recipient), 0, 200_000, callData);
        bytes memory portedSig = _signPortedRequest(portedReq, SIGNER_PK);

        (bool portedSuccess, bytes memory portedRet) =
            portedForwarder.execute(portedReq, portedDomainSeparator, portedRequestTypeHash, "", portedSig);

        // Deploy new recipient for upstream test (to reset state)
        RecipientStub upstreamRecipient = new RecipientStub();

        // Execute on upstream
        IUpstreamForwarder.ForwardRequest memory upstreamReq =
            _buildUpstreamRequest(signer, address(upstreamRecipient), 0, 200_000, callData);
        bytes memory upstreamSig = _signUpstreamRequest(upstreamReq, SIGNER_PK);

        (bool upstreamSuccess, bytes memory upstreamRet) = upstreamForwarder.execute(
            upstreamReq, upstreamDomainSeparator, upstreamRequestTypeHash, "", upstreamSig
        );

        // Both should succeed
        assertTrue(portedSuccess, "Ported execute should succeed");
        assertTrue(upstreamSuccess, "Upstream execute should succeed");

        // Decode return values
        (, address portedExtractedFrom,) = abi.decode(portedRet, (address, address, bytes));
        (, address upstreamExtractedFrom,) = abi.decode(upstreamRet, (address, address, bytes));

        // Both should extract the same original sender
        assertEq(portedExtractedFrom, signer, "Ported should extract signer");
        assertEq(upstreamExtractedFrom, signer, "Upstream should extract signer");
        assertEq(portedExtractedFrom, upstreamExtractedFrom, "Extracted sender parity mismatch");
    }

    /* -------------------------------------------------------------------------- */
    /*                            ERC165 Interface Support                        */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Verify ported Forwarder implements ERC165 and IForwarder interface
     * @dev This is an enhancement in our port (upstream doesn't have ERC165)
     */
    function test_supportsInterface() public view {
        // Ported version supports ERC165 and IForwarder
        assertTrue(
            portedForwarder.supportsInterface(type(IForwarder).interfaceId), "Should support IForwarder"
        );
        assertTrue(
            portedForwarder.supportsInterface(0x01ffc9a7), // ERC165 interface ID
            "Should support ERC165"
        );
    }
}
