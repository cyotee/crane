// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

interface IERC8109Update {

    /* -------------------------------------------------------------------------- */
    /*                                    Types                                   */
    /* -------------------------------------------------------------------------- */

    struct FacetFunctions {
        address facet;
        bytes4[] selectors;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Events                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when a function is added to a diamond.
     *
     * @param _selector The function selector being added.
     * @param _facet    The facet address that will handle calls to `_selector`.
     */
    event DiamondFunctionAdded(bytes4 indexed _selector, address indexed _facet);

    /**
     * @notice Emitted when changing the facet that will handle calls to a function.
     * 
     * @param _selector The function selector being affected.
     * @param _oldFacet The facet address previously responsible for `_selector`.
     * @param _newFacet The facet address that will now handle calls to `_selector`.
     */
    event DiamondFunctionReplaced(
        bytes4 indexed _selector,
        address indexed _oldFacet,
        address indexed _newFacet
    );

    /**
     * @notice Emitted when a function is removed from a diamond.
     *
     * @param _selector The function selector being removed.
     * @param _oldFacet The facet address that previously handled `_selector`.
     */
    event DiamondFunctionRemoved(
        bytes4 indexed _selector, 
        address indexed _oldFacet
    );

    /**
     * @notice Emitted when a diamond's constructor function or function from a
     *         facet makes a `delegatecall`. 
     * 
     * @param _delegate     The contract that was the target of the `delegatecall`.
     * @param _functionCall The function call, including function selector and 
     *                      any arguments.
     */
    event DiamondDelegateCall(address indexed _delegate, bytes _functionCall);

    /**
     * @notice Emitted to record information about a diamond.
     * @dev    This event records any arbitrary metadata. 
     *         The format of `_tag` and `_data` are not specified by the 
     *         standard.
     *
     * @param _tag   Arbitrary metadata, such as a release version.
     * @param _data  Arbitrary metadata.
     */
    event DiamondMetadata(bytes32 indexed _tag, bytes _data);

    /* -------------------------------------------------------------------------- */
    /*                                   Errors                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice The upgradeDiamond function below detects and reverts
     *         with the following errors.
     */
    error NoSelectorsProvidedForFacet(address _facet);
    error NoBytecodeAtAddress(address _contractAddress);

    error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);

    error CannotReplaceFunctionThatDoesNotExist(bytes4 _selector);
    error CannotReplaceFunctionWithTheSameFacet(bytes4 _selector);

    error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);

    error DelegateCallReverted(address _delegate, bytes _functionCall);

    /**
    * @notice Upgrade the diamond by adding, replacing, or removing functions.
    *
    * @dev
    * ### Function Changes:
    * - `_addFunctions` maps new selectors to their facet implementations.
    * - `_replaceFunctions` updates existing selectors to new facet addresses.
    * - `_removeFunctions` removes selectors from the diamond.
    *
    * Functions are added first, then replaced, then removed.
    *
    * These events are emitted to record changes to functions:
    * - `DiamondFunctionAdded`
    * - `DiamondFunctionReplaced`
    * - `DiamondFunctionRemoved`
    *
    * ### `delegatecall`:
    * If `_delegate` is non-zero, the diamond performs a `delegatecall` to
    * `_delegate` using `_functionCall`. The `DiamondDelegateCall` event is
    *  emitted. 
    *
    * The `delegatecall` is done to alter a diamond's state or to 
    * initialize, modify, or remove state after an upgrade.
    *
    * However, if `_delegate` is zero, no `delegatecall` is made and no 
    * `DiamondDelegateCall` event is emitted.
    *
    * ### Metadata:
    * If _tag is non-zero or if _metadata.length > 0 then the
    * `DiamondMetadata` event is emitted.
    *
    * @param _addFunctions     Selectors to add, grouped by facet.
    * @param _replaceFunctions Selectors to replace, grouped by facet.
    * @param _removeFunctions  Selectors to remove.
    * @param _delegate         Optional contract to `delegatecall` (zero address to skip).
    * @param _functionCall     Optional calldata to execute on `_delegate`.
    * @param _tag              Optional arbitrary metadata, such as release version.
    * @param _metadata         Optional arbitrary data.
    */
    function upgradeDiamond(
        FacetFunctions[] calldata _addFunctions,
        FacetFunctions[] calldata _replaceFunctions,
        bytes4[] calldata _removeFunctions,           
        address _delegate,
        bytes calldata _functionCall,
        bytes32 _tag,
        bytes calldata _metadata
    ) external;
}