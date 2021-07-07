// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { TellerNFT } from "../nft/bridging/TellerNFT.sol";

// Interfaces

// Libraries
import {
    PlatformSetting
} from "../settings/platform/libraries/PlatformSettingsLib.sol";
import { Cache } from "../shared/libraries/CacheLib.sol";
import {
    UpgradeableBeaconFactory
} from "../shared/proxy/beacon/UpgradeableBeaconFactory.sol";

struct AppStorage {
    // is it initialized
    bool initialized;
    // is it platform restricted
    bool platformRestricted;
    // mapping between contract IDs and if they're paused
    mapping(bytes32 => bool) paused;
    //p
    mapping(bytes32 => PlatformSetting) platformSettings;
    mapping(address => Cache) assetSettings;
    mapping(string => address) assetAddresses;
    mapping(address => bool) cTokenRegistry;
    TellerNFT nft;
    UpgradeableBeaconFactory loansEscrowBeacon;
    UpgradeableBeaconFactory collateralEscrowBeacon;
    address nftLiquidationController;
    UpgradeableBeaconFactory tTokenBeacon;
}

library AppStorageLib {
    function store() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }
}
