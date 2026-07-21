// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@crane/contracts/external/openzeppelin-upgradeable-v4/proxy/utils/Initializable.sol";
import "@crane/contracts/external/openzeppelin-upgradeable-v4/proxy/utils/UUPSUpgradeable.sol";
import "@crane/contracts/external/openzeppelin-upgradeable-v4/access/OwnableUpgradeable.sol";
import "@crane/contracts/external/openzeppelin-upgradeable-v4/security/PausableUpgradeable.sol";
import "@crane/contracts/external/openzeppelin-upgradeable-v4/security/ReentrancyGuardUpgradeable.sol";

import "@crane/contracts/external/etherfi/archive/interfaces/IProtocolRevenueManager.sol";
import "@crane/contracts/external/etherfi/staking/interfaces/IEtherFiNodesManager.sol";
import "@crane/contracts/external/etherfi/staking/interfaces/IAuctionManager.sol";

contract ProtocolRevenueManager is
    Initializable,
    IProtocolRevenueManager,
    PausableUpgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    UUPSUpgradeable
{
    //--------------------------------------------------------------------------------------
    //---------------------------------  STATE-VARIABLES  ----------------------------------
    //--------------------------------------------------------------------------------------
    
    IEtherFiNodesManager public etherFiNodesManager;
    IAuctionManager public auctionManager;

    uint256 public DEPRECATED_globalRevenueIndex;
    uint128 public DEPRECATED_vestedAuctionFeeSplitForStakers;
    uint128 public DEPRECATED_auctionFeeVestingPeriodForStakersInDays;

    address public admin;

    //--------------------------------------------------------------------------------------
    //----------------------------  STATE-CHANGING FUNCTIONS  ------------------------------
    //--------------------------------------------------------------------------------------
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        DEPRECATED_globalRevenueIndex = 1;
        DEPRECATED_vestedAuctionFeeSplitForStakers = 50; // 50% of the auction fee is vested
        DEPRECATED_auctionFeeVestingPeriodForStakersInDays = 6 * 7 * 4; // 6 months
    }


    //--------------------------------------------------------------------------------------
    //-----------------------------------  SETTERS   ---------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Instantiates the interface of the node manager for integration
    /// @dev Set manually due to circular dependencies
    /// @param _etherFiNodesManager etherfi node manager address to set
    function setEtherFiNodesManagerAddress(address _etherFiNodesManager) external onlyOwner {
        require(_etherFiNodesManager != address(0), "No zero addresses");
        require(address(etherFiNodesManager) == address(0), "Address already set");
        etherFiNodesManager = IEtherFiNodesManager(_etherFiNodesManager);
    }

    /// @notice Instantiates the interface of the auction manager for integration
    /// @dev Set manually due to circular dependencies
    /// @param _auctionManager auction manager address to set
    function setAuctionManagerAddress(address _auctionManager) external onlyOwner {
        require(_auctionManager != address(0), "No zero addresses");
        require(address(auctionManager) == address(0), "Address already set");
        auctionManager = IAuctionManager(_auctionManager);
    }

    function pauseContract() external onlyAdmin { _pause(); }
    function unPauseContract() external onlyAdmin { _unpause(); }

    /// @notice Updates the address of the admin
    /// @param _newAdmin the new address to set as admin
    function updateAdmin(address _newAdmin) external onlyOwner {
        require(_newAdmin != address(0), "Cannot be address zero");
        admin = _newAdmin;
    }

    //--------------------------------------------------------------------------------------
    //-------------------------------  INTERNAL FUNCTIONS   --------------------------------
    //--------------------------------------------------------------------------------------

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    //--------------------------------------------------------------------------------------
    //-------------------------------------  GETTER   --------------------------------------
    //--------------------------------------------------------------------------------------

    /// @notice Fetches the address of the implementation contract currently being used by the proxy
    /// @return the address of the currently used implementation contract
    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    //--------------------------------------------------------------------------------------
    //-----------------------------------  MODIFIERS  --------------------------------------
    //--------------------------------------------------------------------------------------

    modifier onlyEtherFiNodesManager() {
        require(msg.sender == address(etherFiNodesManager), "Only etherFiNodesManager function");
        _;
    }

    modifier onlyAuctionManager() {
        require(msg.sender == address(auctionManager), "Only auction manager function");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }
}
