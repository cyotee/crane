// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

import {ERC20Repo} from "@crane/contracts/tokens/ERC20/ERC20Repo.sol";
import {ERC20Target} from "@crane/contracts/tokens/ERC20/ERC20Target.sol";
import {ERC20PermitTarget} from "@crane/contracts/tokens/ERC20/ERC20PermitTarget.sol";
import {ERC4626Repo} from "@crane/contracts/tokens/ERC4626/ERC4626Repo.sol";
import {ERC4626Target} from "@crane/contracts/tokens/ERC4626/ERC4626Target.sol";
import {BetterSafeERC20} from "@crane/contracts/tokens/ERC20/utils/BetterSafeERC20.sol";
import {IERC20Metadata} from "@crane/contracts/interfaces/IERC20Metadata.sol";
import {IERC20} from "@crane/contracts/interfaces/IERC20.sol";
import {IPermit2} from "@crane/contracts/interfaces/protocols/utils/permit2/IPermit2.sol";
import {Permit2AwareTarget} from "@crane/contracts/protocols/utils/permit2/aware/Permit2AwareTarget.sol";
import {Permit2AwareRepo} from "@crane/contracts/protocols/utils/permit2/aware/Permit2AwareRepo.sol";

contract ERC4626TargetStub is ERC4626Target, ERC20PermitTarget {
    using BetterSafeERC20 for IERC20Metadata;

    constructor(IERC20Metadata reserveAsset, uint8 decimalOffset, IPermit2 permit2) ERC4626Target() {
        uint8 reserveAssetDecimals = reserveAsset.safeDecimals();
        string memory reserveAssetName = reserveAsset.name();
        string memory name_ = string.concat("ERC4626 Vault of ", reserveAssetName);
        ERC20Repo._initialize(name_, "ERC4626", reserveAssetDecimals + decimalOffset);
        ERC4626Repo._initialize(IERC20(address(reserveAsset)), reserveAssetDecimals, decimalOffset);
        Permit2AwareRepo._initialize(permit2);
    }
}
