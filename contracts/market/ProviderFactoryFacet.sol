// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import { Provider } from "./cra/Provider.sol";

contract ProviderFactoryFacet {
    address private admin;
    Provider[] private providers;

    modifier onlyAdmin() {
        require(admin == msg.sender, "Only the admin can call this!");
        _;
    }

    // whichever address that deployst the provider factory facet is the admin of the factory
    constructor() {
        admin = msg.sender;
    }

    /**
     * @notice it creates a new provider. whichever address that creates the new provider is the
     * admin of the said provider.
     */
    function createProvider() public {
        Provider provider = new Provider();
        providers.push(provider);
    }
}
