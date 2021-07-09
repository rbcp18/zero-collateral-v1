// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import { LoanRequest } from "../../../storage/market.sol";
import {
    EnumerableSet
} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { MarketHandler } from "./MarketHandler.sol";
import { Rates } from "../../data/states.sol";

contract TellerMarketHandler is MarketHandler, Rates {
    constructor(
        uint16 maxInterestRate,
        uint16 collateralRatio,
        uint256 maxLoanAmount
    ) MarketHandler(maxInterestRate, collateralRatio, maxLoanAmount) {}

    // teller market handler
    function handler(uint256 marketScore, LoanRequest memory request)
        external
        view
        override
        returns (
            uint16 userInterestRate,
            uint16 userCollateralRatio,
            uint256 userLoanAmount
        )
    {
        uint256 amount = 0;

        // get amount for user based on market score
        if (marketScore >= 5 && marketScore < 7) {
            amount = _loanAmount(18000, 10000, 7, 5, marketScore);
        } else if (marketScore >= 7 && marketScore < 9) {
            amount = _loanAmount(23000, 18000, 9, 7, marketScore);
        } else if (marketScore >= 9 && marketScore <= 10) {
            amount = _loanAmount(25000, 23000, 10, 9, marketScore);
        }

        // get interest rate
        uint16 baseInterestRate = 1000;

        uint16 interestRate =
            baseInterestRate *
                ((maxCollateralRatio / request.request.collateralRatio) / 2);

        // Illinois interest rate for testing
        uint16 sampleCappedInterestRate = rates[uint16(request.request.code)];

        bool useLegalIR = interestRate > sampleCappedInterestRate;

        if (useLegalIR) {
            userInterestRate = sampleCappedInterestRate;
            userLoanAmount =
                (amount) /
                (interestRate / (sampleCappedInterestRate + 1));
        } else {
            userInterestRate = interestRate;
            //
            userLoanAmount = amount;
        }

        userCollateralRatio = request.request.collateralRatio;
    }

    /**
     * @notice it calculates the loan amount from different bounds
     * @param highestAmountBound the highest amount in a select bound (i.e 20000)
     * @param lowestAmountBound the lowest amount in a select bound (i.e 10000)
     * @param highestScoreBound the highest score in a select bound (i.e 7.5)
     * @param lowestScoreBound the lowest score in a select bound
     */
    function _loanAmount(
        uint256 highestAmountBound,
        uint256 lowestAmountBound,
        uint16 highestScoreBound,
        uint16 lowestScoreBound,
        uint256 scoreToCalculate
    ) internal pure returns (uint256 amount) {
        // calculate for slope
        uint256 m =
            (highestAmountBound - lowestAmountBound) /
                (highestScoreBound - lowestScoreBound);

        // return amount
        amount =
            highestAmountBound -
            ((m) * uint256((highestScoreBound - scoreToCalculate)));
    }
}
