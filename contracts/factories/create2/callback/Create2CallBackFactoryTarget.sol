// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

import { BetterAddress as Address } from "../../../utils/BetterAddress.sol";
import { Bytecode } from "../../../utils/Bytecode.sol";
import { OwnableTarget } from "../../../access/ownable/OwnableTarget.sol";
import { OperableModifiers } from "../../../access/operable/OperableModifiers.sol";
import { OperableTarget } from "../../../access/operable/OperableTarget.sol";
import { ICreate2Aware } from "../../../interfaces/ICreate2Aware.sol";
import { ICreate3Aware } from "../../../interfaces/ICreate3Aware.sol";
import { ICreate2CallbackFactory } from "../../../interfaces/ICreate2CallbackFactory.sol";
import { Creation } from "../../../utils/Creation.sol";

/**
 * @title Create2CallBackFactoryTarget
 * @author cyotee doge <doge.cyotee>
 * @notice A factory contract that allows a contract to expose it's initialization data.
 * @notice Provided to enable deterministic deployments regardless of initialization data.
 * @notice Include 
 */
contract Create2CallBackFactoryTarget
is
// Include the ownership management.
// THis includes the onwership modifiers.
OwnableTarget,
OperableModifiers,
// Include the operability management.
OperableTarget,
// Include the factory interface.
ICreate2CallbackFactory
{

    using Address for address;

    /**
     * @dev We deliberately DO NOT pass any constructor arguments.
     * @dev This keeps the bytecode consistent and easier to track.
     */
    constructor() {
        _initOwnable(msg.sender);
    }

    /**
     * @inheritdoc ICreate2CallbackFactory
     */
    mapping(address target => bytes32 initCodeHash) public initCodeHashOfTarget;

    /**
     * @inheritdoc ICreate2CallbackFactory
     */
    mapping(address target => bytes32 salt) public saltOfTarget;

    /**
     * @inheritdoc ICreate2CallbackFactory
     */
    mapping(address target => bytes initData) public initDataOfTarget;

    /**
     * @inheritdoc ICreate2CallbackFactory
     */
    function initData()
    public view returns(
        bytes32 initCodeHash,
        bytes32 salt,
        bytes memory initData_
    ) {
        initCodeHash = initCodeHashOfTarget[msg.sender];
        salt = saltOfTarget[msg.sender];
        initData_ = initDataOfTarget[msg.sender];
    }

    function create2Addr(
        bytes32 initCodeHash_,
        bytes32 salt_
    ) public view returns (address) {
        return Creation._create2AddressFromOf(address(this), initCodeHash_, salt_);
    }

    function create2Addr(
        bytes32 initCodeHash_
    ) public view returns (address) {
        return Creation._create2AddressFromOf(address(this), initCodeHash_, initCodeHash_);
    }

    /**
     * @inheritdoc ICreate2CallbackFactory
     */
    function create2(
        bytes memory initCode,
        bytes memory initData_
    ) public virtual onlyOwnerOrOperator() returns(address deployment) {
        bytes32 initCodeHash_ = keccak256(initCode);
        return _create2(initCode, initCodeHash_, initData_, initCodeHash_);
    }

    function create2(
        bytes memory initCode,
        bytes memory initData_,
        bytes32 salt_
    ) public virtual onlyOwnerOrOperator() returns(address deployment) {
        return _create2(initCode, keccak256(initCode), initData_, salt_);
    }

    function create3(
        bytes memory initCode,
        bytes32 salt
    ) public virtual onlyOwnerOrOperator() returns (address proxy) {
        address predictedTarget = Creation._create3AddressOf(salt);
        // Be optimisitcally idempotent.
        // This may be used to deploy libraries and other bytecode that will not expose it's CREATE2 metadata.
        // This means we can't validate tthe mettadata to ensure the byttecode was deployed by this factory.
        // We will be optimisttic and assume that a CREATE2 address could only be deployed by this factory.
        if(predictedTarget.isContract()) {
            return predictedTarget;
        }
        return Creation._create3(initCode, salt);
    }

    function create3(
        bytes memory initCode,
        bytes memory initData_,
        bytes32 salt
    ) public returns (address proxy) {
        return create3(
            abi.encodePacked(
                initCode,
                abi.encode(
                    ICreate3Aware.CREATE3InitData({
                        salt: salt,
                        initData: initData_
                    })
                )
            ),
            salt
        );
    }

    function _create2(
        bytes memory initCode,
        bytes32 initCodeHash_,
        bytes memory initData_,
        bytes32 salt_
    ) internal virtual returns(address deployment) {
        // Predict the target address.
        address predictedTarget = Creation._create2AddressFromOf(address(this), initCodeHash_, salt_);
        // Be optimisitcally idempotent.
        // This may be used to deploy libraries and other bytecode that will not expose it's CREATE2 metadata.
        // This means we can't validate tthe mettadata to ensure the byttecode was deployed by this factory.
        // We will be optimisttic and assume that a CREATE2 address could only be deployed by this factory.
        if(predictedTarget.isContract()) {
            return predictedTarget;
        }
        // Store the metadata.
        initCodeHashOfTarget[predictedTarget] = initCodeHash_;
        saltOfTarget[predictedTarget] = salt_;
        initDataOfTarget[predictedTarget] = initData_;
        // Deploy the contract.
        deployment = Creation._create2(initCode, salt_);
        // Ensure the deployment address is correct.
        // If you get this error, your universe is broken; or you deployed to a ZK chain, same diff.
        if(predictedTarget != deployment) {
            revert ICreate2CallbackFactory.DeploymentAddressMismatch(predictedTarget, deployment);
        }
        return deployment;
    }
    
}