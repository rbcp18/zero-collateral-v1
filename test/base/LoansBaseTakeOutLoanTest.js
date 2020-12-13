// JS Libraries
const withData = require("leche").withData;
const BN = require('bignumber.js')

const { t, getLatestTimestamp, ONE_HOUR, FIVE_MIN, NULL_ADDRESS, TERMS_SET, ACTIVE, TEN_THOUSAND, SECONDS_PER_YEAR_4DP } = require("../utils/consts");
const { createLoanTerms } = require("../utils/structs");
const { loans } = require("../utils/events");
const { createTestSettingsInstance } = require("../utils/settings-helper");
const { createLoan } = require('../utils/loans')
const settingsNames = require('../utils/platformSettingsNames')

const EscrowFactoryInterfaceEncoder = require("../utils/encoders/EscrowFactoryInterfaceEncoder");

// Mock contracts
const Mock = artifacts.require("./mock/util/Mock.sol");
const LINKMock = artifacts.require("./mock/token/LINKMock.sol");

// Smart contracts
const Settings = artifacts.require("./base/Settings.sol");
const Loans = artifacts.require("./mock/base/LoansBaseMock.sol");

// Libraries
const LoanLib = artifacts.require("../util/LoanLib.sol");

contract("LoansBaseTakeOutLoanTest", function(accounts) {
  const escrowFactoryInterfaceEncoder = new EscrowFactoryInterfaceEncoder(web3);

  const owner = accounts[0];
  let instance;
  let loanTermsConsInstance;
  let collateralTokenInstance;
  let chainlinkAggregatorInstance;

  const mockLoanID = 0;
  const overCollateralizedBuffer = 13000
  const safetyInterval = FIVE_MIN

  const borrower = accounts[3];

  let loanTerms = createLoanTerms(borrower, NULL_ADDRESS, 1475, 3564, 15000000, 0);

  beforeEach("Setup for each test", async () => {
    const lendingPoolInstance = await Mock.new();
    const lendingTokenInstance = await Mock.new();
    collateralTokenInstance = await LINKMock.new();
    const settingsInstance = await createTestSettingsInstance(
      Settings,
      {
        from: owner,
        Mock,
        initialize: true,
        onInitialize: async (instance, { escrowFactory, chainlinkAggregator }) => {
          const newEscrowInstance = await Mock.new();
          await escrowFactory.givenMethodReturnAddress(
            escrowFactoryInterfaceEncoder.encodeCreateEscrow(),
            newEscrowInstance.address
          );

          chainlinkAggregatorInstance = chainlinkAggregator
        }
      }, {
        [settingsNames.OverCollateralizedBuffer]: overCollateralizedBuffer,
        [settingsNames.SafetyInterval]: safetyInterval,
      });

    loanTermsConsInstance = await Mock.new();
    const loanLib = await LoanLib.new();
    await Loans.link("LoanLib", loanLib.address);
    instance = await Loans.new();
    await instance.initialize(
      lendingPoolInstance.address,
      loanTermsConsInstance.address,
      settingsInstance.address,
      collateralTokenInstance.address
    );

  });

  withData({
    _1_max_loan_exceeded: [ 15000001, false, false, 300000, NULL_ADDRESS, 0, 0, false, true, "MAX_LOAN_EXCEEDED" ],
    _2_loan_terms_expired: [ 15000000, true, false, 300000, NULL_ADDRESS, 0, 0, false, true, "LOAN_TERMS_EXPIRED" ],
    _3_collateral_deposited_recently: [ 15000000, false, true, 300000, NULL_ADDRESS, 0, 0, false, true, "COLLATERAL_DEPOSITED_RECENTLY" ],
    _4_more_collateral_needed: [ 15000000, false, false, 300000, NULL_ADDRESS, 45158, 18, true, true, "MORE_COLLATERAL_REQUIRED" ],
    _5_successful_loan: [ 15000000, false, false, 300000, NULL_ADDRESS, 40000, 18, false, false, undefined ],
    _6_with_recipient: [ 15000000, false, false, 300000, accounts[4], 40000, 18, false, false, undefined ]
  }, function(
    amountToBorrow,
    termsExpired,
    collateralTooRecent,
    loanDuration,
    recipient,
    oraclePrice,
    tokenDecimals,
    moreCollateralRequired,
    mustFail,
    expectedErrorMessage
  ) {
    it(t("user", "takeOutLoan", "Should able to take out a loan.", false), async function() {
      // Setup
      const timeNow = new BN(await getLatestTimestamp());
      await collateralTokenInstance.mint(loanTerms.borrower, amountToBorrow);

      let termsExpiry
      if (termsExpired) {
        termsExpiry = timeNow.minus(1);
      } else {
        termsExpiry = timeNow.plus(FIVE_MIN);
      }

      let lastCollateralIn = timeNow.minus(ONE_HOUR)
      if (collateralTooRecent) {
        lastCollateralIn = timeNow
      }

      loanTerms.duration = loanDuration;
      loanTerms.recipient = recipient;
      const loan = createLoan({
        id: mockLoanID,
        loanTerms,
        collateral: 40000,
        lastCollateralIn: lastCollateralIn.toString(),
        borrowedAmount: loanTerms.maxLoanAmount,
        status: TERMS_SET,
        termsExpiry: termsExpiry.toString()
      });
      await instance.setLoan(loan);
      await collateralTokenInstance.approve(instance.address, amountToBorrow, { from: borrower });
      if (moreCollateralRequired) {
        await instance.mockGetCollateralInfo(mockLoanID, loan.borrowedAmount, (loan.collateral*2))
      } else {
        await instance.mockGetCollateralInfo(mockLoanID, loan.borrowedAmount, loan.collateral)
      }
      
      try {
        // Invocation
        const tx = await instance.takeOutLoan(mockLoanID, amountToBorrow, { from: borrower });

        // Assertions
        assert(!mustFail, "It should have failed because data is invalid.");
        assert(tx);

        const txTime = (await web3.eth.getBlock(tx.receipt.blockNumber)).timestamp;
        const interestOwed = Math.floor(amountToBorrow * 1475 * loanDuration / TEN_THOUSAND / SECONDS_PER_YEAR_4DP);
        const loan = await instance.loans.call(mockLoanID);

        assert.equal(loan.loanStartTime.toString(), txTime, 'loan start time not match');
        assert.equal(loan.principalOwed.toString(), amountToBorrow, 'loan principal owed not match');
        assert.equal(loan.interestOwed.toString(), interestOwed, 'loan interest owed not match');
        assert.equal(loan.status.toString(), ACTIVE, 'loan status not match');
        assert(loan.escrow.toString() !== NULL_ADDRESS, 'loan does not have an escrow');

        loans
          .loanTakenOut(tx)
          .emitted(mockLoanID, borrower, loan.escrow, amountToBorrow);

      } catch (error) {
        assert(mustFail, error.message);
        assert.equal(error.reason, expectedErrorMessage, error.reason);
      }
    });
  });
});