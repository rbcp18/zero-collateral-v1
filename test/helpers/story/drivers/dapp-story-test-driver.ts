import chai, { expect } from 'chai'
import { solidity } from 'ethereum-waffle'
import { BigNumber } from 'ethers'
import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { Test } from 'mocha'

import { ICErc20 } from '../../../../types/typechain'
import { getFunds } from '../../get-funds'
import { TestAction,TestScenario } from '../story-helpers'
import LoanStoryTestDriver from './loan-story-test-driver'
import StoryTestDriver from './story-test-driver'

chai.should()
chai.use(solidity)

/*
We will read state data from the chaindata to determine whether or not each 'action' should pass or fail at the current moment 
Then we will expect that 
*/

export default class DappStoryTestDriver extends StoryTestDriver {
  static generateDomainSpecificTestsForScenario(
    hre: HardhatRuntimeEnvironment,
    scenario: TestScenario,
    parentSuite: Mocha.Suite
  ): Mocha.Suite {
    // let allTests: Array<Test> = []

    const scenarioActions = scenario.actions

    for (const action of scenarioActions) {
      const testsForAction: Test[] =
        DappStoryTestDriver.generateTestsForAction(hre, action, parentSuite)

      //allTests = allTests.concat(testsForAction)

      for (const test of testsForAction) {
        parentSuite.addTest(test)
      }
    }

    return parentSuite
  }

  static generateTestsForAction(
    hre: HardhatRuntimeEnvironment,
    action: TestAction,
    testSuite: Mocha.Suite
  ): Test[] {
    const tests: Test[] = []

    const actionParentType = action.actionParentType
    switch (actionParentType) {
      case 'LEND': {
        DappStoryTestDriver.generateTestsForLend(hre, action, tests)
        break
      }
      case 'SWAP': {
        void DappStoryTestDriver.generateTestsForSwap(hre, action, tests)
        break
      }
    }

    return tests
  }

  static generateTestsForLend(
    hre: HardhatRuntimeEnvironment,
    action: TestAction,
    tests: Test[]
  ): void {
    const { getNamedSigner, contracts } = hre
    const actionType = action.actionType
    switch (actionType) {
      case 'AAVE': {
        const newTest = new Test('AAVE Lend DAPP', (async () => {
          expect(1).to.equal(1)
        }))
        console.log('push new story test ! ')
        tests.push(newTest)
        break
      }
      case 'COMPOUND': {
        const newTest = new Test('COMPOUND Lend DAPP', (async () => {
          const borrower = await getNamedSigner('borrower')
          const loan = await LoanStoryTestDriver.getLoan(hre, borrower)
          const { details, diamond } = loan

          await getFunds({
            to: await borrower.getAddress(),
            tokenSym: await details.lendingToken.symbol(),
            amount: BigNumber.from(details.loan.borrowedAmount).mul(2),
            hre,
          })
          await details.lendingToken
            .connect(borrower)
            .approve(
              diamond.address,
              BigNumber.from(details.loan.borrowedAmount).mul(2)
            )
          const cToken = await contracts.get<ICErc20>('ICErc20', {
            at: await diamond.getAssetCToken(details.lendingToken.address),
          })
          await diamond
            .connect(details.borrower.signer)
            .compoundLend(
              details.loan.id,
              details.loan.lendingToken,
              details.loan.borrowedAmount
            )
          const escrowAddress = await diamond.getLoanEscrow(details.loan.id)
          const cDaiBalance = await cToken.balanceOf(escrowAddress)
          cDaiBalance.eq(0).should.eql(false, '')

          const tokenAddresses = await diamond.getEscrowTokens(details.loan.id)
          tokenAddresses.should.include(cToken.address)
        }))
        console.log('push COMPOUND Lend test ! ')
        tests.push(newTest)
        break
      }
      case 'POOL_TOGETHER': {
        const newTest = new Test('POOL_TOGETHER Lend DAPP', (async () => {
          expect(1).to.equal(1)
        }))
        console.log('push new story test ! ')
        tests.push(newTest)
        break
      }
      default:
        break
    }
  }

  static async generateTestsForSwap(
    hre: HardhatRuntimeEnvironment,
    action: TestAction,
    tests: Test[]
  ): Promise<void> {
    const { getNamedSigner, tokens } = hre
    const dapp = action.actionType
    switch (dapp) {
      case 'UNISWAP': {
        const newTest = new Test('UNISWAP Swap DAPP', (async () => {
          // if (args.rewindStateTo) LoanSnapshots[args.rewindStateTo]()
          const borrower = await getNamedSigner('borrower')
          const loan = await LoanStoryTestDriver.getLoan(hre, borrower)
          const { details, diamond } = loan
          const link = await tokens.get('LINK')
          const escrowAddress = await diamond.getLoanEscrow(details.loan.id)

          const lendingBalBefore = await details.lendingToken.balanceOf(
            escrowAddress
          )
          console.log({ lendingBalBefore })
          lendingBalBefore
            .gt(0)
            .should.eql(true, 'Loan escrow should have a lending token balance')

          const swapBalBefore = await link.balanceOf(escrowAddress)
          swapBalBefore
            .eq(0)
            .should.eql(
              true,
              'Loan escrow should not have a token balance before swap'
            )

          await diamond
            .connect(details.borrower.signer)
            .uniswapSwap(
              details.loan.id,
              [details.lendingToken.address, link.address],
              lendingBalBefore,
              '0'
            )
            .should.emit(diamond, 'UniswapSwapped')

          const swapBalAfter = await link.balanceOf(escrowAddress)
          swapBalAfter
            .gt(0)
            .should.eql(true, 'Swap token balance not positive after swap')

          const lendingBalAfter = await details.lendingToken.balanceOf(
            escrowAddress
          )
          lendingBalAfter
            .eq(0)
            .should.eql(
              true,
              'Loan escrow has lending token balance after swapping full amount'
            )
        }))
        console.log('push UNISWAP Swap test ! ')
        tests.push(newTest)
        break
      }
      case 'SUSHISWAP': {
        const newTest = new Test('SUSHISWAP Swap DAPP', (async () => {
          expect(1).to.equal(1)
        }))
        console.log('push new story test ! ')
        tests.push(newTest)
        break
      }
      default:
        break
    }
  }
}
