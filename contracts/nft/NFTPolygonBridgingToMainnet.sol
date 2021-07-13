// SDPX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { TellerNFT } from "./bridging/TellerNFT.sol";
import { NFTLib } from "./libraries/NFTLib.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { NFTStorageLib, NFTStorage } from "../storage/nft.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NFTPolygonBridgingToMainnetFacet {
    // immutable and constant addresses
    address public immutable POLYGON_NFT;
    address public immutable MAINNET_DIAMOND;

    constructor(address polygonNFT, address mainnetDiamond) {
        POLYGON_NFT = polygonNFT;
        MAINNET_DIAMOND = mainnetDiamond;
    }
}
