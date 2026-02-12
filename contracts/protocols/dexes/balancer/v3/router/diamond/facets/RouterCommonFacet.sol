// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.30;

import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IERC20Permit} from "@crane/contracts/interfaces/IERC20Permit.sol";
import {Address} from "@crane/contracts/utils/Address.sol";
import { IPermit2 } from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {IAllowanceTransfer} from "@crane/contracts/interfaces/protocols/utils/permit2/IAllowanceTransfer.sol";

import {IWETH} from "@crane/contracts/external/balancer/v3/interfaces/contracts/solidity-utils/misc/IWETH.sol";
import {IVault} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";
import {IRouterCommon} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IRouterCommon.sol";
import {ISenderGuard} from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/ISenderGuard.sol";

import {InputHelpers} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/InputHelpers.sol";
import {RevertCodec} from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/RevertCodec.sol";

import {IFacet} from "@crane/contracts/interfaces/IFacet.sol";
import {BalancerV3RouterStorageRepo} from "../BalancerV3RouterStorageRepo.sol";
import {BalancerV3RouterModifiers} from "../BalancerV3RouterModifiers.sol";

/* -------------------------------------------------------------------------- */
/*                            RouterCommonFacet                               */
/* -------------------------------------------------------------------------- */

/**
 * @title RouterCommonFacet
 * @notice Provides common utility functions for the Balancer V3 Router Diamond.
 * @dev Implements IRouterCommon and ISenderGuard interfaces.
 *
 * This facet handles:
 * - getWeth, getPermit2, getVault accessors
 * - getSender for transient sender access
 * - version() for router version
 * - permitBatchAndCall for batch approvals + multicall
 * - multicall for batched delegatecalls
 */
contract RouterCommonFacet is IRouterCommon, BalancerV3RouterModifiers, IFacet {

    /* ========================================================================== */
    /*                                  IFacet                                    */
    /* ========================================================================== */

    /// @inheritdoc IFacet
    function facetName() public pure returns (string memory name) {
        return type(RouterCommonFacet).name;
    }

    /// @inheritdoc IFacet
    function facetInterfaces() public pure returns (bytes4[] memory interfaces) {
        interfaces = new bytes4[](2);
        interfaces[0] = type(IRouterCommon).interfaceId;
        interfaces[1] = type(ISenderGuard).interfaceId;
    }

    /// @inheritdoc IFacet
    function facetFuncs() public pure returns (bytes4[] memory funcs) {
        funcs = new bytes4[](7);
        funcs[0] = IRouterCommon.getWeth.selector;
        funcs[1] = IRouterCommon.getPermit2.selector;
        funcs[2] = IRouterCommon.getVault.selector;
        funcs[3] = ISenderGuard.getSender.selector;
        funcs[4] = this.version.selector;
        funcs[5] = IRouterCommon.permitBatchAndCall.selector;
        funcs[6] = IRouterCommon.multicall.selector;
    }

    /// @inheritdoc IFacet
    function facetMetadata()
        external
        pure
        returns (string memory name_, bytes4[] memory interfaces, bytes4[] memory functions)
    {
        name_ = facetName();
        interfaces = facetInterfaces();
        functions = facetFuncs();
    }
    using Address for address;

    /* ========================================================================== */
    /*                             VIEW FUNCTIONS                                 */
    /* ========================================================================== */

    /// @inheritdoc IRouterCommon
    function getWeth() external view returns (IWETH) {
        return BalancerV3RouterStorageRepo._weth();
    }

    /// @inheritdoc IRouterCommon
    function getPermit2() external view returns (IPermit2) {
        return BalancerV3RouterStorageRepo._permit2();
    }

    /// @inheritdoc IRouterCommon
    function getVault() external view returns (IVault) {
        return BalancerV3RouterStorageRepo._vault();
    }

    /// @inheritdoc ISenderGuard
    function getSender() external view override returns (address) {
        return BalancerV3RouterStorageRepo._getSender();
    }

    /**
     * @notice Returns the router version string.
     * @return The version string set during initialization.
     */
    function version() external view returns (string memory) {
        return BalancerV3RouterStorageRepo._routerVersion();
    }

    /* ========================================================================== */
    /*                           UTILITY FUNCTIONS                                */
    /* ========================================================================== */

    /// @inheritdoc IRouterCommon
    function permitBatchAndCall(
        PermitApproval[] calldata permitBatch,
        bytes[] calldata permitSignatures,
        IAllowanceTransfer.PermitBatch calldata permit2Batch,
        bytes calldata permit2Signature,
        bytes[] calldata multicallData
    ) external payable virtual returns (bytes[] memory) {
        if (BalancerV3RouterStorageRepo._isPrepaid()) {
            revert OperationNotSupported();
        }

        _permitBatch(permitBatch, permitSignatures, permit2Batch, permit2Signature);

        // Execute all required operations once permissions have been granted.
        return multicall(multicallData);
    }

    /// @inheritdoc IRouterCommon
    function multicall(
        bytes[] calldata data
    ) public payable virtual saveSenderAndManageEth returns (bytes[] memory results) {
        // Though theoretically these calls could be batched, the normal use case for multicall
        // involves some combination of operation and token transfers (either permit2 or direct to Vault),
        // which cannot be done with multicall alone.
        if (BalancerV3RouterStorageRepo._isPrepaid()) {
            revert OperationNotSupported();
        }

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; ++i) {
            results[i] = address(this).functionDelegateCall(data[i]);
        }
    }

    /* ========================================================================== */
    /*                            INTERNAL FUNCTIONS                              */
    /* ========================================================================== */

    struct SignatureParts {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    function _permitBatch(
        PermitApproval[] calldata permitBatch,
        bytes[] calldata permitSignatures,
        IAllowanceTransfer.PermitBatch calldata permit2Batch,
        bytes calldata permit2Signature
    ) internal nonReentrant {
        InputHelpers.ensureInputLengthMatch(permitBatch.length, permitSignatures.length);

        // Use Permit (ERC-2612) to grant allowances to Permit2 for tokens to swap,
        // and grant allowances to Vault for BPT tokens.
        for (uint256 i = 0; i < permitBatch.length; ++i) {
            bytes memory signature = permitSignatures[i];

            SignatureParts memory signatureParts = _getSignatureParts(signature);
            PermitApproval memory permitApproval = permitBatch[i];

            try
                IERC20Permit(permitApproval.token).permit(
                    permitApproval.owner,
                    address(this),
                    permitApproval.amount,
                    permitApproval.deadline,
                    signatureParts.v,
                    signatureParts.r,
                    signatureParts.s
                )
            {
                // OK; carry on.
            } catch (bytes memory returnData) {
                // Did it fail because the permit was executed (possible DoS attack),
                // or was it something else (e.g., deadline, invalid signature)?
                if (
                    IERC20(permitApproval.token).allowance(permitApproval.owner, address(this)) != permitApproval.amount
                ) {
                    // It was something else, so bubble up the revert reason.
                    RevertCodec.bubbleUpRevert(returnData);
                }
            }
        }

        // Only call permit2 if there's something to do.
        if (permit2Batch.details.length > 0) {
            IPermit2 permit2 = BalancerV3RouterStorageRepo._permit2();
            permit2.permit(msg.sender, permit2Batch, permit2Signature);
        }
    }

    function _getSignatureParts(bytes memory signature) private pure returns (SignatureParts memory signatureParts) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly ("memory-safe") {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        signatureParts.r = r;
        signatureParts.s = s;
        signatureParts.v = v;
    }
}
