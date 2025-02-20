require("dotenv").config();
require("@nomicfoundation/hardhat-ethers");
require("@nomicfoundation/hardhat-foundry"); // Add this

module.exports = {
  solidity: "0.8.20",
  networks: {
    local: {
      url: process.env.RPC_URL || "http://127.0.0.1:8545",
      chainId: 31337,
    },
  },
  foundry: {
    profile: "default",
  },
};
