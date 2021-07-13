// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import { NFTPolygonBridgingToMainnetFacet } from "../NFTPolygonBridgingToMainnetFacet.sol";

contract MockNFTPolygonBridgingToMainnetFacet is
    NFTPolygonBridgingToMainnetFacet
{
    constructor(address polygonNFT)
        NFTPolygonBridgingToMainnetFacet(polygonNFT)
    {}

    function __exit(bytes memory exitCallData) internal override {}
}
