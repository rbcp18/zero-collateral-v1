// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { RolesMods } from "../contexts2/access-control/roles/RolesMods.sol";
import { ADMIN, AUTHORIZED } from "../shared/roles.sol";
import "../nft/TellerNFTDictionary.sol";

// Libraries
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { NFTLib } from "./libraries/NFTLib.sol";
import { RolesLib } from "../contexts2/access-control/roles/RolesLib.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract NFTFacet is RolesMods {
    /**
     * @notice it gets the staked NFTs mapped to an owner's address
     * @return staked_ the returned staked NFTs mapped to an owner's address
     */
    function getStakedNFTs(address nftOwner)
        public
        view
        returns (uint256[] memory staked_)
    {
        staked_ = NFTLib.stakedNFTs(nftOwner);
    }

    /**
     * @notice it returns the NFTs mapped to a loan
     * @param loanID the identifier of the respective loan to get the loan NFTs from
     * @return loanNFTs the loan NFTs mapped to a loan ID
     */
    function getLoanNFTs(uint256 loanID)
        external
        view
        returns (uint256[] memory loanNFTs)
    {
        EnumerableSet.UintSet storage nfts = NFTLib.s().loanNFTs[loanID];
        loanNFTs = new uint256[](EnumerableSet.length(nfts));
        for (uint256 i; i < EnumerableSet.length(nfts); i++) {
            loanNFTs[i] = EnumerableSet.at(nfts, i);
        }
    }

    /**
     * @notice Transfers multiple Teller NFTs to Diamond and applies user stake.
     * @param nftIDs IDs of Teller NFTs to stake.
     */
    function stakeNFTs(uint256[] calldata nftIDs) external {
        for (uint256 i; i < nftIDs.length; i++) {
            // Stake NFT and transfer into diamond
            NFTLib.stake(nftIDs[i], msg.sender);
        }
        // Give the caller authorization to protocol
        RolesLib.grantRole(AUTHORIZED, msg.sender);
    }

    /**
     * @notice it unstakes our NFTs and removes them from our mapping
     * @param nftIDs the nftIDs to unstake
     */
    function unstakeNFTs(uint256[] calldata nftIDs) external {
        for (uint256 i; i < nftIDs.length; i++) {
            // Unstake NFTs
            NFTLib.unstake(nftIDs[i]);
            NFTLib.nft().transferFrom(address(this), msg.sender, nftIDs[i]);
        }
    }

    /**
     * @notice Sets the NFTDictionary address used to get information about an NFT and its tier.
     * @param dictAddress Dictionary address to use.
     *
     * Requirements:
     *  - Sender must have `ADMIN` role
     */
    function setNFTDictionary(address dictAddress)
        external
        authorized(ADMIN, msg.sender)
    {
        NFTLib.s().nftDictionary = TellerNFTDictionary(dictAddress);
    }

    // create a new facet
    // create initNFTBridge() ->
    //      setApprovalForAll() -> on nfts belonging to ERC721 predicate
    //
    // create bridgeNFTToPolygon()
    //      call unstake function()
    //      encode [ownedNFTs, borrower] -> depositData
    //      call depositFor()
    //          rootChainManager contract -> (diamond.address (polygon), tellerNFTAddress(mainnet), depositData)
    //
    //
    // create stakeNFTsOnBehalfOf(uint256[] tokenIds, address user) ->  EnumerableSet.add(s().stakedNFTs[owner], nftID);

    // call stakeNFTs() -> on polytellernft
    // call childchainmanager -> deposit() ^ same parameters
    // call init() ->
    //      set deployer as depositor only for tests

    // create bridgeNFTToMainnet()
    //      call withdrawBatch function()
    //

    // steps
    // approval - automatic
    // mockMainnetFacet -> bridgeNFTToPolygon(). called from tests
    // polyTellerNFT -> deposit(). called from tests
}
