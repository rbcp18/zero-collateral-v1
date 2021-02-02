const BN = require('bignumber.js')

const {teller, tokens} = require("../../../scripts/utils/contracts");
const {
  loans: loansActions,
  tokens: tokensActions,
  settings: settingsActions,
} = require("../../../scripts/utils/actions");
const {
  loans: loansAssertions,
  tokens: tokensAssertions,
} = require("../../../scripts/utils/assertions")
const loanStatus = require("../../../test-old/utils/loanStatus")
const helperActions = require("../../../scripts/utils/actions/helper");
const { toDecimals, ONE_DAY, ONE_YEAR } = require("../../../test-old/utils/consts");
const platformSettingNames = require("../../../test-old/utils/platformSettingsNames")

module.exports = async (testContext) => {
  const {
    getContracts,
    accounts,
    collTokenName,
    tokenName,
  } = testContext;
  console.log("Scenario: Loans#13 - Take out loan to user's wallet.");

  const allContracts = await getContracts.getAllDeployed(
    {teller, tokens},
    tokenName,
    collTokenName
  );
  const {token, collateralToken} = allContracts;
  const tokenInfo = await tokensActions.getInfo({token});
  const collateralTokenInfo = await tokensActions.getInfo({
    token: collateralToken,
  });

  // calculate required collateral ratio to get loan funds into borrower's wallet
  const { value: overCollateralizedBuffer } = await settingsActions.getPlatformSettings(
    allContracts,
    { testContext },
    { settingName: platformSettingNames.OverCollateralizedBuffer }
  )
  const { value: collateralBuffer } = await settingsActions.getPlatformSettings(
    allContracts,
    { testContext },
    { settingName: platformSettingNames.CollateralBuffer }
  )
  const { value: liquidateEthPrice } = await settingsActions.getPlatformSettings(
    allContracts,
    { testContext },
    { settingName: platformSettingNames.LiquidateEthPrice }
  )
  const collateralRatio = new BN(overCollateralizedBuffer)
    .plus(collateralBuffer)
    .plus(new BN(10000).minus(liquidateEthPrice))
    .toFixed(0)

  const depositFundsAmount = toDecimals(300, tokenInfo.decimals);
  const durationInDays = 5;
  const maxAmountRequestLoanTerms = toDecimals(100, tokenInfo.decimals);
  const amountTakeOutValue = 50
  const amountTakeOut = toDecimals(amountTakeOutValue, tokenInfo.decimals);
  let initialOraclePrice;
  let collateralAmountDepositCollateral;
  if (collTokenName.toLowerCase() === "eth") {
    initialOraclePrice = "0.00295835";
  }
  if (collTokenName.toLowerCase() === "link") {
    initialOraclePrice = "0.100704";
  }
  const interestRate = 423
  const interestOwed = new BN(amountTakeOutValue)
    .multipliedBy(interestRate)
    .div(10000)
    .multipliedBy(durationInDays)
    .multipliedBy(ONE_DAY)
    .div(ONE_YEAR)
  collateralAmountDepositCollateral = new BN(amountTakeOutValue)
    .plus(interestOwed)
    .multipliedBy(initialOraclePrice)
    .multipliedBy(new BN(collateralRatio).div(10000))
    .toString()
  collateralAmountDepositCollateral = toDecimals(collateralAmountDepositCollateral, collateralTokenInfo.decimals).toFixed(0);

  const signers = await accounts.getAllAt(12, 13);
  const borrowerTxConfig = await accounts.getTxConfigAt(1);
  const lenderTxConfig = await accounts.getTxConfigAt(0);
  const borrower = borrowerTxConfig.from
  const balanceBefore = (await token.balanceOf(borrower)).toString()

  const loan = await helperActions.takeOutNewLoan(
    allContracts,
    {testContext},
    {
      borrowerTxConfig,
      oraclePrice: initialOraclePrice,
      lenderTxConfig,
      depositFundsAmount,
      maxAmountRequestLoanTerms,
      amountTakeOut,
      collateralAmountDepositCollateral,
      collateralRatio,
      interestRate,
      durationInDays,
      signers,
      tokenInfo,
      collateralTokenInfo,
    }
  )

  await loansAssertions.assertLoanValues(
    allContracts,
    { testContext },
    {
      id: loan.id,
      status: loanStatus.Active,
      hasEscrow: false
    }
  )

  await tokensAssertions.balanceIs(
    allContracts,
    { testContext },
    {
      address: borrower,
      expectedBalance: new BN(balanceBefore).plus(loan.borrowedAmount.toString()).toString()
    }
  )

  await loansActions.printLoanInfo(
    allContracts,
    { testContext },
    {
      loanId: loan.id,
      collateralTokenInfo,
      tokenInfo,
    }
  );
};
