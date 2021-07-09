import { isBytesLike } from '@ethersproject/bytes'
import { toUtf8Bytes } from '@ethersproject/strings'
import { time, timeStamp } from 'console'
import { createSign } from 'crypto'
import {
  BigNumber,
  BigNumberish,
  ContractTransaction,
  PayableOverrides,
  Signer,
} from 'ethers'
import hre from 'hardhat'
import moment from 'moment'
import { ConsoleLogger } from 'ts-generator/dist/logger'

// zkcra imports
import {
  initialize,
  ZoKratesProvider,
  CompilationArtifacts,
  ComputationResult,
  Proof,
  SetupKeypair,
  //@ts-ignore
} from 'zokrates-js/node'
import fetch from 'node-fetch'
// import zkcra from '../fixtures/zkcra.json'
// const out = 'https://ipfs.io/ipfs/QmeWAsv22oPBK2Rk8Jdj49CGjpz8fMivSzozmvARWGVqY8?filename=out'
const zkcraJson = `https://ipfs.io/ipfs/QmPRctNbW2q1TdrJAp2E1CkafJuCEzDKYtrqpYoHDkpXuR?filename=zkcra.json`
import scores from '../fixtures/zk-scores'

// teller files
import { getNFT } from '../../config'
import { claimNFT, getPrice } from '../../tasks'
import { ERC20, ITellerDiamond, TellerNFT } from '../../types/typechain'
import { mockCRAResponse } from './mock-cra-response'

import { readFileSync, writeFile, writeFileSync } from 'fs'
import { join } from 'path'
import { JsonRpcBatchProvider } from '@ethersproject/providers'
const {
  getNamedSigner,
  getNamedAccounts,
  contracts,
  tokens,
  ethers,
  toBN,
  evm,
} = hre

export enum LoanType {
  ZERO_COLLATERAL,
  UNDER_COLLATERALIZED,
  OVER_COLLATERALIZED,
}
export interface LoanHelpersReturn {
  diamond: ITellerDiamond
  details: PromiseReturnType<typeof loanDetails>
  repay: (amount: BigNumberish, from?: Signer) => ReturnType<typeof repayLoan>
  escrowRepay: (
    amount: BigNumberish,
    from?: Signer
  ) => ReturnType<typeof escrowRepayLoan>
  collateral: {
    needed: () => ReturnType<typeof collateralNeeded>
    current: () => ReturnType<typeof collateralCurrent>
    deposit: (
      amount: BigNumberish,
      from?: Signer
    ) => ReturnType<typeof depositCollateral>
    withdraw: (
      amount: BigNumberish,
      from?: Signer
    ) => ReturnType<typeof withdrawCollateral>
  }
}

export const loanHelpers = async (
  loanID: string
): Promise<LoanHelpersReturn> => {
  const diamond = await contracts.get<ITellerDiamond>('TellerDiamond')
  const details = await loanDetails(loanID)
  return {
    diamond,
    details,
    repay: (amount: BigNumberish, from?: Signer) =>
      repayLoan({ diamond, details, amount, from }),
    escrowRepay: (amount: BigNumberish, from?: Signer) =>
      escrowRepayLoan({ diamond, details, amount, from }),
    collateral: {
      needed: () => collateralNeeded({ diamond, details }),
      current: () => collateralCurrent({ diamond, details }),
      deposit: (amount: BigNumberish, from?: Signer) =>
        depositCollateral({ diamond, details, amount, from }),
      withdraw: (amount: BigNumberish, from?: Signer) =>
        withdrawCollateral({ diamond, details, amount, from }),
    },
  }
}
interface CreateLoanWithNftArgs {
  lendToken: string | ERC20
  borrower?: string
  deployer?: string
  amount?: BigNumberish
  amountBN?: BigNumberish
  duration?: moment.Duration
}
interface CreateLoanArgs {
  lendToken: string | ERC20
  collToken: string | ERC20
  loanType: LoanType
  amount?: BigNumberish
  amountBN?: BigNumberish
  borrower?: string
  duration?: moment.Duration
  nft?: boolean
}

interface ZKCRAConfigArgs {
  numberOfProviders: any
}

interface CreateLoanWithZKCRA {
  proof: Proof
  computation?: ComputationResult
  providerAddresses?: any
}

interface ZKCRAConfigReturn {
  numberOfSignaturesRequired: any
  providerAddresses: string[]
}
export interface CreateLoanReturn {
  tx: Promise<ContractTransaction>
  getHelpers: () => Promise<LoanHelpersReturn>
}
export const createLoan = async (
  args: CreateLoanArgs
): Promise<CreateLoanReturn> => {
  const {
    lendToken,
    collToken,
    loanType,
    amount = 100,
    amountBN,
    duration = moment.duration(1, 'day'),
  } = args
  const diamond = await contracts.get<ITellerDiamond>('TellerDiamond')
  const lendingToken =
    typeof lendToken === 'string' ? await tokens.get(lendToken) : lendToken
  const collateralToken =
    typeof collToken === 'string' ? await tokens.get(collToken) : collToken
  const borrower = args.borrower ?? (await getNamedAccounts()).borrower
  const loanAmount = amountBN ?? toBN(amount, await lendingToken.decimals())
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
    lendingToken: lendingToken.address,
    loanAmount,
    loanTermLength: duration.asSeconds(),
    collateralRatio: collateralRatio,
    interestRate: '400',
    borrower,
  })
  // Create loan with terms
  const tx = diamond
    .connect(ethers.provider.getSigner(borrower))
    .createLoanWithTerms(
      craReturn.request,
      [craReturn.responses],
      collateralToken.address,
      '0'
    )
  return {
    tx,
    getHelpers: async (): Promise<LoanHelpersReturn> => {
      await tx
      const allBorrowerLoans = await diamond.getBorrowerLoans(borrower)
      const loanID = allBorrowerLoans[allBorrowerLoans.length - 1].toString()
      return await loanHelpers(loanID)
    },
  }
}

/**
 * @description: function helper that sets the collateral token and ratio and creates a mock CRA
 * response to plug into the newly merged create loan function that:
 *  - sets the terms
 *  - deposits collateral
 *  - takes out the loan
 *
 * @param args: CreateLoanArgs parameters to create the loan
 * @returns: Promise<CreateLoanReturn> helper variables to help run our tests
 */
export const takeOutLoanWithoutNfts = async (
  args: CreateLoanArgs
): Promise<CreateLoanReturn> => {
  const {
    lendToken,
    collToken,
    loanType,
    amount = 100,
    amountBN,
    duration = moment.duration(1, 'day'),
  } = args

  // define diamond contract
  const diamond = await contracts.get<ITellerDiamond>('TellerDiamond')

  // lending token
  const lendingToken =
    typeof lendToken === 'string' ? await tokens.get(lendToken) : lendToken

  // collateral token
  const collateralToken =
    typeof collToken === 'string' ? await tokens.get(collToken) : collToken

  // set borrower and loan amount
  const borrower = args.borrower ?? (await getNamedAccounts()).borrower
  const loanAmount = amountBN ?? toBN(amount, await lendingToken.decimals())

  // depending on the loan type, we set a different collateral ratio. 10000 = 100%
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

  // create our mock CRA response
  const craReturn = await mockCRAResponse({
    lendingToken: lendingToken.address,
    loanAmount,
    loanTermLength: duration.asSeconds(),
    collateralRatio: collateralRatio,
    interestRate: '400',
    borrower,
  })

  const { value: collValue } = await getPrice(
    {
      src: await lendingToken.symbol(),
      dst: await collateralToken.symbol(),
      amount: hre.fromBN(loanAmount, await lendingToken.decimals()),
    },
    hre
  )
  const collAmount = hre.toBN(collValue, await collateralToken.decimals())

  // call the takeOutLoan function from the diamond
  const tx = diamond
    .connect(ethers.provider.getSigner(borrower))
    .takeOutLoan(
      { request: craReturn.request, responses: craReturn.responses },
      collateralToken.address,
      collAmount,
      { value: collAmount.toString() }
    )

  // return our transaction and our helper variable
  return {
    tx,
    getHelpers: async (): Promise<LoanHelpersReturn> => {
      await tx
      const allBorrowerLoans = await diamond.getBorrowerLoans(borrower)
      const loanID = allBorrowerLoans[allBorrowerLoans.length - 1].toString()
      return await loanHelpers(loanID)
    },
  }
}

/**
 * @description: It creates, signs, apply with NFTs and takes out a loan in one function
 * @param args: Arguments we specify to create our Loan by depositing NFT
 * @returns Promise<CreateLoanReturn> that gives us data to help run our tests
 */
export const takeOutLoanWithNfts = async (
  args: CreateLoanWithNftArgs
): Promise<CreateLoanReturn> => {
  const { lendToken, amount = 100, duration = moment.duration(1, 'day') } = args

  // diamond contract
  const diamond = await contracts.get<ITellerDiamond>('TellerDiamond')

  // lending token
  const lendingToken =
    typeof lendToken === 'string' ? await tokens.get(lendToken) : lendToken

  // amount in loan
  const loanAmount = toBN(amount, await lendingToken.decimals())

  // get the borrower, deployer and borrower's signer
  const deployer = await getNamedSigner('deployer')
  const borrower = '0x86a41524cb61edd8b115a72ad9735f8068996688'
  const { signer: borrowerSigner } = await hre.evm.impersonate(borrower)

  // Claim user's NFT as borrower
  await claimNFT({ account: borrower, merkleIndex: 0 }, hre)

  // Get the sum of loan amount to take out
  const nft = await contracts.get<TellerNFT>('TellerNFT')

  // get all the borrower's NFTs
  const ownedNFTs = await nft
    .getOwnedTokens(borrower)
    .then((arr) => (arr.length > 2 ? arr.slice(0, 2) : arr))

  // Set NFT approval
  await nft.connect(borrowerSigner).setApprovalForAll(diamond.address, true)

  // Stake NFTs by transferring from the msg.sender (borrower) to the diamond
  await diamond.connect(borrowerSigner).stakeNFTs(ownedNFTs)

  // Create mockCRAResponse
  const craReturn = await mockCRAResponse({
    lendingToken: lendingToken.address,
    loanAmount,
    loanTermLength: duration.asSeconds(),
    collateralRatio: 0,
    interestRate: '400',
    borrower,
  })

  // plug it in the takeOutLoanWithNfts function along with the proofs to apply to the loan!
  const tx = diamond
    .connect(borrowerSigner)
    .takeOutLoanWithNFTs(
      { request: craReturn.request, responses: craReturn.responses },
      ownedNFTs
    )

  // return our transaction and our helper variables
  return {
    tx,
    getHelpers: async (): Promise<LoanHelpersReturn> => {
      await tx
      const allBorrowerLoans = await diamond.getBorrowerLoans(borrower)
      const loanID = allBorrowerLoans[allBorrowerLoans.length - 1].toString()
      return await loanHelpers(loanID)
    },
  }
}

// we fill zkCRAConfigInfo before we sign
export const fillZKCRAConfigInfo = async (
  args: ZKCRAConfigArgs
): Promise<ZKCRAConfigReturn> => {
  const diamond = await contracts.get<ITellerDiamond>('TellerDiamond')

  // get signers (providers)
  const { craSigner } = await getNamedAccounts()

  const deployer = await getNamedSigner('deployer')
  const providerAddresses_ = []

  // create random provider
  for (let i = 0; i < args.numberOfProviders; i++) {
    await diamond.connect(deployer).createProvider()
    const providerAddress = await diamond
      .connect(deployer)
      .providers(i.toString())
    providerAddresses_.push(providerAddress)
    const provider = await contracts.get('DataProvider', {
      at: providerAddress,
    })
    console.log('about to set signer #' + i.toString())
    await provider.connect(deployer).functions.setSigner(craSigner, true)
  }

  // getting tellerMarketHandler contract
  const marketHandlerAddress = '0x2858023076c86347CDd7DEa4F38aa215cbbCa91b'
  const tellerMarketHandler = await contracts.get('MarketHandler', {
    at: marketHandlerAddress,
  })

  await tellerMarketHandler
    .connect(deployer)
    .functions.addProviders(providerAddresses_)

  // number of signatures required
  const numberOfSignaturesRequired_ = await tellerMarketHandler
    .connect(deployer)
    .numberOfSignaturesRequired()

  return {
    numberOfSignaturesRequired: numberOfSignaturesRequired_,
    providerAddresses: providerAddresses_,
  }
}

export const outputCraValues = async (
  goodScore: boolean
): Promise<CreateLoanWithZKCRA> => {
  // local variables
  let zokratesProvider: ZoKratesProvider
  let compilationArtifacts: CompilationArtifacts
  let keyPair: SetupKeypair
  let computation: ComputationResult
  let proof: Proof
  // set provider after initialization
  const provider: ZoKratesProvider = await initialize()
  console.log('provider initialized')
  // zok file to compile
  const source = `import "hashes/sha256/256bitPadded.zok" as sha256
    def main(private u32[3][8] data, public field identifier) -> (u32, u32[3][8]):
      u32[3][8] commitments = data
      u32 MARKET_SCORE = 0
      u32 MASK = 0x0000000a

      for u32 i in 0..3 do
          MARKET_SCORE = MARKET_SCORE + data[i][0] & MASK
          commitments[i] = sha256(data[i])
      endfor

      return MARKET_SCORE,commitments`
  // const uint8Array = new Uint8Array(JSON.parse(JSON.stringify(zkcra)).program)
  // console.log('fetching zkcra json')
  // let zkcra: any
  // try {
  //   zkcra = await fetch(zkcraJson)
  // } catch (err) {
  //   console.log('error found: ' + err)
  // }
  // console.log('fetched')
  // const response = await zkcra.json()
  // console.log(response)
  // const uint8Array = new Uint8Array(response.program.data)
  // const abi = response.abi
  // const compArtifact = { program: uint8Array, abi: abi }
  // console.log(compArtifact)

  // compile into circuit
  console.log('about to compile source')
  compilationArtifacts = provider.compile(source)
  console.log('compiled source')
  // const programArray = compilationArtifacts.program
  // const programBuffer = programArray.buffer
  // const objectToAdd = {
  //   program: Buffer.from(programBuffer),
  //   abi: compilationArtifacts.abi,
  // }
  // // console.log(JSON.stringify(objectToAdd))
  // // writeFileSync(
  // //   join(__dirname, '../fixtures/zkcra.json'),
  // //   JSON.stringify(objectToAdd),
  // //   { encoding: 'utf-8' }
  // // )

  // generate keypair
  // keyPair = provider.setup(compilationArtifacts.program)
  // console.log('got keypair')

  // get borrower nonce and identifier
  const diamond = await contracts.get<ITellerDiamond>('TellerDiamond')
  const borrower = (await getNamedAccounts()).borrower
  const { length: nonce } = await diamond.getBorrowerLoans(borrower)
  const identifier = BigNumber.from(borrower).xor(nonce)

  // sample data. first element of each array element is the value (Score).
  // next 7 elements are the secrets

  // get computation
  if (goodScore) {
    computation = provider.computeWitness(compilationArtifacts, [
      scores.good,
      identifier.toString(),
    ])
  } else {
    computation = provider.computeWitness(compilationArtifacts, [
      scores.bad,
      identifier.toString(),
    ])
  }
  console.log('witness computed')

  // compute proof
  const provingKey = new Uint8Array(
    readFileSync(
      join(__dirname, '../../contracts/market/cra/proving.key')
    ).buffer
  )
  proof = provider.generateProof(
    compilationArtifacts.program,
    computation.witness,
    provingKey
  )
  console.log('proof generated')
  return {
    computation: computation,
    proof: proof,
  }
}
// take out function with zkcra implemented
export const borrowWithZKCRA = async (
  args: CreateLoanWithZKCRA
): Promise<CreateLoanReturn> => {
  // get proof and witness from args
  const { proof, computation, providerAddresses } = args

  const diamond = await contracts.get<ITellerDiamond>('TellerDiamond')

  // cutting the proof inputs and concatenating them into our input variables
  const firstInput =
    '0x' +
    proof.inputs
      .slice(2, 10)
      .map((input: string) => input.substr(2).substr(56))
      .join('')

  const secondInput =
    '0x' +
    proof.inputs
      .slice(10, 18)
      .map((input: string) => input.substr(2).substr(56))
      .join('')
  console.log('second input made')
  const thirdInput =
    '0x' +
    proof.inputs
      .slice(18, 26)
      .map((input: string) => input.substr(2).substr(56))
      .join('')

  console.log('Third input made')
  // get the signer
  const signer = await getNamedSigner('craSigner')
  // get the time stamp
  const timestampOne = moment().unix()
  // create our message

  const messageOne = ethers.BigNumber.from(firstInput)
    .xor(timestampOne)
    .toHexString()

  // signing first message
  const credentialsSignerOne = await signer.signMessage(
    ethers.utils.arrayify(messageOne)
  )
  // split our signature
  const sigOne = ethers.utils.splitSignature(credentialsSignerOne)

  // construct our signature data to pass onchain
  const signatureDataOne = {
    signature: {
      v: sigOne.v,
      r: sigOne.r,
      s: sigOne.s,
    },
    signedAt: timestampOne,
  }
  // second signature
  const timestampTwo = moment().unix()
  const messageTwo = ethers.BigNumber.from(secondInput)
    .xor(timestampTwo)
    .toHexString()
  const credentialsSignerTwo = await signer.signMessage(
    ethers.utils.arrayify(messageTwo)
  )
  const sigTwo = ethers.utils.splitSignature(credentialsSignerTwo)
  const signatureDataTwo = {
    signature: {
      v: sigTwo.v,
      r: sigTwo.r,
      s: sigTwo.s,
    },
    signedAt: timestampTwo,
  }

  // third signature
  console.log('about to sign third signature')
  const timestampThree = moment().unix()
  const messageThree = ethers.BigNumber.from(thirdInput)
    .xor(timestampThree)
    .toHexString()
  const credentialsSignerThree = await signer.signMessage(
    ethers.utils.arrayify(messageThree)
  )
  const sigThree = ethers.utils.splitSignature(credentialsSignerThree)
  const signatureDataThree = {
    signature: {
      v: sigThree.v,
      r: sigThree.r,
      s: sigThree.s,
    },
    signedAt: timestampThree,
  }
  console.log('signed all data')

  // all borrow variables
  const proof_ = proof.proof
  const witness_ = proof.inputs
  const borrower = (await getNamedAccounts()).borrower

  // get tokens
  const lendToken = '0x6b175474e89094c44da98b954eedeac495271d0f'
  const collToken = '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2'
  const lendingToken =
    typeof lendToken === 'string' ? await tokens.get(lendToken) : lendToken

  // get loan amount
  const loanAmount = 1
  const assetAmount = toBN(loanAmount, await lendingToken.decimals())

  // collateral amount
  const collAmount = '100000'

  console.log('coll amount ')
  // create loan user request object
  const request_ = {
    borrower: borrower,
    assetAddress: '0x6b175474e89094c44da98b954eedeac495271d0f',
    assetAmount: assetAmount,
    collateralAsset: '0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2',
    collateralAmount: collAmount,
    collateralRatio: 5000,
    duration: moment.duration(1, 'day').asSeconds(),
    code: 2,
  }

  // teller market address
  const marketHandlerAddress_ = '0x2858023076c86347CDd7DEa4F38aa215cbbCa91b'
  console.log('taking out loan')
  // create loan request object
  const loanRequest = {
    request: request_,
    marketHandlerAddress: marketHandlerAddress_,
    snarkProof: proof_,
    snarkWitnesses: witness_,
    dataProviderSignatures: [
      signatureDataOne,
      signatureDataTwo,
      signatureDataThree,
    ],
    providers: providerAddresses,
  }
  const tx = diamond
    .connect(ethers.provider.getSigner(borrower))
    .takeOutLoan(loanRequest, collToken, collAmount)

  return {
    tx,
    getHelpers: async (): Promise<LoanHelpersReturn> => {
      await tx
      const allBorrowerLoans = await diamond.getBorrowerLoans(borrower)
      const loanID = allBorrowerLoans[allBorrowerLoans.length - 1].toString()
      return await loanHelpers(loanID)
    },
  }
}

interface LoanDetailsReturn {
  lendingToken: ERC20
  collateralToken: ERC20
  loan: PromiseReturnType<typeof ITellerDiamond.prototype.getLoan>
  debt: PromiseReturnType<typeof ITellerDiamond.prototype.getDebtOwed>
  terms: PromiseReturnType<typeof ITellerDiamond.prototype.getLoanTerms>
  totalOwed: BigNumber
  borrower: {
    address: string
    signer: Signer
  }
  refresh: () => ReturnType<typeof loanDetails>
}
const loanDetails = async (
  loanID: BigNumberish
): Promise<LoanDetailsReturn> => {
  const diamond = await contracts.get<ITellerDiamond>('TellerDiamond')
  const loan = await diamond.getLoan(loanID)
  const lendingToken = await tokens.get(loan.lendingToken)
  const collateralToken = await tokens.get(loan.collateralToken)
  const debt = await diamond.getDebtOwed(loan.id)
  const totalOwed = debt.principalOwed.add(debt.interestOwed)
  const terms = await diamond.getLoanTerms(loan.id)
  const signer = await ethers.provider.getSigner(loan.borrower)
  return {
    loan,
    lendingToken,
    collateralToken,
    debt,
    totalOwed,
    terms,
    borrower: { address: loan.borrower, signer },
    refresh: () => loanDetails(loanID),
  }
}

interface CommonLoanArgs {
  diamond: ITellerDiamond
  details: LoanDetailsReturn
  from?: Signer
}

interface DepositCollateralArgs extends CommonLoanArgs {
  amount?: BigNumberish
}

const depositCollateral = async (
  args: DepositCollateralArgs
): Promise<ContractTransaction> => {
  const {
    diamond,
    details,
    amount = await collateralNeeded({ diamond, details }),
    from = details.borrower.signer,
  } = args
  const weth = await tokens.get('WETH')
  const collateralToken = await tokens.get(details.loan.collateralToken)
  const options: PayableOverrides = {}
  if (
    ethers.utils.getAddress(details.loan.collateralToken) ==
    ethers.utils.getAddress(weth.address)
  ) {
    options.value = amount
  } else {
    await collateralToken.approve(diamond.address, amount)
  }
  return await diamond
    .connect(from)
    .depositCollateral(details.loan.id, amount, options)
}
interface WithdrawCollateralArgs extends CommonLoanArgs {
  amount: BigNumberish
}
const withdrawCollateral = async (
  args: WithdrawCollateralArgs
): Promise<ContractTransaction> => {
  const { diamond, details, amount, from = details.borrower.signer } = args
  return await diamond.connect(from).withdrawCollateral(amount, details.loan.id)
}
interface CollateralNeededArgs extends CommonLoanArgs {}
const collateralNeeded = async (
  args: CollateralNeededArgs
): Promise<BigNumber> => {
  const { diamond, details } = args
  const { neededInCollateralTokens } = await diamond.getCollateralNeededInfo(
    details.loan.id
  )
  return neededInCollateralTokens
}
interface CollateralCurrentArgs extends CommonLoanArgs {}
const collateralCurrent = async (
  args: CollateralCurrentArgs
): Promise<BigNumber> => {
  const { diamond, details } = args
  return await diamond.getLoanCollateral(details.loan.id)
}
interface RepayLoanArgs extends CommonLoanArgs {
  amount: BigNumberish
}
const repayLoan = async (args: RepayLoanArgs): Promise<ContractTransaction> => {
  const {
    diamond,
    details: { loan, borrower },
    amount,
    from = borrower.signer,
  } = args
  return await diamond.connect(from).repayLoan(loan.id, amount)
}
const escrowRepayLoan = async (
  args: RepayLoanArgs
): Promise<ContractTransaction> => {
  const {
    diamond,
    details: { loan, borrower },
    amount,
    from = borrower.signer,
  } = args
  return await diamond.connect(from).escrowRepay(loan.id, amount)
}
