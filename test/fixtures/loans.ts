import { deployments } from 'hardhat'
import { Signer } from 'ethers'
import { fundedMarket, FundedMarketArgs, FundedMarketReturn } from './markets'
import { mockCRAResponse } from '../../utils/mock-cra-response'
import { ONE_DAY } from '../../utils/consts'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { Loans } from '../../types/typechain'

enum LoanType {
  ZERO_COLLATERAL,
  UNDER_COLLATERALIZED,
  OVER_COLLATERALIZED,
}

export interface MarketWithLoanArgs {
  market?: FundedMarketArgs
  borrower: Signer
  loanType: LoanType
}

export interface MarketWithLoanReturn
  extends FundedMarketReturn,
    BorrowedLoanReturn {}

export interface BorrowedLoanReturn {
  createdLoanId: string
  totalOwed: number
}

export const createMarketWithLoan = (
  args: MarketWithLoanArgs
): Promise<MarketWithLoanReturn> =>
  deployments.createFixture(async (hre) => {
    // Create a fully funded market
    const market = await fundedMarket(args.market)

    // Create a loan with terms, deposit collateral and take it out from the funded market
    const createdLoan = await createAndGetLoan(
      market,
      args.borrower,
      args.loanType,
      hre
    )

    // Return the market state with the created loan ID and total owed
    return {
      ...market,
      ...createdLoan,
    }
  })()

export const createAndGetLoan = async (
  market: FundedMarketReturn,
  borrower: Signer,
  loanType: LoanType,
  hre: HardhatRuntimeEnvironment
): Promise<BorrowedLoanReturn> => {
  // Setup loan amount
  const { ethers } = hre
  const BN = ethers.BigNumber
  const loanAmount = BN.from('1684').mul(BN.from('10').pow('18')).toString()

  // Create a loan and get the loan ID
  const createdLoanId = await createLoan(market, loanType, loanAmount, borrower)
  // Take out loan
  await getLoan(await market.loans, createdLoanId, loanAmount, borrower, hre)
  // Get total owed for loan
  const totalOwed = Number(await market.loans.getTotalOwed(createdLoanId))

  return {
    createdLoanId,
    totalOwed,
  }
}

export const createLoan = async (
  market: FundedMarketReturn,
  loanType: LoanType,
  loanAmount: string,
  borrower: Signer
): Promise<string> => {
  // Set up collateral
  let collateralRatio = 0
  switch (loanType) {
    case LoanType.ZERO_COLLATERAL:
      break
    case LoanType.UNDER_COLLATERALIZED:
      collateralRatio = 5000
      break
    case LoanType.OVER_COLLATERALIZED:
      collateralRatio = 15000
      break
  }

  // Get mock cra request and response
  const craReturn = await mockCRAResponse({
    lendingToken: market.lendTokenSym,
    collateralToken: market.collTokenSym,
    loanAmount: loanAmount,
    loanTermLength: ONE_DAY.toString(),
    collateralRatio: collateralRatio.toString(),
    interestRate: '400',
    borrower: await borrower.getAddress(),
  })

  // Create loan with terms
  await market.loans
    .connect(borrower)
    .createLoanWithTerms(craReturn.request, [craReturn.response], '0')
  const borrowerAddress = await borrower.getAddress()

  // Return ID for created loan
  const allBorrowerLoans = await market.loans.getBorrowerLoans(borrowerAddress)
  return allBorrowerLoans[allBorrowerLoans.length - 1].toString()
}

export const getLoan = async (
  loansContract: Loans,
  createdLoanId: string,
  loanAmount: string,
  borrower: Signer,
  hre: HardhatRuntimeEnvironment
): Promise<void> => {
  const { fastForward } = hre

  // Deposit collateral
  const collateral = (await loansContract.getCollateralInfo(createdLoanId))
    .neededInCollateralTokens
  const borrowerAddress = await borrower.getAddress()
  await loansContract
    .connect(borrower)
    .depositCollateral(borrowerAddress, createdLoanId, collateral, {
      value: collateral,
    })

  // Forward block timestamp
  await fastForward(300)

  // Take out loan as borrower
  await loansContract.connect(borrower).takeOutLoan(createdLoanId, loanAmount)
}