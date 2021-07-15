// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import { NFTMainnetBridgingToPolygonFacet } from "../NFTMainnetBridgingToPolygonFacet.sol";
import { NFTLib } from "../libraries/NFTLib.sol";

contract MockNFTMainnetBridgingToPolygonFacet is
    NFTMainnetBridgingToPolygonFacet
{
    constructor(address polygonNFT)
        NFTMainnetBridgingToPolygonFacet(polygonNFT)
    {}

    function __initNFTBridge() internal override {
        TELLER_NFT.setApprovalForAll(address(this), true);
    }

    /**
     * @notice it doesn't call the rootchain manager. used for mock tests
     * @dev see __bridgePolygonDepositFor on NFTMainnetBridgingToPolygonFacet
     * @param tokenData the tokenData that's decoded and bridged
     * @param staked are the tokens sent by the user staked?
     */
    function __bridgePolygonDepositFor(bytes memory tokenData, bool staked)
        internal
        override
    {
        if (tokenData.length == 32) {
            uint256 tokenId = abi.decode(tokenData, (uint256));
            if (staked) {
                NFTLib.unstake(tokenId);
            } else {
                NFTLib.nft().transferFrom(msg.sender, address(this), tokenId);
            }
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
        }
    }
}
