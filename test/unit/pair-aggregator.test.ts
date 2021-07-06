import chai from 'chai'
import chaiAsPromised from 'chai-as-promised'
import { Signer } from 'ethers'
import hre from 'hardhat'

import { getChainlink, getTokens } from '../../config'
import { Address } from '../../types/custom/config-types'
import { ITellerDiamond } from '../../types/typechain'
import { NULL_ADDRESS } from '../../utils/consts'
import { RUN_EXISTING } from '../helpers/env-helpers'

chai.should()
chai.use(chaiAsPromised)

const { contracts, tokens, deployments, getNamedSigner, toBN } = hre

describe.skip('PriceAggregator', () => {
  let diamond: ITellerDiamond
  let deployer: Signer

  const chainlink = getChainlink(hre.network)
  const tokenAddresses = getTokens(hre.network)
  const pairs = Object.values(chainlink)

  const getTokenAddress = (sym: string): Address => tokenAddresses.all[sym]

  before(async () => {
    await deployments.fixture('protocol')

    diamond = await contracts.get<ITellerDiamond>('TellerDiamond')
    deployer = await getNamedSigner('deployer')
  })

  describe.skip('addChainlinkAggregator', () => {
    it('Should not be able to add a Chainlink aggregator as not an admin', async () => {
      // Sender address
      const lender = await getNamedSigner('lender')

      await diamond
        .connect(lender)
        .addChainlinkAggregator(
          getTokenAddress(pairs[0].baseTokenName),
          getTokenAddress(pairs[0].quoteTokenName),
          pairs[0].address
        )
        .should.be.rejectedWith('AccessControl: not authorized')
    })

    for (const pair of pairs) {
      it(`Should be able add Chainlink aggregators for ${pair.baseTokenName}/${pair.quoteTokenName} an admin`, async () => {
        const srcTokenAddress = getTokenAddress(pair.baseTokenName)
        const dstTokenAddress = getTokenAddress(pair.quoteTokenName)

        // Add aggregator
        await diamond
          .connect(deployer)
          .addChainlinkAggregator(
            srcTokenAddress,
            dstTokenAddress,
            pair.address
          )

        // Check if aggregator was successfully added
        const aggregatorResponse = await diamond.getChainlinkAggregatorFor(
          srcTokenAddress,
          dstTokenAddress
        )

        const tokenSupportResponse = await diamond.isChainlinkTokenSupported(
          srcTokenAddress
        )

        aggregatorResponse.agg.should.be.equals(
          pair.address,
          'Chainlink pair Aggregator was not stored'
        )
        tokenSupportResponse.should.eql(
          true,
          'Chainlink token not supported after pair added'
        )
      })
    }
  })

  describe('getPriceFor', () => {
    for (const pair of pairs) {
      it(`Should be able get the latest price for ${pair.baseTokenName}/${pair.quoteTokenName}`, async () => {
        const answer = await diamond.getPriceFor(
          getTokenAddress(pair.baseTokenName),
          getTokenAddress(pair.quoteTokenName)
        )

        answer.gt(0).should.eql(true, 'Chainlink pair zero price')
      })
    }
  })

  describe('getValueFor', () => {
    for (const pair of pairs) {
      it(`Should be able get the latest price for ${pair.baseTokenName}/${pair.quoteTokenName}`, async () => {
        const answer = await diamond.getValueFor(
          getTokenAddress(pair.baseTokenName),
          getTokenAddress(pair.quoteTokenName),
          await tokens
            .get(pair.baseTokenName)
            .then(async (t) => toBN(1, await t.decimals()))
        )

        answer.gt(0).should.eql(true, 'Chainlink pair zero value')
      })
    }
  })

  describe('removeChainlinkAggregator', () => {
    it('Should not be able to remove an aggregator as not an admin', async () => {
      // Sender address
      const lender = await getNamedSigner('lender')

      await diamond
        .connect(lender)
        .removeChainlinkAggregator(
          getTokenAddress(pairs[0].baseTokenName),
          getTokenAddress(pairs[0].quoteTokenName)
        )
        .should.be.rejectedWith('AccessControl: not authorized')
    })

    for (const pair of pairs) {
      it(`Should be able remove the aggregator for ${pair.baseTokenName}/${pair.quoteTokenName} as an admin`, async () => {
        const srcTokenAddress = getTokenAddress(pair.baseTokenName)
        const dstTokenAddress = getTokenAddress(pair.quoteTokenName)

        // Remove aggregator
        await diamond
          .connect(deployer)
          .removeChainlinkAggregator(srcTokenAddress, dstTokenAddress)

        // Check if aggregator was successfully removed
        const { agg } = await diamond.getChainlinkAggregatorFor(
          srcTokenAddress,
          dstTokenAddress
        )

        agg.should.be.equal(NULL_ADDRESS, 'Chainlink Aggregator not removed')
      })
    }

    const tokenAddresses = pairs.reduce(
      (set, { baseTokenName, quoteTokenName }) => {
        set.add(getTokenAddress(baseTokenName))
        set.add(getTokenAddress(quoteTokenName))
        return set
      },
      new Set<string>()
    )

    for (const tokenAddress of tokenAddresses) {
      it(`should not support any tokens after all aggregators being removed`, async () => {
        const tokenSupportResponse = await diamond.isChainlinkTokenSupported(
          tokenAddress
        )

        tokenSupportResponse.should.eql(
          false,
          'Chainlink token still supported'
        )
      })
    }
  })
})
