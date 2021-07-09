import chai, { expect } from 'chai'
import { solidity } from 'ethereum-waffle'
import { Signer } from 'ethers'
import hre, { contracts, evm,getNamedAccounts, getNamedSigner } from 'hardhat'

import { getMarkets, getNFT } from '../../config'
import {
  claimNFT,
  getPlatformSetting,
  updatePlatformSetting,
} from '../../tasks'
import { Market } from '../../types/custom/config-types'
import { ITellerDiamond, PolyTellerNFT, TellerNFT } from '../../types/typechain'

chai.should()
chai.use(solidity)

describe.only('Bridging Assets to Polygon', () => {
  getMarkets(hre.network).forEach(testBridging)
  function testBridging(markets: Market): void {
    let deployer: Signer
    let diamond: ITellerDiamond
    let rootToken: TellerNFT
    let childToken: PolyTellerNFT
    let borrower: string
    let borrowerSigner: Signer

    before(async () => {
      await hre.deployments.fixture(['market'], {
        keepExistingDeployments: true,
      })
      rootToken = await contracts.get('TellerNFT')
      childToken = await contracts.get('PolyTellerNFT')
      diamond = await contracts.get('TellerDiamond')
      deployer = await getNamedSigner('deployer')
      borrower = '0x86a41524cb61edd8b115a72ad9735f8068996688'
      borrowerSigner = (await hre.evm.impersonate(borrower)).signer
    })
    describe('Mainnet', () => {
      it('approves spending of tokens', async () => {
        const helpers: any = null
        before(async () => {
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
        })
        const erc721Predicate = '0x74D83801586E9D3C4dc45FfCD30B54eA9C88cf9b'
        await claimNFT({ account: borrower, merkleIndex: 0 }, hre)
        const ownedNFTs = await rootToken
          .getOwnedTokens(borrower)
          .then((arr) => (arr.length > 2 ? arr.slice(0, 2) : arr))
        console.log('owned nfts')
        console.log(ownedNFTs)
        for (let i = 0; i < ownedNFTs.length; i++) {
          await rootToken
            .connect(borrowerSigner)
            .approve(erc721Predicate, ownedNFTs[i])
        }
      })
    })
  }
})
