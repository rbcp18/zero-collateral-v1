// SDPX-License-Identifier: MIT
pragma solidity ^0.8.3;

import { NFTMainnetBridgingToPolygonFacet } from "../NFTMainnetBridgingToPolygonFacet.sol";

contract MockNFTMainnetBridgingToPolygonFacet is
    NFTMainnetBridgingToPolygonFacet
{
    constructor(address polygonNFT, address polygonDiamond)
        NFTMainnetBridgingToPolygonFacet(polygonNFT, polygonDiamond)
    {}

    // this function is empty because it doesn't do much for our tests
    function __bridgePolygonDepositFor(uint256[] memory tokenIds)
        internal
        override
    {}

    function __initNFTBridge() internal override {
        TELLER_NFT.setApprovalForAll(address(this), true);
    }
}
