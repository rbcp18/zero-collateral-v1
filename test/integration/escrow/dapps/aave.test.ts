import chai from 'chai'
import { solidity } from 'ethereum-waffle'
import hre from 'hardhat'

import { getMarkets } from '../../../../config'
import { getPlatformSetting } from '../../../../tasks'
import { Market } from '../../../../types/custom/config-types'
import { ERC20, IAToken, ITellerDiamond } from '../../../../types/typechain'
import { fundedMarket } from '../../../fixtures'
import { LoanType, takeOutLoanWithoutNfts } from '../../../helpers/loans'

chai.should()
chai.use(solidity)

const { getNamedSigner, contracts, evm } = hre

describe.skip('AaveDapp', () => {
  getMarkets(hre.network).forEach(testAave)

  function testAave(market: Market): void {
    describe(`${market.lendingToken} lending token`, () => {
      let diamond: ITellerDiamond
      let lendingToken: ERC20
      let aToken: IAToken

      before(async () => {
        ({ diamond, lendingToken } = await fundedMarket(hre, {
          assetSym: market.lendingToken,
          amount: 100000,
        }))

        aToken = await contracts.get<IAToken>('IAToken', {
          at: await diamond.getAssetAToken(lendingToken.address),
        })
      })

      beforeEach(async () => {
        // Advance time
        const { value: rateLimit } = await getPlatformSetting(
          'RequestLoanTermsRateLimit',
          hre
        )
        await evm.advanceTime(rateLimit)
      })

      describe('lend, redeemAll', () => {
        it('Should be able to lend and then redeem successfully from Aave', async () => {
          const { getHelpers } = await takeOutLoanWithoutNfts(hre, {
            lendToken: market.lendingToken,
            collToken: market.collateralTokens[0],
            loanType: LoanType.UNDER_COLLATERALIZED,
          })
          const { details } = await getHelpers()

          await diamond
            .connect(details.borrower.signer)
            .aaveDeposit(
              details.loan.id,
              details.loan.lendingToken,
              details.loan.borrowedAmount
            )

          const escrowAddress = await diamond.getLoanEscrow(details.loan.id)

          let aDaiBalance = await aToken.balanceOf(escrowAddress)

          aDaiBalance.eq(0).should.eql(false, '')

          let tokenAddresses: string[]
          tokenAddresses = await diamond.getEscrowTokens(details.loan.id)
          tokenAddresses.should.include(aToken.address)

          await diamond
            .connect(details.borrower.signer)
            .aaveWithdrawAll(details.loan.id, lendingToken.address)

          tokenAddresses = await diamond.getEscrowTokens(details.loan.id)
          tokenAddresses.should.not.include(aToken.address)

          aDaiBalance = await aToken.balanceOf(escrowAddress)
          aDaiBalance.eq(0).should.eql(true, '')
        })

        it.skip('Should not be able to lend into Aave as not the loan borrower', async () => {
          const { getHelpers } = await takeOutLoanWithoutNfts(hre, {
            lendToken: market.lendingToken,
            collToken: market.collateralTokens[0],
            loanType: LoanType.UNDER_COLLATERALIZED,
          })
          const { details } = await getHelpers()

          const rando = await getNamedSigner('lender')
          await diamond
            .connect(rando)
            .aaveDeposit(
              details.loan.id,
              details.loan.lendingToken,
              details.loan.borrowedAmount
            )
            .should.rejectedWith('Teller: dapp not loan borrower')
        })
      })
    })
  }
})
