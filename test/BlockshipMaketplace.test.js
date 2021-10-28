const hre = require("hardhat");
const { ethers, waffle } = require("hardhat");
const { expect, use } = require("chai");
const { solidity } = require("ethereum-waffle");
const { BigNumber, utils, provider } = ethers;

use(solidity);

const ZERO = new BigNumber.from("0");
const ONE = new BigNumber.from("1");
const ONE_ETH = utils.parseUnits("1", 5);
const LESS_ETH = utils.parseUnits("100000000000000000", 5);
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";
const MAX_UINT = "115792089237316195423570985008687907853269984665640564039457584007913129639935";

describe("BlockshipMarketplace", () => {
    let marketplace, nft, partnerShare;
    let deployer, taker, maker, partner;
    let tokenId = 1;

    it("it should deploy marketplace contract", async () => {
        [deployer, taker, maker, partner] = await ethers.getSigners();
        const marketplaceContract = await ethers.getContractFactory("BlockshipMaketplace");
        marketplace = await marketplaceContract.deploy();

        const nftContract = await ethers.getContractFactory("DNFT");
        nft = await nftContract.deploy();
        console.log(nft.address);
    });
    it("it should mint NFTs", async () => {
        await nft.connect(maker).setApprovalForAll(nft.address, true);
        await expect(nft.connect(maker).mint(maker.address, tokenId)).to.emit(nft, "Minted");
        // tokenId = await nft.currentId();
    });
    it("it should give shares to partner", async () => {
        await nft.connect(maker).setApprovalForAll(nft.address, true);
        // partnerShare = await marketplace.connect(maker).transfer(partner.address, 1, 250);
        // const tx = await expect(nft.connect(maker).transfer(partner.address, 1, 250)).to.emit(nft, "Transfer").withArgs(maker.address, partner.address, 1,250);
        const tx = await nft.connect(maker).transfer(partner.address, tokenId, 250);
        const rc = await tx.wait(); // 0ms, as tx is already confirmed
        const event = rc.events.find((event) => event.event === "Transfer");
        const eventValues = event.args;
        console.log(eventValues);
    });
    //check this test
    it("it should not create marketplace item", async function () {
        await expect(marketplace.connect(maker).createMarketItem(nft.address, tokenId, ONE_ETH)).to.not.reverted;
    });
    it("it should create marketplace item", async function () {
        await nft.connect(maker).setApprovalForAll(nft.address, true);
        await expect(marketplace.connect(maker).createMarketItem(nft.address, tokenId, ONE_ETH)).to.emit(marketplace, "MarketItemCreated");
    });
    it("it should fetch token owners", async () => {
        const owners = await marketplace.connect(deployer).listOfTokenOwners(tokenId);
        console.log(owners);
    });
    it("it should create marketplace sell", async () => {
        // const owner = await nft.ownerOf(tokenId)
        // console.log(owner);
        expect(await nft.connect(taker).buyerIsNotSeller(tokenId, taker.address)).to.not.equal(false);
        // expect(await marketplace.connect(deployer)).to.not.equal(taker.address);

        await expect(marketplace.connect(taker).createMarketSale(nft.address, tokenId, { value: ONE_ETH })).to.emit(
            marketplace,
            "ItemSold"
        );

        // expect(await nft.ownerOf(tokenId)).to.equal(taker.address);
    });
});
