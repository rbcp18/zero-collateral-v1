// import chai from 'chai'
// import { ethers } from 'hardhat'

// chai.Assertion.overwriteMethod(
//   'eql',
//   (_super) =>
//     function (this: any, ...args: any[]) {
//       const obj = chai.util.flag(this, 'object')
//       if (ethers.BigNumber.isBigNumber(obj)) {
//         const expected = ethers.BigNumber.isBigNumber(args[0])
//           ? args[0].toString()
//           : args[0]
//         new chai.Assertion(obj.toString()).to.eql(expected, ...args.slice(1))
//       } else {
//         _super.apply(this, args)
//       }
//     }
// )
