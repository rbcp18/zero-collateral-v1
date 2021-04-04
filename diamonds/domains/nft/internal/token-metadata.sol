// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import "../storage/tier.sol";

// Libraries
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract int_TokenMetadata_v1 is sto_Tier_v1 {
    using SafeMath for uint256;

    /**
     * @notice The base URI path where the token media is hosted.
     * @dev Base URI for computing {tokenURI}.
     */
    function _baseURI() internal view override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/";
    }

    /**
     * @notice It returns the hash to use for the token URI.
     */
    function _tokenURI(uint256 tokenId) internal view returns (string memory) {
        string[] storage tierImageHashes =
            tierStore().tiers[tierStore().tokenTierMap[tokenId]].hashes;
        return tierImageHashes[tokenId.mod(tierImageHashes.length)];
    }
}
