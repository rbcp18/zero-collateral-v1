import chai from 'chai'
import { solidity } from 'ethereum-waffle'
import hre from 'hardhat'

import { getMarkets } from '../../../../config'
import { getPlatformSetting } from '../../../../tasks'
import { Market } from '../../../../types/custom/config-types'
import { ERC20, IERC20, ITellerDiamond } from '../../../../types/typechain'
import { fundedMarket } from '../../../fixtures'
import { LoanType, takeOutLoanWithoutNfts } from '../../../helpers/loans'

chai.should()
chai.use(solidity)

const { getNamedSigner, contracts, evm } = hre

describe.skip('poolTogether Dapp', () => {
  getMarkets(hre.network).forEach(testPoolTogether)

  function testPoolTogether(market: Market): void {
    describe(`${market.lendingToken} lending token`, () => {
      let diamond: ITellerDiamond
      let lendingToken: ERC20
      let poolTicket: IERC20

      before(async () => {
        ({ diamond, lendingToken } = await fundedMarket(hre, {
          assetSym: market.lendingToken,
          amount: 1000000,
        }))
        poolTicket = await contracts.get<IERC20>('IERC20', {
          at: await diamond.getAssetPPoolTicket(lendingToken.address),
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

      describe('deposit, withdrawAll', () => {
        it('Should be able to deposit and then withdraw successfully from poolTogether', async () => {
          const { getHelpers } = await takeOutLoanWithoutNfts(hre, {
            lendToken: market.lendingToken,
            collToken: market.collateralTokens[0],
            loanType: LoanType.UNDER_COLLATERALIZED,
          })
          const { details } = await getHelpers()

          await diamond
            .connect(details.borrower.signer)
            .poolTogetherDepositTicket(
              details.loan.id,
              details.loan.lendingToken,
              details.loan.borrowedAmount
            )

          const escrowAddress = await diamond.getLoanEscrow(details.loan.id)

          let daiBalance = await lendingToken.balanceOf(escrowAddress)
          daiBalance.should.be.eql('0')

          let tokenAddresses: string[]
          tokenAddresses = await diamond.getEscrowTokens(details.loan.id)
          tokenAddresses.should.include(poolTicket.address)

          await diamond
            .connect(details.borrower.signer)
            .poolTogetherWithdrawAll(details.loan.id, lendingToken.address)

          tokenAddresses = await diamond.getEscrowTokens(details.loan.id)
          tokenAddresses.should.not.include(poolTicket.address)

          daiBalance = await lendingToken.balanceOf(escrowAddress)
          daiBalance.should.be.gt('0')
        })

        it.skip('Should not be able to deposit into pooltogether as not the loan borrower', async () => {
          const { getHelpers } = await takeOutLoanWithoutNfts(hre, {
            lendToken: market.lendingToken,
            collToken: market.collateralTokens[0],
            loanType: LoanType.UNDER_COLLATERALIZED,
          })
          const { details } = await getHelpers()

          const rando = await getNamedSigner('lender')
          await diamond
            .connect(rando)
            .poolTogetherDepositTicket(
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
