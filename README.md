
---

# GoldSilverStablecoin 

**GoldSilverStablecoin** is a Solidity-based stablecoin smart contract backed by a weighted ratio of gold (80%) and silver (20%). The contract uses Chainlink price feeds for real-time gold and silver price data to determine the stablecoin value. This project provides a robust solution for creating a tangible asset-backed cryptocurrency.  

---
# Disclaimer

   **Use at Your Own Risk:**
This smart contract and its associated code are provided as-is, without any warranties or guarantees of any kind. The project is intended for educational and experimental purposes only. The author (Vedang Prasad Limaye) does not assume responsibility for any financial loss, technical issues, or damages incurred as a result of using this project.

Before using the smart contract in production, users should:

Perform their own due diligence and testing.
Seek professional advice for any legal, financial, or technical implications.
Ensure they understand the risks involved in deploying and using blockchain-based solutions.
By interacting with this project, you acknowledge and agree that any loss or issue arising from its use is solely your responsibility.
---

## Features  

- **Minting**: Stablecoins can be minted based on the value of gold and silver provided by the owner.  
- **Burning**: Users can burn stablecoins, effectively reducing the total supply.  
- **Real-Time Price Feeds**: The contract integrates Chainlink price feeds to fetch live gold and silver prices.  
- **Ratio-Based Valuation**: Implements an 80:20 ratio for gold-to-silver value calculations.  
- **Access Control**: Only the contract owner can mint stablecoins, ensuring secure management.  

---

## Prerequisites  

### Tools Required  
- [Foundry](https://getfoundry.sh) (for development, testing, and deployment)  
- Node.js (for additional package support, if needed)  
- Ethereum wallet (e.g., MetaMask or Anvil for local testing)  
- RPC endpoint (e.g., Infura or Alchemy for mainnet/testnet access)  

### Environment Variables  
The project requires the following environment variables to run:  
```bash  
export GOLD_PRICE_FEED=<Chainlink Gold/USD Price Feed Address>  
export SILVER_PRICE_FEED=<Chainlink Silver/USD Price Feed Address>  
export PRIVATE_KEY=<Your Ethereum Private Key>  
```  

- Replace `<Chainlink Gold/USD Price Feed Address>` and `<Chainlink Silver/USD Price Feed Address>` with actual Chainlink addresses for the desired network.  
- Replace `<Your Ethereum Private Key>` with your private key for deployment or interaction.  

---

## Library Imports  

The project relies on the following libraries:  

1. **OpenZeppelin Contracts**: For ERC20 token standard and ownership modules.  
2. **Forge-std**: Foundry's standard library for testing and deployment.  
3. **Chainlink Brownie Contracts**: For accessing Chainlink price feed interfaces.  

### Steps to Install Libraries  

#### 1. OpenZeppelin Contracts  
Run the following command to install OpenZeppelin Contracts into your Foundry project:  
```bash  
forge install OpenZeppelin/openzeppelin-contracts  
```  

#### 2. Forge-std Library  
Install the standard library for testing and scripting:  
```bash  
forge install foundry-rs/forge-std  
```  

#### 3. Chainlink Brownie Contracts  
Install the Chainlink Brownie contracts:  
```bash  
forge install smartcontractkit/chainlink-brownie-contracts  
```  

#### Update Dependencies  
After installing the libraries, run the following command to fetch and link them in your project:  
```bash  
forge update  
```  

---

## Getting Started  

### Clone the Repository  
```bash  
git clone https://github.com/Vedang456/GoldSilverStablecoin.git  
cd GoldSilverStablecoin  
```  

### Compile the Contract  
Run the following to compile the smart contract:  
```bash  
forge build  
```  

---

## Deployment  

The deploy script is designed to streamline the deployment process using Foundry.  

### Steps to Deploy  
1. Export the required environment variables:  
   ```bash  
   export GOLD_PRICE_FEED=0x...  # Replace with actual gold price feed address  
   export SILVER_PRICE_FEED=0x...  # Replace with actual silver price feed address  
   export PRIVATE_KEY=0x...  # Replace with your Ethereum private key  
   ```  

2. Run the deployment script:  
   ```bash  
   forge script script/Deploy.sol --rpc-url <RPC_URL> --broadcast --verify --private-key $PRIVATE_KEY  
   ```  
   - Replace `<RPC_URL>` with your Ethereum provider's RPC endpoint (e.g., Infura, Alchemy, or Anvil for local testing).  

3. Verify the deployment:  
   - Check the deployment logs for the deployed contract address.  
   - Confirm on a blockchain explorer (e.g., Etherscan for mainnet/testnet).  

---

## Testing  

### Writing and Running Tests  
This project includes flexibility for users to write and run their own tests using Foundry.  
1. Write test cases in the `test` folder.  
2. Execute the test suite:  
   ```bash  
   forge test  
   ```  

Foundry's testing framework will compile and execute all tests, providing detailed output for any issues.  

---

## Usage  

After deploying the contract, you can interact with it using a web3 client (e.g., Remix, Foundry's `cast`, or a custom dApp).  

Key functions include:  
- **`mint(uint256 goldAmount, uint256 silverAmount)`**: Mints stablecoins based on provided gold and silver amounts. Restricted to the contract owner.  
- **`burn(uint256 amount)`**: Burns stablecoins from the caller's account.  
- **`calculateStablecoinValue(uint256 goldAmount, uint256 silverAmount)`**: Calculates the stablecoin value using gold and silver amounts.  

---

## License  

This project is licensed under the MIT License. You are free to use, modify, and distribute the code, but proper attribution is required.  

---

## Copyright  

This project and its codebase are copyright © 2025 Vedang Prasad Limaye. Unauthorized copying or redistribution without explicit permission is strictly prohibited.  

--- 
