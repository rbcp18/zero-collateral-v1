// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import { NFTMainnetBridgingToPolygonFacet } from "../NFTMainnetBridgingToPolygonFacet.sol";

contract MockNFTMainnetBridgingToPolygonFacet is
    NFTMainnetBridgingToPolygonFacet
{
    constructor(address polygonNFT, address polygonDiamond)
        NFTMainnetBridgingToPolygonFacet(polygonNFT, polygonDiamond)
    {}

    function __initNFTBridge() internal override {
        TELLER_NFT.setApprovalForAll(address(this), true);
    }

    function __bridgePolygonDepositFor(DepositData memory depositData)
        internal
        override
    {}
}
