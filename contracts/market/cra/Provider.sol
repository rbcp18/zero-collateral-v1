// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

contract Provider {
    mapping(address => bool) public admins;
    mapping(address => bool) public signers;

    modifier onlyAdmin() {
        require(admins[msg.sender], "Teller: not admin");
        _;
    }

    constructor() {
        admins[msg.sender] = true;
    }

    /**
     * @notice it sets the admin of a provider
     * @param signerAddress the address of the new or existing signer
     * @param signerValue the bool value for the admin
     */
    function setSigner(address signerAddress, bool signerValue)
        public
        onlyAdmin
    {
        signers[signerAddress] = signerValue;
    }

    /**
     * @notice it sets the admin of a provider
     * @param adminAddress the address of the new or existing admin
     * @param adminValue the bool value for the admin
     */
    function setAdmin(address adminAddress, bool adminValue) public onlyAdmin {
        admins[adminAddress] = adminValue;
    }
}
