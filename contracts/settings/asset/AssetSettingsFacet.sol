// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { RolesMods } from "../../contexts2/access-control/roles/RolesMods.sol";
import { ADMIN, AUTHORIZED } from "../../shared/roles.sol";

// Libraries
import {
    CacheLib,
    Cache,
    CacheType
} from "../../shared/libraries/CacheLib.sol";
import { MaxTVLLib } from "./libraries/MaxTVLLib.sol";

// Storage
import { AppStorageLib, AppStorage } from "../../storage/app.sol";

struct AssetSettingRequest {
    bytes32 key;
    bytes32 value;
    CacheType cacheType;
}

contract AssetSettingsFacet is RolesMods {
    function s(address asset) private view returns (Cache storage) {
        return AppStorageLib.store().assetSettings[asset];
    }

    event AssetSettingsCreated(
        address indexed asset,
        bytes32 indexed key,
        bytes32 value,
        CacheType cacheType
    );

    event AssetSettingsUpdated(
        address indexed asset,
        bytes32 indexed key,
        bytes32 value,
        CacheType cacheType
    );

    /**
     * @notice it checks if the settings of an asset is initialized
     * @param asset the address of the asset
     * @return bool to check if settings of an asset exists
     */
    function isAssetSettingInitialized(address asset)
        external
        view
        returns (bool)
    {
        return CacheLib.exists(s(asset));
    }

    /**
     * @notice it gets the MaxTVL amount of an asset
     * @param asset the address of the asset
     * @return the max TVL amount
     */
    function getMaxTVLAmount(address asset) external view returns (uint256) {
        return MaxTVLLib.get(asset);
    }

    /**
     * @notice It creates an asset settings with the given parameters.
     * @param asset the address to create settings for
     * @param requests the multiple settings to update the asset with
     */
    function createAssetSetting(
        address asset,
        AssetSettingRequest[] calldata requests
    ) external authorized(ADMIN, msg.sender) {
        require(asset != address(0), "Teller: asset address required");

        CacheLib.initialize(s(asset));

        for (uint256 i; i < requests.length; i++) {
            CacheLib.update(
                s(asset),
                requests[i].key,
                requests[i].value,
                requests[i].cacheType
            );

            emit AssetSettingsCreated(
                asset,
                requests[i].key,
                requests[i].value,
                requests[i].cacheType
            );
        }
    }

    /**
     * @notice It updates an asset with the given parameter
     * @param asset the address of the asset to update
     * @param request the setting to update the asset with
     */
    function updateAssetSetting(
        address asset,
        AssetSettingRequest calldata request
    ) external authorized(ADMIN, msg.sender) {
        require(
            CacheLib.exists(s(asset)),
            "Teller: asset setting does not exists"
        );

        CacheLib.update(
            s(asset),
            request.key,
            request.value,
            request.cacheType
        );

        emit AssetSettingsUpdated(
            asset,
            request.key,
            request.value,
            request.cacheType
        );
    }
}
