// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "./BaseProxy.sol";
import "../upgradeable/DynamicUpgradeable.sol";

/**
    @notice It is a dynamic proxy contract for any contract. It uses the logic versions registry to get a logic contract address.
    @notice It extends BaseUpgradeable to get access to the settings.

    @author develop@teller.finance
 */
abstract contract BaseDynamicProxy is BaseProxy, DynamicUpgradeable {
    function _implementation()
        internal
        view
        override(DynamicUpgradeable, Proxy)
        returns (address)
    {
        return DynamicUpgradeable._implementation();
    }
}
