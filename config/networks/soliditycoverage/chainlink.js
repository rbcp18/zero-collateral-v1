const { DUMMY_ADDRESS } = require('../../consts');

module.exports = {
    USDC_ETH: {
        address: DUMMY_ADDRESS,
        collateralDecimals: 18, // ETH
        tokenDecimals: 6,
        responseDecimals: 18,
    },
    DAI_ETH: {
        address: DUMMY_ADDRESS,
        collateralDecimals: 18, // ETH
        tokenDecimals: 18,
        responseDecimals: 18,
    },
    LINK_USD: {
        address: DUMMY_ADDRESS,
        collateralDecimals: 18, // LINK
        tokenDecimals: 18,
        responseDecimals: 8,
    },
};