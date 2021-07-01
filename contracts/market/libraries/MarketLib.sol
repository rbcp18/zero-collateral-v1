// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// external contracts
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

// Teller contracts
import { PausableMods } from "../../settings/pausable/PausableMods.sol";
import {
    ReentryMods
} from "../../contexts2/access-control/reentry/ReentryMods.sol";
import { RolesMods } from "../../contexts2/access-control/roles/RolesMods.sol";
import { ADMIN } from "../../shared/roles.sol";
import {
    Signature,
    MarketStorageLib,
    MarketStorage,
    MarketConfig,
    ProviderConfig,
    LoanRequest
} from "../../storage/market.sol";
import { Verifier } from "../cra/verifier.sol";
import { LibLoans } from "../libraries/LibLoans.sol";
// import reentry guard
import "hardhat/console.sol";

library MarketLib {
    // function s() internal pure returns (MarketStorage storage s_) {
    //     s_ = MarketStorageLib.store();
    // }
    // function m(bytes32 marketId)
    //     internal
    //     view
    //     returns (MarketConfig storage m_)
    // {
    //     m_ = s().markets[marketId];
    // }
    // function p(bytes32 providerId)
    //     internal
    //     view
    //     returns (ProviderConfig storage p_)
    // {
    //     p_ = s().providers[providerId];
    // }
    // function c(bytes32 commitmentId) internal view returns (bool c_) {
    //     c_ = s().usedCommitments[commitmentId];
    // }
    // function setProviderAdmin(
    //     bytes32 providerId,
    //     address account,
    //     bool admin
    // ) internal onlyProviderAdmin(providerId) {
    //     p(providerId).signer[account] = admin;
    // }
    // function getProviderAdmin(bytes32 providerId)
    //     internal
    //     view
    //     returns (bool admin)
    // {
    //     admin = p(providerId).signer[msg.sender];
    // }
    // function setProviderSigner(
    //     bytes32 providerId,
    //     address account,
    //     bool signerValue
    // ) internal onlyProviderAdmin(providerId) {
    //     p(providerId).signer[account] = signerValue;
    // }
    // function setProviderMaxAge(bytes32 providerId, uint32 maxAge)
    //     internal
    //     onlyProviderAdmin(providerId)
    // {
    //     p(providerId).maxAge = maxAge;
    // }
    // function setMarketAdmin(
    //     bytes32 marketId,
    //     address account,
    //     bool admin
    // ) internal onlyMarketAdmin(marketId) {
    //     m(marketId).admin[account] = admin;
    // }
    // /**
    //  * @notice it gets the user score and user request then returns the loan interest rate,
    //  * loan collateral ratio and loan amount.
    //  * @param marketScore the score of the user
    //  * @param request the user's request for the loan
    //  * @return userInterestRate returns the interest rate for the user based on his score
    //  * @return userCollateralRatio returns the collateral ratio of the user based on his score
    //  * @return userLoanAmount returns the amount for the user to take a loan out based on his score
    //  */
    // function handler(uint256 marketScore, LoanRequest memory request)
    //     internal
    //     pure
    //     returns (
    //         uint16 userInterestRate,
    //         uint16 userCollateralRatio,
    //         uint256 userLoanAmount
    //     )
    // {
    //     require(marketScore > 5, "market score not high enough!");
    //     (
    //         uint16 marketInterestRate,
    //         uint16 marketCollateralRatio,
    //         uint256 marketLoanAmount
    //     ) = _getMarketInformation(request.marketId);
    //     // uint256 marketScoreForInterestRatio = (marketScore - 5) / 5;
    //     // userInterestRate = uint16(
    //     //     marketInterestRate -
    //     //         (marketScoreForInterestRatio * marketInterestRate)
    //     // );
    //     // to compile for now
    //     userInterestRate = marketInterestRate;
    //     userCollateralRatio = marketCollateralRatio;
    //     userLoanAmount = marketLoanAmount;
    // }
    // /**
    //  * @notice it retrieves market information concerning max interest rate, collateral ratio and
    //  * loan amount. This information is for use by the market handler
    //  * @param marketId the market to get the information from
    //  * @return maxInterestRate the maximum interest rate set in a market
    //  * @return maxCollateralRatio the maximum collateral ratio set in a market
    //  * @return maxLoanAmount the maximum loan amount set in a market
    //  */
    // function _getMarketInformation(bytes32 marketId)
    //     internal
    //     pure
    //     returns (
    //         uint16 maxInterestRate,
    //         uint16 maxCollateralRatio,
    //         uint256 maxLoanAmount
    //     )
    // {
    //     uint16 _maxInterestRate;
    //     uint16 _maxCollateralRatio;
    //     uint256 _maxLoanAmount;
    //     // if market id is teller market
    //     if (marketId == bytes32(0)) {
    //         _maxInterestRate = 10000;
    //         _maxCollateralRatio = 15000;
    //         _maxLoanAmount = 25000;
    //     } else {
    //         // get market information from other markets
    //     }
    //     maxInterestRate = _maxInterestRate;
    //     maxCollateralRatio = _maxCollateralRatio;
    //     maxLoanAmount = _maxLoanAmount;
    // }
    // modifier onlyMarketAdmin(bytes32 marketId) {
    //     require(m(marketId).admin[msg.sender], "Teller: not market admin");
    //     _;
    // }
    // modifier onlyProviderAdmin(bytes32 providerId) {
    //     require(p(providerId).admin[msg.sender], "Teller: not provider admin");
    //     _;
    // }
}
