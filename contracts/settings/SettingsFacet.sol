// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { RolesMods } from "../contexts2/access-control/roles/RolesMods.sol";
import { ADMIN, PAUSER, AUTHORIZED } from "../shared/roles.sol";
import { UpgradeableBeaconFactory } from "../shared/proxy/beacon/UpgradeableBeaconFactory.sol";
import { TellerNFT } from "../nft/bridging/TellerNFT.sol";
import { TellerNFTDictionary } from "../nft/TellerNFTDictionary.sol";
import { PriceAggregator } from "../price-aggregator/PriceAggregator.sol";

// Interfaces
import { IUniswapV2Router } from "../shared/interfaces/IUniswapV2Router.sol";

// Libraries
import { RolesLib } from "../contexts2/access-control/roles/RolesLib.sol";
import { NFTLib } from "../nft/libraries/NFTLib.sol";

// Storage
import { AppStorageLib, AppStorage } from "../storage/app.sol";

struct InitArgs {
    address admin;
    address tellerNFT;
    address loansEscrowBeacon;
    address collateralEscrowBeacon;
    address tTokenBeacon;
    address nftLiquidationController;
    address wrappedNativeToken;
    address nftDictionary;
    address priceAggregator;
}

contract SettingsFacet is RolesMods {
    /**
     * @notice This event is emitted when the platform restriction is switched
     * @param restriction Boolean representing the state of the restriction
     * @param pauser address of the pauser flipping the switch
     */
    event PlatformRestricted(bool restriction, address indexed pauser);

    /**
     * @notice Restricts the use of the Teller protocol to authorized wallet addresses only
     * @param restriction Bool turning the resitriction on or off
     */
    function restrictPlatform(bool restriction)
        internal
        authorized(ADMIN, msg.sender)
    {
        AppStorageLib.store().platformRestricted = restriction;
        emit PlatformRestricted(restriction, msg.sender);
    }

    /**
     * @notice Adds a wallet address to the list of authorized wallets
     * @param account The wallet address of the user being authorized
     */
    function addAuthorizedAddress(address account)
        external
        authorized(ADMIN, msg.sender)
    {
        RolesLib.grantRole(AUTHORIZED, account);
    }

    /**
     * @notice Adds a list of wallet addresses to the list of authorized wallets
     * @param addressesToAdd The list of wallet addresses being authorized
     */
    function addAuthorizedAddressList(address[] calldata addressesToAdd)
        external
        authorized(ADMIN, msg.sender)
    {
        for (uint256 i; i < addressesToAdd.length; i++) {
            RolesLib.grantRole(AUTHORIZED, addressesToAdd[i]);
        }
    }

    /**
     * @notice Removes a wallet address from the list of authorized wallets
     * @param account The wallet address of the user being unauthorized
     */
    function removeAuthorizedAddress(address account)
        external
        authorized(ADMIN, msg.sender)
    {
        RolesLib.revokeRole(AUTHORIZED, account);
    }

    /**
     * @notice Tests whether an account has authorization
     * @param account The account address to check for
     * @return True if account has authorization, false if it does not
     */
    function hasAuthorization(address account) external view returns (bool) {
        return RolesLib.hasRole(AUTHORIZED, account);
    }

    /**
     * @notice Sets a new address to which NFTs should be sent when used for taking out a loan and gets liquidated.
     * @param newController The address where NFTs should be transferred.
     */
    function setNFTLiquidationController(address newController)
        external
        authorized(ADMIN, msg.sender)
    {
        AppStorageLib.store().nftLiquidationController = newController;
    }

    /**
     * @notice Gets the new address where NFTs are sent when used for taking out a loan and gets liquidated.
     * @return controller_ The address where NFTs are be transferred.
     */
    function getNFTLiquidationController()
        external
        view
        returns (address controller_)
    {
        controller_ = AppStorageLib.store().nftLiquidationController;
    }

    /**
     * @notice it stores multiple parameters in the AppStorageLib
     * @param _args multiple arguments that are stored in the AppStorageLibrary
     */
    function init(InitArgs calldata _args) external {
        AppStorage storage s = AppStorageLib.store();

        if (s.initialized) return;
        s.initialized = true;

        RolesLib.grantRole(ADMIN, _args.admin);
        RolesLib.grantRole(PAUSER, _args.admin);

        s.nft = TellerNFT(_args.tellerNFT);
        s.loansEscrowBeacon = UpgradeableBeaconFactory(_args.loansEscrowBeacon);
        s.collateralEscrowBeacon = UpgradeableBeaconFactory(
            _args.collateralEscrowBeacon
        );
        s.tTokenBeacon = UpgradeableBeaconFactory(_args.tTokenBeacon);
        s.nftLiquidationController = _args.nftLiquidationController;
        s.wrappedNativeToken = _args.wrappedNativeToken;
        s.priceAggregator = PriceAggregator(_args.priceAggregator);

        NFTLib.s().nftDictionary = TellerNFTDictionary(_args.nftDictionary);
    }
}
