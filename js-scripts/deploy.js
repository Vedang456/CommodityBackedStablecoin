const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();  

    // Convert to string before parsing units
    const initialSupply = ethers.parseUnits("1000000", 18); // 1M tokens with 18 decimals

    const GoldSilverStablecoin = await ethers.getContractFactory("GoldSilverStablecoin");
    const contract = await GoldSilverStablecoin.deploy(deployer.address, initialSupply);

    console.log("Contract deployed to:", await contract.getAddress()); // Use getAddress() instead of target
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
