import { Config, Network, Tokens } from '../types/custom/config-types'

const mainnetTokens: Tokens = {
  ETH: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
  // Compound
  CDAI: '0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643',
  CUSDC: '0x39aa39c021dfbae8fac545936693ac917d5e7563',
  CETH: '0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5',
  // ERC20
  WETH: '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',
  DAI: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
  USDC: '0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48',
  USDT: '0xdac17f958d2ee523a2206206994597c13d831ec7',
  LINK: '0x514910771AF9Ca656af840dff83E8264EcF986CA',
  WBTC: '0x2260fac5e5542a773aa44fbcfedf7c193bc2c599',
  SNX: '0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f',
  MKR: '0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2',
  YFI: '0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e',
  LEND: '0x80fB784B7eD66730e8b1DBd9820aFD29931aab03'
}

export const tokensConfigsByNetwork: Config<Tokens> = {
  kovan: {
    ETH: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
    // Compound
    CDAI: '0xf0d0eb522cfa50b716b3b1604c4f0fa6f04376ad',
    CUSDC: '0x4a92e71227d294f041bd82dd8f78591b75140d63',
    CETH: '0x41b5844f4680a8c38fbb695b7f9cfd1f64474a72',
    // ERC20
    WETH: '0xd0a1e359811322d97991e03f863a0c30c2cf029c',
    DAI: '0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa',
    USDC: '0xb7a4f3e9097c08da09517b5ab877f7a917224ede',
    LINK: '0xa36085F69e2889c224210F603D836748e7dC0088'
  },
  rinkeby: {
    ETH: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
    // Compound
    CDAI: '0x6D7F0754FFeb405d23C51CE938289d4835bE3b14',
    CUSDC: '0x5B281A6DdA0B271e91ae35DE655Ad301C976edb1',
    CETH: '0xd6801a1dffcd0a410336ef88def4320d6df1883e',
    // ERC20
    WETH: '0xc778417E063141139Fce010982780140Aa0cD5Ab',
    DAI: '0x5592EC0cfb4dbc12D3aB100b257153436a1f0FEa',
    USDC: '0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b',
    LINK: '0x01BE23585060835E02B77ef475b0Cc51aA1e0709'
  },
  ropsten: {
    ETH: '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE',
    // Compound
    CDAI: '0xdb5Ed4605C11822811a39F94314fDb8F0fb59A2C',
    CUSDC: '0x8aF93cae804cC220D1A608d4FA54D1b6ca5EB361',
    CETH: '0xbe839b6d93e3ea47effcca1f27841c917a8794f3',
    // ERC20
    WETH: '0xc778417e063141139fce010982780140aa0cd5ab',
    DAI: '0xc2118d4d90b274016cB7a54c03EF52E6c537D957',
    USDC: '0x0D9C8723B343A8368BebE0B5E89273fF8D712e3C',
    LINK: '0x20fE562d797A42Dcb3399062AE9546cd06f63280'
  },
  hardhat: mainnetTokens,
  localhost: mainnetTokens,
  mainnet: mainnetTokens
}

export const getTokens = (network: Network) => tokensConfigsByNetwork[network]
