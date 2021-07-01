// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// address constant CORE = address(0);
// bytes32 constant CHAINLINK_REGISTRY_SALT = keccak256(
//     "teller.finance.chainlink.registry.salt"
// );

// function c2a(
//     address deployer,
//     bytes32 salt,
//     bytes32 initCodeHash
// ) pure returns (address) {
//     return
//         address(
//             uint160(
//                 uint256(
//                     keccak256(
//                         abi.encodePacked(hex"ff", deployer, salt, initCodeHash)
//                     )
//                 )
//             )
//         );
// }

// library TellerAssets {
//     uint32 internal constant TLR = 0;
//     uint32 internal constant ETH = 1;
//     uint32 internal constant DAI = 2;
//     uint32 internal constant YFI = 3;
//     uint32 internal constant LINK = 4;

//     enum AssetType { ERC20, ERC721, ERC1155 }

//     function assetType(uint256 assetId) pure returns (AssetType assetType_) {
//         return AssetType(uint8(bytes1(bytes32(assetId))));
//     }

//     /**
//         Get the Teller ERC20 token ID encoded in the bytes [1..5] of an assetId.
//         This ID can help reduce the cost of retrieving metadata about a token, like
//         the chainlink price feed oracle address for that token and ETH.
//         @param assetId uint256 id of the asset to get the Teller erc20 token id for.
//         @return uint32 Teller erc20 token id.
//     */
//     function get(uint256 assetId) internal pure returns (uint32) {
//         return uint32(bytes4(bytes32(assetId << 8)));
//     }

//     function value(uint256 assetId, uint256 amount)
//         internal
//         view
//         returns (uint256 value_)
//     {
//         AssetType typ = assetType(assetId);

//         if (typ == AssetType.ERC20) {
//             return erc20Value(assetId, amount);
//             // chainlink
//         } else if (typ == AssetType.ERC721) {
//             // nft price?
//             revert("Teller: no price for asset");
//         } else if (typ == ERC1155) {
//             // erc1155 price?
//             revert("Teller: no price for asset");
//         } else {
//             revert("Teller: no price for asset");
//         }
//     }

//     function erc20Value(uint256 assetId, uint256 amount)
//         internal
//         view
//         returns (uint256 value_)
//     {
//         address core = CORE;
//         uint256 erc20Id = get(assetId);
//         uint256 assetIndex = erc20Id % 200;
//         bytes32 targetSalt = CHAINLINK_REGISTRY_SALT ^ bytes32(erc20Id / 200);
//         address target = c2a(core, targetSalt, mmCodeHash);
//         address chainlinkAggregator;

//         assembly {
//             extcodecopy(target, 0, assetIndex, 20)
//             chainlinkAggregator := mload(0)
//         }

//         value_ = ChainlinkAggregatorV2V3Interface(chainlinkAggregator)
//             .latestRound();
//     }
// }
