// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import { RolesMods } from "../contexts2/access-control/roles/RolesMods.sol";
import { PausableMods } from "../settings/pausable/PausableMods.sol";
import { ReentryMods } from "../contexts2/access-control/reentry/ReentryMods.sol";
import { AUTHORIZED } from "../shared/roles.sol";
import { LoanDataFacet } from "./LoanDataFacet.sol";
import { EscrowClaimTokens } from "../escrow/EscrowClaimTokens.sol";

// Libraries
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { LibLoans } from "./libraries/LibLoans.sol";
import { LibCollateral } from "./libraries/LibCollateral.sol";
import { LibDapps } from "../escrow/dapps/libraries/LibDapps.sol";
import { LibEscrow } from "../escrow/libraries/LibEscrow.sol";
import { PlatformSettingsLib } from "../settings/platform/libraries/PlatformSettingsLib.sol";
import { NumbersLib } from "../shared/libraries/NumbersLib.sol";
import { PriceAggLib } from "../price-aggregator/PriceAggLib.sol";
import { NFTLib } from "../nft/libraries/NFTLib.sol";

// Interfaces
import { ITToken } from "../lending/ttoken/ITToken.sol";
import { ILoansEscrow } from "../escrow/escrow/ILoansEscrow.sol";

// Storage
import { MarketStorageLib, MarketStorage, Loan, LoanStatus } from "../storage/market.sol";
import { NFTStorageLib, NFTStorage } from "../storage/nft.sol";

contract RepayFacet is RolesMods, ReentryMods, PausableMods, EscrowClaimTokens {
    /**
        @notice This event is emitted when a loan has been successfully repaid
        @param loanID ID of loan from which collateral was withdrawn
        @param borrower Account address of the borrower
        @param amountPaid Amount of the loan paid back
        @param payer Account address of the payer
        @param totalOwed Total amount of the loan to be repaid
     */
    event LoanRepaid(
        uint256 indexed loanID,
        address indexed borrower,
        uint256 amountPaid,
        address payer,
        uint256 totalOwed
    );

    /**
     * @notice This event is emitted when a loan has been successfully liquidated
     * @param loanID ID of loan from which collateral was withdrawn
     * @param borrower Account address of the borrower
     * @param liquidator Account address of the liquidator
     * @param reward Value in lending token paid out to liquidator
     * @param tokensIn Percentage of the collateral price paid by the liquidator to the lending pool
     */
    event LoanLiquidated(
        uint256 indexed loanID,
        address indexed borrower,
        address liquidator,
        uint256 reward,
        uint256 tokensIn
    );

    /**
     * @notice Repay this Escrow's loan.
     * @dev If the Escrow's balance of the borrowed token is less than the amount to repay, transfer tokens from the sender's wallet.
     * @dev Only the owner of the Escrow can call this. If someone else wants to make a payment, they should call the loan manager directly.
     * @param loanID The id of the loan being used.
     * @param amount The amount being repaid.
     */
    function escrowRepay(uint256 loanID, uint256 amount)
        external
        paused("", false)
        authorized(AUTHORIZED, msg.sender)
        nonReentry("")
    {
        uint256 balance = LibEscrow.balanceOf(
            loanID,
            LibLoans.loan(loanID).lendingToken
        );
        uint256 totalOwed = LibLoans.getTotalOwed(loanID);
        // if there isn't enough balance in the escrow, then transfer amount needed to the escrow
        if (balance < totalOwed && amount > balance) {
            uint256 amountNeeded = amount > totalOwed
                ? totalOwed - (balance)
                : amount - (balance);

            SafeERC20.safeTransferFrom(
                IERC20(LibLoans.loan(loanID).lendingToken),
                msg.sender,
                address(LibEscrow.e(loanID)),
                amountNeeded
            );
        }

        __repayLoan(loanID, amount, address(LibEscrow.e(loanID)), false);
    }

    /**
     * @notice Make a payment to a loan
     * @param loanID The ID of the loan the payment is for
     * @param amount The amount of tokens to pay back to the loan
     */
    function repayLoan(uint256 loanID, uint256 amount)
        external
        nonReentry("")
        paused("", false)
        authorized(AUTHORIZED, msg.sender)
    {
        __repayLoan(loanID, amount, msg.sender, false);
    }

    /**
     * @notice it repays the loan, either from an escrow or from a regular address
     * @param loanID the identifier of the loan to repay
     * @param amount the amount to repay the loan
     * @param sender the address of the sender that wants to pay, can also be a loan escrow
     * @param isLiquidation is this loan being liquidated?
     * @return leftToPay_ the amount left to pay for the loan
     */
    function __repayLoan(
        uint256 loanID,
        uint256 amount,
        address sender,
        bool isLiquidation
    ) private returns (uint256 leftToPay_) {
        require(amount > 0, "Teller: zero repay");

        // calculate the actual amount to repay
        leftToPay_ =
            LibLoans.debt(loanID).principalOwed +
            LibLoans.debt(loanID).interestOwed;
        if (leftToPay_ < amount) {
            amount = leftToPay_;
            leftToPay_ = 0;
        } else {
            leftToPay_ -= amount;
        }

        // Get the Teller token for the loan
        ITToken tToken = MarketStorageLib.store().tTokens[
            LibLoans.loan(loanID).lendingToken
        ];
        // Transfer funds from an escrow if an escrow is calling it
        // Otherwise, transfer funds from an account
        if (address(LibEscrow.e(loanID)) == sender) {
            LibEscrow.e(loanID).claimToken(
                LibLoans.loan(loanID).lendingToken,
                address(tToken),
                amount
            );
        } else {
            SafeERC20.safeTransferFrom(
                IERC20(LibLoans.loan(loanID).lendingToken),
                sender,
                address(tToken),
                amount
            );
        }

        // Deduct the interest and principal owed
        uint256 principalPaid;
        uint256 interestPaid;
        if (amount < LibLoans.debt(loanID).interestOwed) {
            interestPaid = amount;
            LibLoans.debt(loanID).interestOwed -= amount;
        } else {
            if (LibLoans.debt(loanID).interestOwed > 0) {
                interestPaid = LibLoans.debt(loanID).interestOwed;
                amount -= interestPaid;
                LibLoans.debt(loanID).interestOwed = 0;
            }

            if (amount > 0) {
                principalPaid = amount;
                LibLoans.debt(loanID).principalOwed -= amount;
            }
        }

        // Tell the Teller Token value has been deposited back into the pool.
        tToken.repayLoan(principalPaid, interestPaid);

        if (isLiquidation) {
            // Make sure there is nothing left to repay on the loan
            require(leftToPay_ == 0, "Teller: liquidate partial repay");

            // Set loan status
            LibLoans.loan(loanID).status = LoanStatus.Liquidated;

            // Transfer NFT if linked
            NFTLib.liquidateNFT(loanID);
        } else {
            // if the loan is now fully paid, close it and withdraw borrower collateral
            if (leftToPay_ == 0) {
                LibLoans.loan(loanID).status = LoanStatus.Closed;

                // Check if the loan has a collateral token
                if (LibLoans.loan(loanID).collateralToken != address(0)) {
                    LibCollateral.withdrawAll(
                        loanID,
                        LibLoans.loan(loanID).borrower
                    );
                }

                // Claim tokens in the escrow for the loan if any
                __claimEscrowTokens(loanID);

                // Restake any NFTs linked to loan for borrower
                NFTLib.restakeLinked(loanID, LibLoans.loan(loanID).borrower);
            }

            emit LoanRepaid(
                loanID,
                LibLoans.loan(loanID).borrower,
                amount,
                msg.sender,
                leftToPay_
            );
        }
    }

    /**
     * @notice Liquidate a loan if it is expired or under collateralized
     * @param loanID The ID of the loan to be liquidated
     */
    function liquidateLoan(uint256 loanID)
        external
        nonReentry("")
        paused("", false)
        authorized(AUTHORIZED, msg.sender)
    {
        Loan storage loan = LibLoans.loan(loanID);
        uint256 collateralAmount = LibCollateral.e(loanID).loanSupply(loanID);
        require(
            RepayLib.isLiquidable(loanID, collateralAmount),
            "Teller: does not need liquidation"
        );

        // Calculate the reward before repaying the loan
        (uint256 rewardInLending, uint256 collateralInLending) = RepayLib
        .getLiquidationReward(loanID, collateralAmount);

        // The liquidator pays the amount still owed on the loan
        uint256 amountToLiquidate = LibLoans.debt(loanID).principalOwed +
            LibLoans.debt(loanID).interestOwed;

        __repayLoan(loanID, amountToLiquidate, msg.sender, true);

        // Payout the liquidator reward owed
        if (rewardInLending > 0) {
            RepayLib.payOutLiquidator(
                loanID,
                rewardInLending,
                collateralInLending,
                collateralAmount,
                payable(msg.sender)
            );
        }

        emit LoanLiquidated(
            loanID,
            loan.borrower,
            msg.sender,
            rewardInLending,
            amountToLiquidate
        );
    }

    /**
     * @notice It gets the current liquidation reward for a given loan.
     * @param loanID The loan ID to get the info.
     * @return inLending_ The value the liquidator will receive denoted in lending tokens.
     * @return inCollateral_ The value the liquidator will receive denoted in collateral tokens.
     */
    function getLiquidationReward(uint256 loanID)
        external
        view
        returns (uint256 inLending_, uint256 inCollateral_)
    {
        (inLending_, ) = RepayLib.getLiquidationReward(
            loanID,
            LibCollateral.e(loanID).loanSupply(loanID)
        );
        inCollateral_ = PriceAggLib.valueFor(
            LibLoans.loan(loanID).lendingToken,
            LibLoans.loan(loanID).collateralToken,
            inLending_
        );
    }
}

library RepayLib {
    uint256 constant SECONDS_PER_MONTH = 2592000;

    /**
     * @notice It checks if a loan can be liquidated.
     * @param loanID The loan ID to check.
     * @return true if the loan is liquidable.
     */
    function isLiquidable(uint256 loanID, uint256 collateralAmount)
        internal
        view
        returns (bool)
    {
        Loan storage loan = LibLoans.loan(loanID);
        // Check if loan can be liquidated
        if (loan.status != LoanStatus.Active) {
            return false;
        }

        if (loan.collateralRatio > 0) {
            // If loan has a collateral ratio, check how much is needed
            (, uint256 neededInCollateral, ) = LoanDataFacet(address(this))
            .getCollateralNeededInfo(loanID);
            if (neededInCollateral > collateralAmount) {
                return true;
            }
        }

        //if the loan is from an NFT, an additional 30 days grace is given
        if (
            loanUsesTellerNFT(loan) &&
            block.timestamp <
            loan.loanStartTime + loan.duration + SECONDS_PER_MONTH
        ) {
            return false;
        }

        // Otherwise, check if the loan has expired
        return block.timestamp >= loan.loanStartTime + loan.duration;
    }

    function loanUsesTellerNFT(Loan storage loan) internal view returns (bool) {
        EnumerableSet.UintSet storage nftSet = NFTStorageLib.store().loanNFTs[
            loan.id
        ];

        return EnumerableSet.length(nftSet) > 0;
    }

    /**
     * @notice It gets the current liquidation reward for a given loan.
     * @param loanID The loan ID to get the info.
     * @param collateralAmount The amount of collateral for the {loanID}. Passed in to save gas calling the collateral escrow multiple times.
     * @return reward_ The value the liquidator will receive denoted in lending tokens.
     */
    function getLiquidationReward(uint256 loanID, uint256 collateralAmount)
        internal
        view
        returns (uint256 reward_, uint256 collateralValue_)
    {
        uint256 amountToLiquidate = LibLoans.debt(loanID).principalOwed +
            LibLoans.debt(loanID).interestOwed;

        // Max reward is amount repaid on loan plus extra percentage
        uint256 maxReward = amountToLiquidate +
            NumbersLib.percent(
                amountToLiquidate,
                uint16(PlatformSettingsLib.getLiquidateRewardPercent())
            );

        // Calculate available collateral for reward
        if (collateralAmount > 0) {
            collateralValue_ = PriceAggLib.valueFor(
                LibLoans.loan(loanID).collateralToken,
                LibLoans.loan(loanID).lendingToken,
                collateralAmount
            );
            reward_ += collateralValue_;
        }

        // Calculate loan escrow value if collateral not enough to cover reward
        if (reward_ < maxReward) {
            reward_ += LibEscrow.calculateTotalValue(loanID);
        }

        // Cap the reward to max
        if (reward_ > maxReward) {
            reward_ = maxReward;
        }
    }

    /**
     * @notice Checks if the loan has an Escrow and claims any tokens then pays out the loan collateral.
     * @dev See Escrow.claimTokens for more info.
     * @param loanID The loan ID which is being liquidated
     * @param rewardInLending The total amount of reward based in the lending token to pay the liquidator
     * @param collateralInLending The amount of collateral that is available for the loan denoted in lending tokens
     * @param collateralAmount The amount of collateral that is available for the loan
     * @param liquidator The address of the liquidator where the liquidation reward will be sent to
     */
    function payOutLiquidator(
        uint256 loanID,
        uint256 rewardInLending,
        uint256 collateralInLending,
        uint256 collateralAmount,
        address payable liquidator
    ) internal {
        // check if loan is liquidated
        require(
            LibLoans.loan(loanID).status == LoanStatus.Liquidated,
            "Teller: loan not liquidated"
        );

        // if the lending reward is less than the collateral lending tokens, then aggregate
        // the value for the lending token with the collateral token and send it to the liquidator
        if (rewardInLending <= collateralInLending) {
            uint256 rewardInCollateral = PriceAggLib.valueFor(
                LibLoans.loan(loanID).lendingToken,
                LibLoans.loan(loanID).collateralToken,
                rewardInLending
            );

            LibCollateral.withdraw(loanID, rewardInCollateral, liquidator);
        } else {
            // Payout whats available in the collateral token
            LibCollateral.withdraw(loanID, collateralAmount, liquidator);

            // Claim remaining reward value from the loan escrow
            claimEscrowTokensByValue(
                loanID,
                liquidator,
                rewardInLending - collateralInLending
            );
        }
    }

    /**
     * @dev Send the equivalent of tokens owned by the loan escrow (in lending value) to the recipient,
     * @param loanID The loan ID to clam tokens from
     * @param recipient address to send the tokens to
     * @param value The value of escrow held tokens to be claimed based in lending value
     */
    function claimEscrowTokensByValue(
        uint256 loanID,
        address recipient,
        uint256 value
    ) private {
        EnumerableSet.AddressSet storage tokens = MarketStorageLib
        .store()
        .escrowTokens[loanID];
        uint256 valueLeftToTransfer = value;

        // Start with the lending token
        valueLeftToTransfer = claimEscrowToken(
            loanID,
            LibLoans.loan(loanID).lendingToken,
            recipient,
            valueLeftToTransfer
        );

        // Cycle through remaining tokens
        for (uint256 i = 0; i < EnumerableSet.length(tokens); i++) {
            if (valueLeftToTransfer == 0) {
                return;
            }

            valueLeftToTransfer = claimEscrowToken(
                loanID,
                EnumerableSet.at(tokens, i),
                recipient,
                valueLeftToTransfer
            );
        }
    }

    /**
     * @notice it claims the escrow tokens for the liquidator
     * @notice it keeps claiming escrow tokens until there aren't anymore tokens or the valueLeftToTransfer is zero
     * @param loanID the identifier of the escrow loan to claim tokens from
     * @param token the address of the token asset to claim
     * @param recipient the address of the recipient to transfer the tokens to
     * @param valueLeftToTransfer the value left to transfer to the liquidator that is returned back
     * @return the value left to transfer
     */
    function claimEscrowToken(
        uint256 loanID,
        address token,
        address recipient,
        uint256 valueLeftToTransfer
    ) private returns (uint256) {
        uint256 balance = LibEscrow.balanceOf(loanID, token);
        // get value of token balance in lending value
        if (balance > 0) {
            // If token not the lending token, get value of token
            uint256 balanceInLending;
            if (token == LibLoans.loan(loanID).lendingToken) {
                balanceInLending = balance;
            } else {
                balanceInLending = PriceAggLib.valueFor(
                    token,
                    LibLoans.loan(loanID).lendingToken,
                    balance
                );
            }

            if (balanceInLending <= valueLeftToTransfer) {
                LibEscrow.e(loanID).claimToken(token, recipient, balance);
                valueLeftToTransfer -= balanceInLending;
            } else {
                // Token balance is more than enough so calculate ratio of balance to transfer
                uint256 valueToTransfer;
                if (token == LibLoans.loan(loanID).lendingToken) {
                    valueToTransfer = valueLeftToTransfer;
                } else {
                    valueToTransfer = NumbersLib.percent(
                        balance,
                        NumbersLib.ratioOf(
                            valueLeftToTransfer,
                            balanceInLending
                        )
                    );
                }

                LibEscrow.e(loanID).claimToken(
                    token,
                    recipient,
                    valueToTransfer
                );
                valueLeftToTransfer = 0;
            }
        }
        return valueLeftToTransfer;
    }
}
