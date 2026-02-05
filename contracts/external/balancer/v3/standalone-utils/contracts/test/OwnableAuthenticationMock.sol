// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.24;

import {Ownable} from "@crane/contracts/access/Ownable.sol";
import {Ownable2Step} from "@crane/contracts/access/Ownable2Step.sol";

import { IAuthorizer } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IAuthorizer.sol";
import { IVault } from "@crane/contracts/external/balancer/v3/interfaces/contracts/vault/IVault.sol";

import { Authentication } from "@crane/contracts/external/balancer/v3/solidity-utils/contracts/helpers/Authentication.sol";

import { OwnableAuthentication } from "../OwnableAuthentication.sol";

contract OwnableAuthenticationMock is OwnableAuthentication {
    constructor(IVault vault, address initialOwner) OwnableAuthentication(vault, initialOwner) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function permissionedFunction() external view authenticate {
        // solhint-disable-previous-line no-empty-blocks
    }
}
