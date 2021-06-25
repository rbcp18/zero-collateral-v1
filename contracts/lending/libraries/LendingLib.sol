// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Libraries
import { NumbersLib } from "../../shared/libraries/NumbersLib.sol";

// Interfaces
import { ITToken } from "../ttoken/ITToken.sol";

// Storage
import { MarketStorageLib, MarketStorage } from "../../storage/market.sol";

library LendingLib {
    bytes32 internal constant ID = keccak256("LENDING");

    function s() internal pure returns (MarketStorage storage) {
        return MarketStorageLib.store();
    }

    function tToken(address asset) internal view returns (ITToken tToken_) {
        tToken_ = s().tTokens[asset];
    }
}
