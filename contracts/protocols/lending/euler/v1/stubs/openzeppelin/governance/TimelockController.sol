// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AccessControl} from "../../access/AccessControl.sol";

abstract contract TimelockController is AccessControl {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
    uint256 public constant GRACE_PERIOD = 2 days;
    
    mapping(bytes32 => uint256) private _timestamps;
    
    constructor(uint256 minDelay, address[] memory proposers, address[] memory executors) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(PROPOSER_ROLE, msg.sender);
        _setupRole(EXECUTOR_ROLE, msg.sender);
    }
    
    function schedule(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt, uint256 delay) external virtual;
    function scheduleBatch(address[] calldata targets, uint256[] calldata values, bytes[] calldata datas, bytes32 predecessor, bytes32 salt, uint256 delay) external virtual;
    function execute(address target, uint256 value, bytes calldata data, bytes32 predecessor, bytes32 salt) external payable virtual;
    function cancel(bytes32 id) external virtual;
    function updateDelay(uint256 newDelay) external virtual;
}
