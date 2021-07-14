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
    address public constant ERC721_PREDICATE =
        0x74D83801586E9D3C4dc45FfCD30B54eA9C88cf9b;
    address public constant ROOT_CHAIN_MANAGER =
        0xD4888faB8bd39A663B63161F5eE1Eae31a25B653;
    TellerNFT public constant TELLER_NFT =
        TellerNFT(0x2ceB85a2402C94305526ab108e7597a102D6C175);

    constructor(address polygonNFT) {
        POLYGON_NFT_ADDRESS = polygonNFT;
    }

    /**
     * @dev calls the
     */
    function __bridgePolygonDepositFor(bytes memory tokenData, bool staked)
        internal
        virtual
    {
        bytes memory encodedData;
        if (tokenData.length == 32) {
            uint256 tokenId = abi.decode(tokenData, (uint256));
            if (staked) {
                NFTLib.unstake(tokenId);
            } else {
                NFTLib.nft().transferFrom(msg.sender, address(this), tokenId);
            }
            encodedData = abi.encodeWithSignature(
                "depositFor(address,address,bytes)",
                msg.sender,
                address(TELLER_NFT),
                abi.encode(tokenId)
            );
        } else {
            uint256[] memory tokenIds = abi.decode(tokenData, (uint256[]));
            if (staked) {
                for (uint256 i; i < tokenIds.length; i++) {
                    NFTLib.unstake(tokenIds[i]);
                }
            } else {
                for (uint256 i; i < tokenIds.length; i++) {
                    NFTLib.nft().transferFrom(
                        msg.sender,
                        address(this),
                        tokenIds[i]
                    );
                }
            }
            // call the depositFor funciton at the rootChainManager
            encodedData = abi.encodeWithSignature(
                "depositFor(address,address,bytes)",
                msg.sender,
                address(TELLER_NFT),
                abi.encode(tokenIds)
            );
        }

        // root chain manager
        Address.functionCall(ROOT_CHAIN_MANAGER, encodedData);
    }

    function initNFTBridge() external {
        __initNFTBridge();
    }

    function __initNFTBridge() internal virtual {
        TELLER_NFT.setApprovalForAll(ERC721_PREDICATE, true);
    }

    function bridgeNFT(uint256 tokenId) external {
        bool isStaked = EnumerableSet.contains(
            NFTLib.s().stakedNFTs[msg.sender],
            tokenId
        );
        if (isStaked) {
            NFTLib.unstake(tokenId);
            __bridgePolygonDepositFor(abi.encode(tokenId), true);
        } else {
            __bridgePolygonDepositFor(abi.encode(tokenId), false);
        }
    }

    function bridgeAllNFTs() external {
        console.log("briding nfts");
        uint256[] memory stakedTokenIds = NFTLib.stakedNFTs(msg.sender);
        uint256[] memory unstakedTokenIds = TELLER_NFT.getOwnedTokens(
            msg.sender
        );
        if (stakedTokenIds.length > 0) {
            __bridgePolygonDepositFor(abi.encode(stakedTokenIds), true);
        }

        if (unstakedTokenIds.length > 0) {
            __bridgePolygonDepositFor(abi.encode(unstakedTokenIds), false);
        }
    }
}
