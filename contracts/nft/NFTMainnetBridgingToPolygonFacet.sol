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

contract NFTMainnetBridgingToPolygonFacet {
    // immutable and constant addresses
    address public immutable POLYGON_NFT;
    address public immutable POLYGON_DIAMOND;
    address public constant ERC721_PREDICATE =
        0x74D83801586E9D3C4dc45FfCD30B54eA9C88cf9b;
    TellerNFT public constant TELLER_NFT =
        TellerNFT(0x2ceB85a2402C94305526ab108e7597a102D6C175);

    constructor(address polygonNFT, address polygonDiamond) {
        POLYGON_NFT = polygonNFT;
        POLYGON_DIAMOND = polygonDiamond;
    }

    function initNFTBridge() external {
        // approves all the tokens
        TELLER_NFT.setApprovalForAll(ERC721_PREDICATE, true);
    }

    function bridgeNFTToPolygon(uint256[] memory tokenIds) external {
        // Unstake the NFT
        for (uint256 i; i < tokenIds.length; i++) {
            NFTLib.unstake(tokenIds[i]);
        }
        __bridgePolygonDepositFor(tokenIds);
    }

    function __bridgePolygonDepositFor(uint256[] memory tokenIds)
        internal
        virtual
    {
        // call the depositFor funciton at the rootChainManager
        bytes memory encodedData =
            abi.encodeWithSignature(
                "depositFor(address,address,bytes)",
                POLYGON_DIAMOND,
                address(TELLER_NFT),
                abi.encode(msg.sender, tokenIds)
            );
        Address.functionCall(
            0xD4888faB8bd39A663B63161F5eE1Eae31a25B653,
            encodedData
        );
    }

    function stakeNFTsOnBehalfOfUser(uint256[] memory tokenIds, address user)
        external
    {
        for (uint256 i; i < tokenIds.length; i++) {
            EnumerableSet.add(NFTLib.s().stakedNFTs[user], tokenIds[i]);
        }
    }
}
