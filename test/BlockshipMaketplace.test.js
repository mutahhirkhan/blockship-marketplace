const { ethers, waffle } = require("hardhat");
const { expect, use } = require("chai");
const { solidity } = require("ethereum-waffle");
const { BigNumber, utils, provider } = ethers;
import hre from "hardhat";

use(solidity);

const ZERO = new BigNumber.from("0");
const ONE = new BigNumber.from("1");
const ONE_ETH = utils.parseUnits("1", 5);
const LESS_ETH = utils.parseUnits("100000000000000000", 5);
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const MAX_UINT = "115792089237316195423570985008687907853269984665640564039457584007913129639935";

describe("BlockshipMarketplace", () => {
    let marketplace, nft, tokenId;
    let deployer, user;

    it("it should deploy marketplace contract", async () => {
        [deployer, taker, maker] = await ethers.getSigners();
        const marketplaceContract = await ethers.getContractFactory("BlockshipMaketplace");
        marketplace = await marketplaceContract.deploy();

        const nftContract = await ethers.getContractFactory("DNFT");
        nft = await nftContract.deploy();
        console.log(nft.address);
        console.log(marketplace.address);
    });
});
