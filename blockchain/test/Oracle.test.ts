import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("Oracle tests", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const Oracle = await hre.ethers.getContractFactory("Oracle");
    //const EtherToWei =  hre.ethers.parseUnits("1", "ether");
    //ETH price in 11/01/2025 ~ $3,000.00 USD
    //Ethereum price in pennys = 2000 * 100
    const oracle = await Oracle.deploy(2000 * 100);

    const Rebase = await hre.ethers.getContractFactory("Rebase");
    const rebase = await Rebase.deploy();    

    return { oracle, rebase, owner, otherAccount };
  }

  describe("WeiUSDOracle", function () {

    it("Should set the right owner", async function () {
      const { oracle, owner } = await loadFixture(deployFixture);
      expect(await oracle.owner()).to.equal(owner.address);
    });

    it("Should get the wei / penny ratio", async function () {
      const { oracle } = await loadFixture(deployFixture);
      const ETH_IN_WEI = 1 * 10 ** 18;
      const ETH_IN_USD = 2000;
      const ETH_IN_PENNYS = ETH_IN_USD * 100;
      const WEI_PENNY_RATIO = ETH_IN_WEI / ETH_IN_PENNYS;//5.000.000.000.000
      expect(await oracle.getWeiRatio()).to.equal(String(WEI_PENNY_RATIO));
    });

    it("Should set the ETH price", async function () {
      const { oracle } = await loadFixture(deployFixture);
      const ETH_IN_WEI = 1 * 10 ** 18;
      const ETH_IN_USD = 4000; //<-----increase ETH price will decrease the wei ratio
      const ETH_IN_PENNYS = ETH_IN_USD * 100;
      const WEI_PENNY_RATIO = ETH_IN_WEI / ETH_IN_PENNYS;//2.500.000.000.000

      await oracle.setEthPrice(ETH_IN_PENNYS);

      expect(await oracle.getWeiRatio()).to.equal(String(WEI_PENNY_RATIO));
    });

    it("Should register a subscriber", async function () {
      const { oracle, rebase } = await loadFixture(deployFixture);
      expect(await oracle.register(rebase.target)).to.emit(oracle, "Subscribed");
    });

    it("Should unregister a subscriber", async function () {
      const { oracle, rebase } = await loadFixture(deployFixture);
      await oracle.register(rebase.target);
      expect(await oracle.unregister(rebase.target)).to.emit(oracle, "Unsubscribed");
    });

    it("Should notify ETH price update", async function () {
      const { oracle, rebase } = await loadFixture(deployFixture);
      await oracle.register(rebase.target);      

      expect(await oracle.setEthPrice(400000)).to.emit(oracle, "AllUpdated").withArgs([rebase.target]);
    });


  });

});