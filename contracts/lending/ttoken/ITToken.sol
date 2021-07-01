// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contracts
import {
    ERC20Upgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    RolesFacet
} from "../../contexts2/access-control/roles/RolesFacet.sol";

/**
 * @notice This contract acts as an interface for the Teller token (TToken).
 *
 * @author develop@teller.finance
 */
abstract contract ITToken is ERC20Upgradeable, RolesFacet {
    /**
     * @notice This event is emitted when a user deposits tokens into the pool.
     */
    event Mint(
        address indexed sender,
        uint256 tTokenAmount,
        uint256 underlyingAmount
    );

    /**
     * @notice This event is emitted when a user withdraws tokens from the pool.
     */
    event Redeem(
        address indexed sender,
        uint256 tTokenAmount,
        uint256 underlyingAmount
    );

    /**
     * @notice The token that is the underlying assets for this Teller token.
     * @return ERC20 token
     */
    function underlying() external view virtual returns (ERC20);

    /**
     * @notice The balance of an {account} denoted in underlying value.
     * @param account Address to calculate the underlying balance.
     * @return balance_ the balance of the account
     */
    function balanceOfUnderlying(address account)
        external
        virtual
        returns (uint256 balance_);

    /**
     * @notice It calculates the current exchange rate for a whole Teller Token based of the underlying token balance.
     * @return rate_ The current exchange rate.
     */
    function exchangeRate() external virtual returns (uint256 rate_);

    /**
     * @notice It calculates the total supply of the underlying asset.
     * @return totalSupply_ the total supply denoted in the underlying asset.
     */
    function totalUnderlyingSupply()
        external
        virtual
        returns (uint256 totalSupply_);

    /**
     * @notice It calculates the market state values across a given market.
     * @notice Returns values that represent the global state across the market.
     * @return totalSupplied Total amount of the underlying asset supplied.
     * @return totalBorrowed Total amount borrowed through loans.
     * @return totalRepaid The total amount repaid till the current timestamp.
     * @return totalInterestRepaid The total amount interest repaid till the current timestamp.
     * @return totalOnLoan Total amount currently deployed in loans.
     */
    function getMarketState()
        external
        virtual
        returns (
            uint256 totalSupplied,
            uint256 totalBorrowed,
            uint256 totalRepaid,
            uint256 totalInterestRepaid,
            uint256 totalOnLoan
        );

    /**
     * @notice Calculates the current Total Value Locked, denoted in the underlying asset, in the Teller Token pool.
     * @return tvl_ The value locked in the pool.
     *
     * Note: This value includes the amount that is on loan (including ones that were sent to EOAs).
     */
    function currentTVL() external virtual returns (uint256 tvl_);

    /**
     * @notice It validates whether supply to debt (StD) ratio is valid including the loan amount.
     * @param newLoanAmount the new loan amount to consider the StD ratio.
     * @return ratio_ Whether debt ratio for lending pool is valid.
     */
    function debtRatioFor(uint256 newLoanAmount)
        external
        virtual
        returns (uint16 ratio_);

    /**
     * @notice Called by the Teller Diamond contract when a loan has been taken out and requires funds.
     * @param recipient The account to send the funds to.
     * @param amount Funds requested to fulfill the loan.
     */
    function fundLoan(address recipient, uint256 amount) external virtual;

    /**
     * @notice Called by the Teller Diamond contract when a loan has been repaid.
     * @param amount Funds deposited back into the pool to repay the principal amount of a loan.
     * @param interestAmount Interest value paid into the pool from a loan.
     */
    function repayLoan(uint256 amount, uint256 interestAmount) external virtual;

    /**
     * @notice Increase account supply of specified token amount.
     * @param amount The amount of underlying tokens to use to mint.
     * @return mintAmount_ the amount minted of the specified token
     */
    function mint(uint256 amount)
        external
        virtual
        returns (uint256 mintAmount_);

    /**
     * @notice Redeem supplied Teller token underlying value.
     * @param amount The amount of Teller tokens to redeem.
     */
    function redeem(uint256 amount) external virtual;

    /**
     * @notice Redeem supplied underlying value.
     * @param amount The amount of underlying tokens to redeem.
     */
    function redeemUnderlying(uint256 amount) external virtual;

    /**
     * @notice Rebalances the funds controlled by Teller Token according to the current strategy.
     *
     * See {TTokenStrategy}.
     */
    function rebalance() external virtual;

    /**
     * @notice Sets a new strategy to use for balancing funds.
     * @param strategy Address to the new strategy contract. Must implement the {ITTokenStrategy} interface.
     * @param initData Optional data to initialize the strategy.
     *
     * Requirements:
     *  - Sender must have ADMIN role
     */
    function setStrategy(address strategy, bytes calldata initData)
        external
        virtual;

    /**
     * @notice Gets the strategy used for balancing funds.
     * @return address of the strategy contract
     */
    function getStrategy() external view virtual returns (address);

    /**
     * @notice Sets the restricted state of the platform.
     * @param state boolean value that resembles the platform's state
     */
    function restrict(bool state) external virtual;

    /**
     * @notice it initializes the Teller Token
     * @param admin address of the admin to the respective Teller Token
     * @param underlying address of the ERC20 token
     */
    function initialize(address admin, address underlying) external virtual;
}
