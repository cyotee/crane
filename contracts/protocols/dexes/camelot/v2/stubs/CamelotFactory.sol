// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.24;

/* -------------------------------------------------------------------------- */
/*                                   Solday                                   */
/* -------------------------------------------------------------------------- */

import {BetterEfficientHashLib} from "@crane/contracts/utils/BetterEfficientHashLib.sol";

import "@crane/contracts/interfaces/protocols/dexes/camelot/v2/ICamelotFactory.sol";
import "@crane/contracts/protocols/dexes/camelot/v2/stubs/CamelotPair.sol";

contract CamelotFactory is ICamelotFactory {
    using BetterEfficientHashLib for bytes;

    address public owner;
    address public feePercentOwner;
    address public setStableOwner;
    address public feeTo;

    //uint public constant FEE_DENOMINATOR = 100000;
    uint256 public constant OWNER_FEE_SHARE_MAX = 100000; // 100%
    uint256 public ownerFeeShare = 50000; // default value = 50%

    uint256 public constant REFERER_FEE_SHARE_MAX = 20000; // 20%
    mapping(address => uint256) public referrersFeeShare; // fees are taken from the user input

    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    event FeeToTransferred(address indexed prevFeeTo, address indexed newFeeTo);
    // event PairCreated(address indexed token0, address indexed token1, address pair, uint length);
    event OwnerFeeShareUpdated(uint256 prevOwnerFeeShare, uint256 ownerFeeShare);
    event OwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event FeePercentOwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event SetStableOwnershipTransferred(address indexed prevOwner, address indexed newOwner);
    event ReferrerFeeShareUpdated(address referrer, uint256 prevReferrerFeeShare, uint256 referrerFeeShare);

    constructor(address feeTo_) {
        owner = msg.sender;
        feePercentOwner = msg.sender;
        setStableOwner = msg.sender;
        feeTo = feeTo_;

        emit OwnershipTransferred(address(0), msg.sender);
        emit FeePercentOwnershipTransferred(address(0), msg.sender);
        emit SetStableOwnershipTransferred(address(0), msg.sender);
        emit FeeToTransferred(address(0), feeTo_);
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "CamelotFactory: caller is not the owner");
        _;
    }

    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    function createPair(address tokenA, address tokenB) external returns (address pair) {
        require(tokenA != tokenB, "CamelotFactory: IDENTICAL_ADDRESSES");
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "CamelotFactory: ZERO_ADDRESS");
        require(getPair[token0][token1] == address(0), "CamelotFactory: PAIR_EXISTS"); // single check is sufficient
        bytes memory bytecode = type(CamelotPair).creationCode;
        // bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        bytes32 salt = abi.encodePacked(token0, token1)._hash();
        assembly {
            pair := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(pair != address(0), "CamelotFactory: FAILED");
        CamelotPair(pair).initialize(token0, token1);
        getPair[token0][token1] = pair;
        getPair[token1][token0] = pair; // populate mapping in the reverse direction
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setOwner(address _owner) external onlyOwner {
        require(_owner != address(0), "CamelotFactory: zero address");
        emit OwnershipTransferred(owner, _owner);
        owner = _owner;
    }

    function setFeePercentOwner(address _feePercentOwner) external onlyOwner {
        require(_feePercentOwner != address(0), "CamelotFactory: zero address");
        emit FeePercentOwnershipTransferred(feePercentOwner, _feePercentOwner);
        feePercentOwner = _feePercentOwner;
    }

    function setSetStableOwner(address _setStableOwner) external {
        require(msg.sender == setStableOwner, "CamelotFactory: not setStableOwner");
        require(_setStableOwner != address(0), "CamelotFactory: zero address");
        emit SetStableOwnershipTransferred(setStableOwner, _setStableOwner);
        setStableOwner = _setStableOwner;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        emit FeeToTransferred(feeTo, _feeTo);
        feeTo = _feeTo;
    }

    /**
     * @dev Updates the share of fees attributed to the owner
     *
     * Must only be called by owner
     */
    function setOwnerFeeShare(uint256 newOwnerFeeShare) external onlyOwner {
        require(newOwnerFeeShare > 0, "CamelotFactory: ownerFeeShare mustn't exceed minimum");
        require(newOwnerFeeShare <= OWNER_FEE_SHARE_MAX, "CamelotFactory: ownerFeeShare mustn't exceed maximum");
        emit OwnerFeeShareUpdated(ownerFeeShare, newOwnerFeeShare);
        ownerFeeShare = newOwnerFeeShare;
    }

    /**
     * @dev Updates the share of fees attributed to the given referrer when a swap went through him
     *
     * Must only be called by owner
     */
    function setReferrerFeeShare(address referrer, uint256 referrerFeeShare) external onlyOwner {
        require(referrer != address(0), "CamelotFactory: zero address");
        require(referrerFeeShare <= REFERER_FEE_SHARE_MAX, "CamelotFactory: referrerFeeShare mustn't exceed maximum");
        emit ReferrerFeeShareUpdated(referrer, referrersFeeShare[referrer], referrerFeeShare);
        referrersFeeShare[referrer] = referrerFeeShare;
    }

    function feeInfo() external view returns (uint256 _ownerFeeShare, address _feeTo) {
        _ownerFeeShare = ownerFeeShare;
        _feeTo = feeTo;
    }
}
