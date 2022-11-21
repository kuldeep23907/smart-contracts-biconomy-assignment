require('dotenv').config();
const path = require('path');
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      host: '127.0.0.1', // Localhost (default: none)
      port: 8545, // Standard Ethereum port (default: none)
      network_id: '*', // Any network (default: none)
    },
    goerli: {
      provider: () =>
        new HDWalletProvider(
          process.env.MNEMONIC,
          'https://goerli.infura.io/v3/' + process.env.INFURA_KEY
        ),
      network_id: 5,
      confirmations: 1,
      timeoutBlocks: 700,
      skipDryRun: true,
      gas: 1000000, // 8000000,
      // gasPrice: 30000000000,
    },
    compilers: {
      solc: {
        version: '0.8.15', // Fetch exact version from solc-bin (default: truffle's version)
        // docker: false,        // Use "0.5.1" you've installed locally with docker (default: false)
        settings: {
          // See the solidity docs for advice about optimization and evmVersion
          optimizer: {
            enabled: true,
            runs: 200,
          },
          // evmVersion: "byzantium"
        },
      },
    },
  },
};
