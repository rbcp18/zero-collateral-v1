// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import { NFTPolygonBridgingToMainnetFacet } from "../NFTPolygonBridgingToMainnetFacet.sol";

contract MockNFTPolygonBridgingToMainnetFacet is
    NFTPolygonBridgingToMainnetFacet
{
    constructor(address polygonNFT, address mainnetDiamond)
        NFTPolygonBridgingToMainnetFacet(polygonNFT, mainnetDiamond)
    {}

    
}
