// SDPX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { TellerNFT } from "./bridging/TellerNFT.sol";
import { NFTLib } from "./libraries/NFTLib.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { NFTStorageLib, NFTStorage } from "../storage/nft.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NFTPolygonBridgingToMainnetFacet {
    // immutable and constant addresses
    address public immutable POLYGON_NFT;

    constructor(address polygonNFT) {
        POLYGON_NFT = polygonNFT;
    }

    function bridgeNFTToMainnet(uint256[] memory tokenIds) external {
        // Unstake all the nfts
        for (uint256 i; i < tokenIds.length; i++) {
            NFTLib.unstake(tokenIds[i]);
        }
        // __withdrawTokensOnChild(tokenIds);
    }

    function __withdrawTokensOnChild(uint256[] memory tokenIds)
        internal
        virtual
    {
        bytes memory encodedData = abi.encodeWithSignature(
            "withdrawBatch(uint256[])",
            tokenIds
        );
        Address.functionCall(POLYGON_NFT, encodedData);
    }

    function exit(bytes memory exitCallData) external {
        __exit(exitCallData);
    }

    function __exit(bytes memory exitCallData) internal virtual {
        bytes memory encodedData = abi.encodeWithSignature(
            "exit(bytes)",
            exitCallData
        );
        Address.functionCall(
            0xD4888faB8bd39A663B63161F5eE1Eae31a25B653,
            encodedData
        );
    }
}
