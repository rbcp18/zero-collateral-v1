import chai, { expect } from 'chai'
import { solidity } from 'ethereum-waffle'
import { Signer } from 'ethers'
import { defaultMaxListeners } from 'events'
import hre from 'hardhat'
import { BUILD_INFO_FORMAT_VERSION } from 'hardhat/internal/constants'

import { getMarkets, getNFT } from '../../config'
import {
  claimNFT,
  getPlatformSetting,
  updatePlatformSetting,
} from '../../tasks'
import { getLoanMerkleTree, setLoanMerkle } from '../../tasks'
import { Market } from '../../types/custom/config-types'
import { ITellerDiamond, TellerNFT } from '../../types/typechain'
import { CacheType, LoanStatus } from '../../utils/consts'
import { fundedMarket } from '../fixtures'
import { fundLender, getFunds } from '../helpers/get-funds'
import {
  createLoan,
  LoanType,
  takeOutLoanWithNfts,
  takeOutLoanWithoutNfts,
} from '../helpers/loans'

chai.should()
chai.use(solidity)

const { getNamedSigner, contracts, tokens, ethers, evm, toBN } = hre

describe.only('Loans', () => {
  getMarkets(hre.network).forEach(testLoans)

  function testLoans(market: Market): void {
    let deployer: Signer
    let diamond: ITellerDiamond
    let borrower: Signer

    before(async () => {
      await hre.deployments.fixture(['market'], {
        keepExistingDeployments: true,
      })

      diamond = await contracts.get('TellerDiamond')

      deployer = await getNamedSigner('deployer')
    })
    // tests for merged loan functions
    describe('merge create loan', () => {
      var helpers: any = null
      before(async () => {
        // update percentage submission percentage value to 0 for this test
        const percentageSubmission = {
          name: 'RequiredSubmissionsPercentage',
          value: 0,
        }
        await updatePlatformSetting(percentageSubmission, hre)

        // Advance time
        const { value: rateLimit } = await getPlatformSetting(
          'RequestLoanTermsRateLimit',
          hre
        )
        await evm.advanceTime(rateLimit)

        // get helpers variables after function returns our transaction and
        // helper variables
        const { getHelpers } = await takeOutLoanWithoutNfts({
          lendToken: market.lendingToken,
          collToken: market.collateralTokens[0],
          loanType: LoanType.UNDER_COLLATERALIZED,
          collAmount: 100,
        })
        helpers = await getHelpers()

        // borrower data from our helpers
        borrower = helpers.details.borrower.signer
      })
      it('should create a loan', () => {
        // check if loan exists
        expect(helpers.details.loan).to.exist
      })
      it('should have collateral deposited', async () => {
        // get collateral
        const { collateral } = helpers
        const amount = await collateral.current()

        // check if collateral is > 0
        amount.gt(0).should.eq(true, 'Loan must have collateral')
      })
      it('should be taken out', () => {
        // get loanStatus from helpers and check if it's equal to 2, which means
        // it's active and taken out
        const loanStatus = helpers.details.loan.status
        expect(loanStatus).to.equal(2)
      })
      describe('other loan tests', () => {
        it('should not be able to take out a loan when loan facet is paused', async () => {
          const LOANS_ID = hre.ethers.utils.id('LOANS')

          // Pause lending
          await diamond
            .connect(deployer)
            .pause(LOANS_ID, true)
            .should.emit(diamond, 'Paused')
            .withArgs(LOANS_ID, await deployer.getAddress())

          // trying to run the function will revert with the same error message
          // written in our PausableMods file
          const { tx } = await takeOutLoanWithoutNfts({
            lendToken: market.lendingToken,
            collToken: market.collateralTokens[0],
            loanType: LoanType.UNDER_COLLATERALIZED,
          })
          await tx.should.be.revertedWith('Pausable: paused')

          // Unpause lending
          await diamond
            .connect(deployer)
            .pause(LOANS_ID, false)
            .should.emit(diamond, 'UnPaused')
            .withArgs(LOANS_ID, await deployer.getAddress())
        })
        // it('should not be able to take out a loan without enough collateral', async () => {
        //   const { tx } = await takeOutLoanWithoutNfts({
        //     lendToken: market.lendingToken,
        //     collToken: market.collateralTokens[0],
        //     loanType: LoanType.OVER_COLLATERALIZED,
        //     collAmount: 1
        //   })

        //   // Try to take out loan which should fail
        //   await tx.should.be.revertedWith('Teller: more collateral required')
        // })
      })
    })
    describe('merge create loan w/ nfts', () => {
      var helpers: any
      before(async () => {
        // Advance time
        const { value: rateLimit } = await getPlatformSetting(
          'RequestLoanTermsRateLimit',
          hre
        )

        // get helpers
        const { getHelpers } = await takeOutLoanWithNfts({
          lendToken: market.lendingToken,
        })
        helpers = await getHelpers()

        await evm.advanceTime(rateLimit)
      })
      it('creates a loan', async () => {
        console.log(helpers.details.loan)
        expect(helpers.details.loan).to.exist
      })
      it('should be an active loan', () => {
        // get loanStatus from helpers and check if it's equal to 2, which means it's active
        const loanStatus = helpers.details.loan.status
        expect(loanStatus).to.equal(2)
      })
    })
  }
})
