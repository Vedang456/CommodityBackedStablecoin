const { ethers } = require("hardhat");

async function main() {
    const GoldSilverStablecoin = await ethers.getContractFactory("GoldSilverStablecoin");
    const contract = await GoldSilverStablecoin.deploy();
    await contract.deployed();

    console.log(`Deployed to: ${contract.address}`);
}

main().catch((error) => {
    console.error(error);
    process.exit(1);
});
