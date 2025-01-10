import dotenv from 'dotenv';
dotenv.config();

import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  defaultNetwork: "local",
  networks: {
    local: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
      accounts: {
        mnemonic: "test test test test test test test test test test test junk"
      }
    },
    sepolia: {
      url: process.env.RPC_URL_1,
      chainId: parseInt(`${process.env.CHAIN_ID_1}`),
      accounts: {
        mnemonic: process.env.SECRET
      }
    },
    amoy: {
      url: process.env.RPC_URL_2,
      chainId: parseInt(`${process.env.CHAIN_ID_2}`),
      accounts: {
        mnemonic: process.env.SECRET
      }
    }
  },
  etherscan: {
    apiKey: process.env.API_KEY_2
  }

};

export default config;
