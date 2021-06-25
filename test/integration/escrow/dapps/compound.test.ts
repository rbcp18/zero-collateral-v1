// import chai from 'chai'
// import { solidity } from 'ethereum-waffle'
// import hre from 'hardhat'

// import { getMarkets } from '../../../../config'
// import { getPlatformSetting } from '../../../../tasks'
// import { Market } from '../../../../types/custom/config-types'
// import { ERC20, ICErc20, ITellerDiamond } from '../../../../types/typechain'
// import { fundedMarket } from '../../../fixtures'
// import { LoanType, takeOut } from '../../../helpers/loans'

// chai.should()
// chai.use(solidity)

// const { getNamedSigner, contracts, evm } = hre

// describe('CompoundDapp', () => {
//   getMarkets(hre.network).forEach(testCompound)

//   function testCompound(market: Market): void {
//     describe(`${market.lendingToken} lending token`, () => {
//       let diamond: ITellerDiamond
//       let lendingToken: ERC20
//       let cToken: ICErc20

//       before(async () => {
//         ;({ diamond, lendingToken } = await fundedMarket({
//           assetSym: market.lendingToken,
//           amount: 100000,
//         }))

//         cToken = await contracts.get<ICErc20>('ICErc20', {
//           at: await diamond.getAssetCToken(lendingToken.address),
//         })
//       })

//       beforeEach(async () => {
//         // Advance time
//         const { value: rateLimit } = await getPlatformSetting(
//           'RequestLoanTermsRateLimit',
//           hre
//         )
//         await evm.advanceTime(rateLimit)
//       })

//       describe('lend, redeemAll', () => {
//         it('Should be able to lend and then redeem successfully from Compound', async () => {
//           const { details } = await takeOut({
//             lendToken: market.lendingToken,
//             collToken: market.collateralTokens[0],
//             loanType: LoanType.UNDER_COLLATERALIZED,
//           })

//           await diamond
//             .connect(details.borrower.signer)
//             .compoundLend(
//               details.loan.id,
//               details.loan.lendingToken,
//               details.loan.borrowedAmount
//             )

//           const escrowAddress = await diamond.getLoanEscrow(details.loan.id)

//           let cDaiBalance = await cToken.balanceOf(escrowAddress)

//           cDaiBalance.eq(0).should.eql(false, '')

//           let tokenAddresses: string[]
//           tokenAddresses = await diamond.getEscrowTokens(details.loan.id)
//           tokenAddresses.should.include(cToken.address)

//           await diamond
//             .connect(details.borrower.signer)
//             .compoundRedeemAll(details.loan.id, lendingToken.address)

//           tokenAddresses = await diamond.getEscrowTokens(details.loan.id)
//           tokenAddresses.should.not.include(cToken.address)

//           cDaiBalance = await cToken.balanceOf(escrowAddress)
//           cDaiBalance.eq(0).should.eql(true, '')
//         })

//         it('Should not be able to lend into Compound as not the loan borrower', async () => {
//           const { details } = await takeOut({
//             lendToken: market.lendingToken,
//             collToken: market.collateralTokens[0],
//             loanType: LoanType.UNDER_COLLATERALIZED,
//           })

//           const rando = await getNamedSigner('lender')
//           await diamond
//             .connect(rando)
//             .compoundLend(
//               details.loan.id,
//               details.loan.lendingToken,
//               details.loan.borrowedAmount
//             )
//             .should.rejectedWith('Teller: dapp not loan borrower')
//         })
//       })
//     })
//   }
// })
