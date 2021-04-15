// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import {
    CacheLib,
    Cache,
    CacheType
} from "../../shared/libraries/CacheLib.sol";

// Storage
import { AppStorageLib } from "../../storage/app.sol";

/**
 * @notice Utility library of inline functions for MaxTVLAmount asset setting.
 *
 * @author develop@teller.finance
 */
library MaxTVLAmountLib {
    bytes32 private constant NAME = keccak256("MaxTVLAmount");

    function s(address asset) private view returns (Cache storage) {
        return AppStorageLib.store().assetSettings[asset];
    }

    function get(address asset) internal view returns (uint256) {
        return s(asset).uints[NAME];
    }

    function set(address asset, uint256 newValue) internal returns (uint256) {
        return s(asset).uints[NAME] = newValue;
    }
}