// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC20} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/ERC20.sol";
import {ERC20Burnable} from "@crane/contracts/external/openzeppelin-contracts-v5/token/ERC20/extensions/ERC20Burnable.sol";

/**
 * @title PonsV2LauncherToken
 * @notice Fixed-supply ERC-20 deployed by PonsV2LaunchFactory for a v2 launch.
 * The entire supply mints directly to the token's bonding curve instead of a
 * Uniswap position. Anyone, the deployer included, may buy any amount from
 * the curve at any time; the curve's own price impact and its reserved pool
 * allocation are the only limits on a large buy. `deployer` is carried here
 * as immutable reference data for off-chain attribution only, and confers no
 * privileges over the token.
 * `ERC20Burnable` lets any holder voluntarily burn their own balance; the
 * protocol's buyback mechanism does not use it, bought-back tokens are
 * locked into `PonsV2BuybackVault` for a five-year vest instead of being
 * burned.
 */
contract PonsV2LauncherToken is ERC20, ERC20Burnable {
    struct Socials {
        string twitter;
        string telegram;
        string discord;
        string website;
        string farcaster;
    }

    /**
     * @notice Constructor args bundled so CREATE2 encoding and the constructor
     * stay under the non-IR stack limit.
     */
    struct Init {
        string name;
        string symbol;
        string logo;
        string description;
        Socials socials;
        address deployer;
        address curve;
        address launchFactory;
        uint256 supply;
    }

    error ZeroAddress();

    address public immutable deployer;
    address public immutable launchFactory;
    address public immutable curve;

    string public logo;
    string public description;

    Socials private _socials;

    /**
     * @notice Creates a v2 launch token and mints its entire supply to the bonding curve.
     * @param init Bundled constructor args (see `Init`).
     */
    constructor(Init memory init) ERC20(init.name, init.symbol) {
        if (init.deployer == address(0) || init.curve == address(0) || init.launchFactory == address(0)) {
            revert ZeroAddress();
        }

        deployer = init.deployer;
        // Passed explicitly rather than read from msg.sender: PonsV2LaunchFactory
        // deploys this token indirectly through PonsV2LaunchDeployer to keep its
        // own bytecode under EIP-170's size limit, so msg.sender at construction
        // time would otherwise resolve to that deployer helper, not the factory.
        launchFactory = init.launchFactory;
        curve = init.curve;
        logo = init.logo;
        description = init.description;
        _socials = init.socials;

        _mint(init.curve, init.supply);
    }

    /**
     * @notice Returns the launch token's five social metadata fields.
     */
    function socials()
        external
        view
        returns (
            string memory twitter,
            string memory telegram,
            string memory discord,
            string memory website,
            string memory farcaster
        )
    {
        Socials memory values = _socials;
        return (values.twitter, values.telegram, values.discord, values.website, values.farcaster);
    }

    /**
     * @notice Returns creator and metadata in the launcher-compatible tuple.
     */
    function getTokenInfo()
        external
        view
        returns (
            address tokenDeployer,
            string memory tokenLogo,
            string memory tokenDescription,
            Socials memory tokenSocials
        )
    {
        return (deployer, logo, description, _socials);
    }
}
