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
      describe.only('stake, unstake, deposit to polygon', () => {
        it('stakes NFTs on behalf of the user', async () => {
          await claimNFT({ account: borrower, merkleIndex: 0 }, hre)
          ownedNFTs = await rootToken
            .getOwnedTokens(borrower)
            .then((arr) => (arr.length > 2 ? arr.slice(0, 2) : arr))
          await rootToken
            .connect(borrowerSigner)
            .setApprovalForAll(diamond.address, true)
          await diamond.connect(borrowerSigner).stakeNFTs(ownedNFTs)
          const stakedNFTs = await diamond.getStakedNFTs(borrower)
          for (let i = 0; i < ownedNFTs.length; i++) {
            expect(ownedNFTs[i]).to.equal(stakedNFTs[i])
          }
        })
        it('unstakes the nfts then "deposits" to polygon', async () => {
          console.log('about to bridge')
          console.log(ownedNFTs)
          await diamond.connect(borrowerSigner).bridgeNFTToPolygon(ownedNFTs)
          const stakedNFTs = await diamond.getStakedNFTs(borrower)
          expect(stakedNFTs.length).to.equal(0)
        })
        it('stakes the NFTs on "polygon"', async () => {
          // encode data
          const depositData = ethers.utils.defaultAbiCoder.encode(
            ['address', 'uint256[]'],
            [borrower, ownedNFTs]
          )
          // stake the nfts
          await childToken
            .connect(deployer)
            .deposit(diamond.address, depositData)
          const stakedNFTs = await diamond
            .connect(borrower)
            .getStakedNFTs(borrower)
          console.log(stakedNFTs)
        })
      })
      describe('unstakes then "deposits" back to ethereum', () => {
        it('unstakes NFTs on polygon', async () => {})
        it('burns the NFTs then "deposits" to ethereum', async () => {})
        it('stakes the NFTs on ethereum', async () => {})
      })
    })
  }
})
