import dotenv from 'dotenv';
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@nomicfoundation/hardhat-verify';
import '@openzeppelin/hardhat-upgrades';

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.20",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    sepolia: {
      url: `https://sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ],
      chainId: 11155111
    },
    amoy: {
      url: `https://polygon-amoy.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    cardona: {
      url: `https://rpc.cardona.zkevm-rpc.com`,
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    arbitrum: {
      url: `https://arbitrum-sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    zircuit: {
      url: "https://zircuit1.p2pify.com/",
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    rootstock: {
      url: "https://public-node.testnet.rsk.co/",
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    jenkins: {
      url: "https://jenkins.rpc.caldera.xyz/http",
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    scroll: {
      url: "https://sepolia-rpc.scroll.io/",
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    alfajores: {
      url: `https://celo-alfajores.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    linea: {
      url: `https://linea-sepolia.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    },
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      accounts: [
        `${process.env.PRIVATE_KEY}`
      ]
    }
  }
};

export default config;
