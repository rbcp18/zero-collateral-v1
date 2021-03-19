pragma solidity 0.5.17;
pragma experimental ABIEncoderV2;

// Commons
import "../../util/TellerCommon.sol";

// Interfaces
import "../SettingsInterface.sol";

/**
    @notice This interface defines the functions to work with the Teller loans protocol

    @author develop@teller.finance
 */

interface ILoanManager {
    /**
        @notice Deposit collateral for a loan, unless it isn't allowed
        @param borrower Account address of the borrower
        @param loanID ID of loan from which collateral was withdrawn
        @param amount Amount to be deposited as collateral
     */
    function depositCollateral(
        address borrower,
        uint256 loanID,
        uint256 amount
    ) external payable;

    /**
        @notice Withdraw collateral from a loan, unless this isn't allowed
        @param amount The amount of collateral token or ether the caller is hoping to withdraw
        @param loanID The ID of the loan the collateral is for
     */
    function withdrawCollateral(uint256 amount, uint256 loanID) external;

    /**
        @notice Create a loan with specified terms, if allowed
        @param request Struct of the protocol loan request
        @param responses List of structs of the protocol loan responses
        @param collateralAmount Amount of collateral for the loan
     */
    function createLoanWithTerms(
        TellerCommon.LoanRequest calldata request,
        TellerCommon.LoanResponse[] calldata responses,
        uint256 collateralAmount
    ) external payable;

    /**
        @notice Take out a loan, if allowed
        @param loanID The ID of the loan to be taken out
        @param amountBorrow Amount of tokens to be taken out in the loan
     */
    function takeOutLoan(uint256 loanID, uint256 amountBorrow) external;

    /**
        @notice Make a payment to a specified loan
        @param amount The amount of tokens to pay back to the loan
        @param loanID The ID of the loan the payment is for
     */
    function repay(uint256 amount, uint256 loanID) external;

    /**
        @notice Liquidate a loan if has is expired or under collateralized
        @param loanID The ID of the loan to be liquidated
     */
    function liquidateLoan(uint256 loanID) external;

    /**
        @notice Initializes the current contract instance setting the required parameters, if allowed
        @param lendingPoolAddress Contract address of the lending pool
        @param loanTermsConsensusAddress Contract address for loan term consensus
        @param settingsAddress Contract address for the configuration of the platform
        @param collateralTokenAddress Contract address for the collateral token
     */
    function initialize(
        address lendingPoolAddress,
        address loanTermsConsensusAddress,
        address settingsAddress,
        address collateralTokenAddress
    ) external;

    /**
        @notice This event is emitted when collateral has been deposited for the loan
        @param loanID ID of the loan for which collateral was deposited
        @param borrower Account address of the borrower
        @param depositAmount Amount of collateral deposited
     */
    event CollateralDeposited(
        uint256 indexed loanID,
        address indexed borrower,
        uint256 depositAmount
    );

    /**
        @notice This event is emitted when collateral has been withdrawn
        @param loanID ID of loan from which collateral was withdrawn
        @param borrower Account address of the borrower
     */
    event CollateralWithdrawn(
        uint256 indexed loanID,
        address indexed borrower,
        uint256 withdrawalAmount
    );

    /**
        @notice This event is emitted when loan terms have been successfully set
        @param loanID ID of loan from which collateral was withdrawn
        @param borrower Account address of the borrower
        @param recipient Account address of the recipient
        @param interestRate Interest rate set in the loan terms
        @param collateralRatio Collateral ratio set in the loan terms
        @param maxLoanAmount Maximum loan amount that can be taken out, set in the loan terms
     */
    event LoanTermsSet(
        uint256 indexed loanID,
        address indexed borrower,
        address indexed recipient,
        uint256 interestRate,
        uint256 collateralRatio,
        uint256 maxLoanAmount,
        uint256 duration,
        uint256 termsExpiry
    );

    /**
        @notice This event is emitted when a loan has been successfully taken out
        @param loanID ID of loan from which collateral was withdrawn
        @param borrower Account address of the borrower
        @param escrow Escrow address associated to this loan
        @param amountBorrowed Total amount taken out in the loan
     */
    event LoanTakenOut(
        uint256 indexed loanID,
        address indexed borrower,
        address indexed escrow,
        uint256 amountBorrowed
    );

    /**
        @notice This event is emitted when a new Escrow contract is created.
        @param borrower address associated to the new escrow.
        @param loanID loan id associated to the borrower and escrow contract.
        @param escrowAddress the new escrow contract address.
     */
    event EscrowCreated(
        address indexed borrower,
        uint256 indexed loanID,
        address escrowAddress
    );

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
        @notice This event is emitted when a loan has been successfully liquidated
        @param loanID ID of loan from which collateral was withdrawn
        @param borrower Account address of the borrower
        @param liquidator Account address of the liquidator
        @param collateralOut Collateral that is sent to the liquidator
        @param tokensIn Percentage of the collateral price paid by the liquidator to the lending pool
     */
    event LoanLiquidated(
        uint256 indexed loanID,
        address indexed borrower,
        address liquidator,
        uint256 collateralOut,
        uint256 tokensIn
    );
}