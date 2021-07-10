import rootChainManagerAbi from '@maticnetwork/meta/network/mainnet/v1/artifacts/pos/RootChainManager.json'
import chai, { expect } from 'chai'
import { solidity } from 'ethereum-waffle'
import { BigNumber, Contract, Signer } from 'ethers'
import hre, {
  contracts,
  ethers,
  evm,
  getNamedAccounts,
  getNamedSigner,
} from 'hardhat'

import { getMarkets, getNFT } from '../../config'
import {
  claimNFT,
  getPlatformSetting,
  updatePlatformSetting,
} from '../../tasks'
import { Market } from '../../types/custom/config-types'
import {
  ITellerDiamond,
  PolyTellerNFT,
  RootChainManager,
  TellerNFT,
} from '../../types/typechain'

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
    let ownedNFTs: BigNumber[]
    let rootChainManager: Contract
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
      rootChainManager = new ethers.Contract(
        '0xD4888faB8bd39A663B63161F5eE1Eae31a25B653',
        rootChainManagerAbi.abi,
        borrowerSigner
      )
    })
    describe('Calling mapped contracts', () => {
      it('approves spending of tokens', async () => {
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
        ownedNFTs = await rootToken
          .getOwnedTokens(borrower)
          .then((arr) => (arr.length > 2 ? arr.slice(0, 2) : arr))
        for (let i = 0; i < ownedNFTs.length; i++) {
          await rootToken
            .connect(borrowerSigner)
            .approve(erc721Predicate, ownedNFTs[i])

          const approved = await rootToken
            .connect(borrower)
            .getApproved(ownedNFTs[i])
          expect(erc721Predicate).to.equal(approved)
        }
      })
      it('deposits tokens in the root', async () => {
        const depositData = ethers.utils.defaultAbiCoder.encode(
          ['uint256[]', 'address'],
          [ownedNFTs, borrower]
        )
        const tellerNFTAddress = '0x2ceB85a2402C94305526ab108e7597a102D6C175'
        await rootChainManager
          .connect(borrowerSigner)
          .depositFor(borrower, tellerNFTAddress, depositData)
      })
    })
    describe.only('Mock tests', () => {
      it('stakes NFTs on behalf of the user', async () => {
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
        await claimNFT({ account: borrower, merkleIndex: 0 }, hre)
        ownedNFTs = await rootToken
          .getOwnedTokens(borrower)
          .then((arr) => (arr.length > 2 ? arr.slice(0, 2) : arr))
        await rootToken
          .connect(borrowerSigner)
          .setApprovalForAll(diamond.address, true)
        await diamond.connect(borrowerSigner).stakeNFTs(ownedNFTs)
        const stakedNFTs = await diamond.getStakedNFTs(borrower)
        expect(stakedNFTs).to.equal(ownedNFTs)
      })
      it('unstakes NFTs before "depositing" to polygon', async () => {})
    })
  }
})
