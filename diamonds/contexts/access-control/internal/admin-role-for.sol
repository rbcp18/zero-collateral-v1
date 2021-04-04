// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "diamonds/Roles.sol";

abstract contract int_adminRoleFor_AccessControl_v1 is sto_AccessControl_Roles {
    function _adminRoleFor(bytes32 role)
        internal
        view
        returns (bytes32 adminRoleFor_)
    {
        adminRoleFor_ = getStorage().roles[role].adminRole;
    }
}

abstract contract int_adminRoleFor_AccessControl is
    int_adminRoleFor_AccessControl_v1
{}