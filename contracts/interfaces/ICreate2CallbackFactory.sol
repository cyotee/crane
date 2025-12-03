// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/**
 * @title ICreate2CallbackFactory
 * @author cyotee doge <doge.cyotee>
 * @notice A interface for a CREATE2 callback factory.
 * @notice Exposed to deploy contracts that will callback to get their metadata and initialization data.
 */
interface ICreate2CallbackFactory {
    /**
     * @notice Thrown if math breaks.
     * @dev If you get this error, your universe is broken.
     */
    error DeploymentAddressMismatch(address predicted, address actual);

    /**
     * @notice The initcode hash of a target contract.
     * @param target_ The target contract.
     * @return initCodeHash_ The initcode hash of the target contract.
     * @custom:selector 0x652b6efa
     */
    function initCodeHashOfTarget(address target_) external view returns (bytes32 initCodeHash_);

    /**
     * @notice The salt of a target contract.
     * @param target_ The target contract.
     * @return salt_ The salt of the target contract.
     * @custom:selector 0x6bd9a5e6
     */
    function saltOfTarget(address target_) external view returns (bytes32 salt_);

    /**
     * @notice The initialization data of a target contract.
     * @param target_ The target contract.
     * @return initData_ The initialization data of the target contract.
     * @custom:selector 0x8ac58875
     */
    function initDataOfTarget(address target_) external view returns (bytes memory initData_);

    /**
     * @dev Create2CallBackContracts call this function to get their metadata and initialization data.
     * @notice The initcode hash, salt, and initialization data of a target contract.
     * @return initCodeHash The initcode hash of the target contract.
     * @return salt The salt of the target contract.
     * @return initData_ The initialization data of the target contract.
     * @custom:selector 0x8eb36e3d
     */
    function initData() external view returns (bytes32 initCodeHash, bytes32 salt, bytes memory initData_);

    /**
     * @notice Creates a contract using the CREATE2 opcode.
     * @param initCode The initialization code of the contract.
     * @param initData_ The initialization data of the contract.
     * @return deployment The address of the deployed contract.
     * @custom:selector 0x0a2df826
     */
    function create2(bytes memory initCode, bytes memory initData_) external returns (address deployment);

    function create3(bytes memory initCode, bytes32 salt) external returns (address proxy);

    function create3(bytes memory initCode, bytes memory initData, bytes32 salt) external returns (address proxy);

    function create3WithInitData(bytes memory initCode, bytes memory initData, bytes32 salt)
        external
        returns (address proxy);
}
