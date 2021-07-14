// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// Contracts
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import { TellerNFT } from "./bridging/TellerNFT.sol";
import { NFTLib } from "./libraries/NFTLib.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { NFTStorageLib, NFTStorage } from "../storage/nft.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "hardhat/console.sol";

contract NFTMainnetBridgingToPolygonFacet {
    // immutable and constant addresses
    address public immutable POLYGON_NFT_ADDRESS;
    address public immutable POLYGON_DIAMOND;
    address public constant ERC721_PREDICATE =
        0x74D83801586E9D3C4dc45FfCD30B54eA9C88cf9b;
    TellerNFT public constant TELLER_NFT =
        TellerNFT(0x2ceB85a2402C94305526ab108e7597a102D6C175);

    // add rootchain manager address
    struct DepositData {
        address user;
        uint256[] stakedTokenIds;
        uint256[] unstakedTokenIds;
    }

    constructor(address polygonNFT, address polygonDiamond) {
        POLYGON_NFT_ADDRESS = polygonNFT;
        POLYGON_DIAMOND = polygonDiamond;
    }

    function __bridgePolygonDepositFor(DepositData memory depositData)
        internal
        virtual
    {
        for (uint256 i; i < depositData.stakedTokenIds.length; i++) {
            NFTLib.unstake(depositData.stakedTokenIds[i]);
        }
        // call the depositFor funciton at the rootChainManager
        bytes memory encodedData = abi.encodeWithSignature(
            "depositFor(address,address,bytes)",
            POLYGON_DIAMOND,
            address(TELLER_NFT),
            abi.encode(depositData)
        );

        // root chain manager
        Address.functionCall(
            0xD4888faB8bd39A663B63161F5eE1Eae31a25B653,
            encodedData
        );
    }

    function initNFTBridge() external {
        __initNFTBridge();
    }

    function __initNFTBridge() internal virtual {
        TELLER_NFT.setApprovalForAll(ERC721_PREDICATE, true);
    }

    function stakeNFTsOnBehalfOfUser(uint256[] memory tokenIds, address user)
        external
    {
        console.log("staking nfts on behalf of user");
        for (uint256 i; i < tokenIds.length; i++) {
            EnumerableSet.add(NFTLib.s().stakedNFTs[user], tokenIds[i]);
        }
    }

    function bridgeNFT(uint256 tokenId) external {
        bool isStaked = EnumerableSet.contains(
            NFTLib.s().stakedNFTs[msg.sender],
            tokenId
        );
        DepositData memory dd;
        dd.user = msg.sender;
        if (isStaked) {
            dd.stakedTokenIds = new uint256[](tokenId);
            dd.unstakedTokenIds = new uint256[](0);
        } else {
            dd.stakedTokenIds = new uint256[](0);
            dd.unstakedTokenIds = new uint256[](tokenId);
        }
        __bridgePolygonDepositFor(dd);
    }

    function bridgeAllNFTs(DepositData memory depositData) external {
        for (uint256 i; i < depositData.stakedTokenIds.length; i++) {
            NFTLib.unstake(depositData.stakedTokenIds[i]);
        }
        __bridgePolygonDepositFor(
            DepositData(
                msg.sender,
                NFTLib.stakedNFTs(msg.sender),
                TELLER_NFT.getOwnedTokens(msg.sender)
            )
        );
    }
}
