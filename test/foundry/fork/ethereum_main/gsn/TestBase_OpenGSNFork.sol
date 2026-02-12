// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {Forwarder as PortedForwarder} from "@crane/contracts/protocols/utils/gsn/forwarder/Forwarder.sol";
import {IForwarder} from "@crane/contracts/protocols/utils/gsn/forwarder/IForwarder.sol";
// NOTE: "UpstreamForwarder" is the same contract as PortedForwarder.
// Both aliases point to the same Forwarder.sol, so they share identical
// GENERIC_PARAMS ("...uint256 validUntilTime") and the same auto-registered
// ForwardRequest type hash.  The "upstream" label exists only to mirror the
// original test intent of comparing against a real upstream OpenGSN forwarder.
import {Forwarder as UpstreamForwarder} from "@crane/contracts/protocols/utils/gsn/forwarder/Forwarder.sol";
import {IForwarder as IUpstreamForwarder} from "@crane/contracts/protocols/utils/gsn/forwarder/IForwarder.sol";

import {RecipientStub} from "./RecipientStub.sol";

/**
 * @title TestBase_OpenGSNFork
 * @notice Base test contract for OpenGSN Forwarder fork parity tests
 * @dev Provides setup for comparing ported Forwarder behavior against upstream OpenGSN
 *
 * This TestBase deploys:
 * - Our ported Forwarder (from contracts/protocols/utils/gsn/forwarder/)
 * - Upstream OpenGSN Forwarder (from lib/gsn at pinned commit)
 * - A RecipientStub to test appended sender semantics
 */
abstract contract TestBase_OpenGSNFork is Test {
    /* -------------------------------------------------------------------------- */
    /*                              Fork Configuration                            */
    /* -------------------------------------------------------------------------- */

    /// @dev Block number for fork reproducibility
    uint256 internal constant FORK_BLOCK = 21_000_000;

    /* -------------------------------------------------------------------------- */
    /*                              Contract Instances                            */
    /* -------------------------------------------------------------------------- */

    /// @notice Our ported Forwarder
    PortedForwarder internal portedForwarder;

    /// @notice Upstream OpenGSN Forwarder
    UpstreamForwarder internal upstreamForwarder;

    /// @notice Test recipient contract
    RecipientStub internal recipient;

    /* -------------------------------------------------------------------------- */
    /*                              EIP-712 Constants                             */
    /* -------------------------------------------------------------------------- */

    /// @dev Domain name for testing
    string internal constant DOMAIN_NAME = "TestForwarder";

    /// @dev Domain version for testing
    string internal constant DOMAIN_VERSION = "1";

    /// @dev Standard ForwardRequest type hash
    bytes32 internal portedRequestTypeHash;
    bytes32 internal upstreamRequestTypeHash;

    /// @dev Domain separators (computed after deployment)
    bytes32 internal portedDomainSeparator;
    bytes32 internal upstreamDomainSeparator;

    /* -------------------------------------------------------------------------- */
    /*                              Test Accounts                                 */
    /* -------------------------------------------------------------------------- */

    /// @dev Test signer with known private key
    uint256 internal constant SIGNER_PK = 0xA11CE;
    address internal signer;

    /* -------------------------------------------------------------------------- */
    /*                                   Setup                                    */
    /* -------------------------------------------------------------------------- */

    function setUp() public virtual {
        // Skip fork tests when no RPC credentials are configured
        // string memory infuraKey = vm.envOr("INFURA_KEY", string(""));
        // if (bytes(infuraKey).length == 0) {
        //     vm.skip(true);
        // }

        // Create fork at specific block for reproducibility
        vm.createSelectFork("ethereum_mainnet_infura", FORK_BLOCK);

        // Derive signer address from private key
        signer = vm.addr(SIGNER_PK);
        vm.label(signer, "Signer");

        // Deploy forwarders
        portedForwarder = new PortedForwarder();
        vm.label(address(portedForwarder), "PortedForwarder");

        upstreamForwarder = new UpstreamForwarder();
        vm.label(address(upstreamForwarder), "UpstreamForwarder");

        // Deploy recipient stub
        recipient = new RecipientStub();
        vm.label(address(recipient), "RecipientStub");

        // Register domain separators
        portedForwarder.registerDomainSeparator(DOMAIN_NAME, DOMAIN_VERSION);
        upstreamForwarder.registerDomainSeparator(DOMAIN_NAME, DOMAIN_VERSION);

        // Compute domain separators
        portedDomainSeparator = _computeDomainSeparator(address(portedForwarder));
        upstreamDomainSeparator = _computeDomainSeparator(address(upstreamForwarder));

        // Compute request type hashes (both should use the same generic ForwardRequest type)
        portedRequestTypeHash = _computeRequestTypeHash();
        upstreamRequestTypeHash = _computeRequestTypeHash();
    }

    /* -------------------------------------------------------------------------- */
    /*                              EIP-712 Helpers                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Compute EIP-712 domain separator for a forwarder
     */
    function _computeDomainSeparator(address forwarder) internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                block.chainid,
                forwarder
            )
        );
    }

    /**
     * @notice Compute the ForwardRequest type hash
     * @dev Uses the ported version's GENERIC_PARAMS format
     */
    function _computeRequestTypeHash() internal pure returns (bytes32) {
        // Note: Our ported version uses "validUntilTime" while upstream uses "validUntil"
        // But the constructor-registered type uses the contract's GENERIC_PARAMS constant
        string memory portedRequestType =
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntilTime)";
        return keccak256(bytes(portedRequestType));
    }

    /**
     * @notice Compute the upstream ForwardRequest type hash
     */
    function _computeUpstreamRequestTypeHash() internal pure returns (bytes32) {
        string memory upstreamRequestType =
            "ForwardRequest(address from,address to,uint256 value,uint256 gas,uint256 nonce,bytes data,uint256 validUntil)";
        return keccak256(bytes(upstreamRequestType));
    }

    /**
     * @notice Sign a forward request for our ported forwarder
     * @param req The forward request
     * @param signerPk The private key to sign with
     */
    function _signPortedRequest(IForwarder.ForwardRequest memory req, uint256 signerPk)
        internal
        view
        returns (bytes memory signature)
    {
        bytes32 structHash = keccak256(
            abi.encodePacked(
                portedRequestTypeHash,
                uint256(uint160(req.from)),
                uint256(uint160(req.to)),
                req.value,
                req.gas,
                req.nonce,
                keccak256(req.data),
                req.validUntilTime,
                bytes("")  // empty suffix data
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", portedDomainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        signature = abi.encodePacked(r, s, v);
    }

    /**
     * @notice Sign a forward request for upstream forwarder
     * @param req The forward request (using upstream struct)
     * @param signerPk The private key to sign with
     */
    function _signUpstreamRequest(IUpstreamForwarder.ForwardRequest memory req, uint256 signerPk)
        internal
        view
        returns (bytes memory signature)
    {
        bytes32 structHash = keccak256(
            abi.encodePacked(
                upstreamRequestTypeHash,
                uint256(uint160(req.from)),
                uint256(uint160(req.to)),
                req.value,
                req.gas,
                req.nonce,
                keccak256(req.data),
                req.validUntilTime,
                bytes("")  // empty suffix data
            )
        );

        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", upstreamDomainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPk, digest);
        signature = abi.encodePacked(r, s, v);
    }

    /* -------------------------------------------------------------------------- */
    /*                              Request Builders                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Build a ported ForwardRequest for testing
     */
    function _buildPortedRequest(
        address from,
        address to,
        uint256 value,
        uint256 gas,
        bytes memory data
    ) internal view returns (IForwarder.ForwardRequest memory) {
        return IForwarder.ForwardRequest({
            from: from,
            to: to,
            value: value,
            gas: gas,
            nonce: portedForwarder.getNonce(from),
            data: data,
            validUntilTime: block.timestamp + 1 hours
        });
    }

    /**
     * @notice Build an upstream ForwardRequest for testing
     */
    function _buildUpstreamRequest(
        address from,
        address to,
        uint256 value,
        uint256 gas,
        bytes memory data
    ) internal view returns (IUpstreamForwarder.ForwardRequest memory) {
        return IUpstreamForwarder.ForwardRequest({
            from: from,
            to: to,
            value: value,
            gas: gas,
            nonce: upstreamForwarder.getNonce(from),
            data: data,
            validUntilTime: block.timestamp + 1 hours
        });
    }
}
