import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("Algodollar tests", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.

  const ONE_ETH = hre.ethers.parseEther("1");
  const ETH_IN_WEI = Number(hre.ethers.parseUnits("1", "ether"));//1 * 10 ** 18;
  const ETH_IN_USD = 2000;
  const ETH_IN_CENTS = ETH_IN_USD * 100;
  const WEI_CENT_RATIO = ETH_IN_WEI / ETH_IN_CENTS;//5.000.000.000.000

  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const StableCoin = await hre.ethers.getContractFactory("StableCoin");
    const stableCoin = await StableCoin.deploy();

    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy(ETH_IN_CENTS);//valor arbitrário para testes.

    const Rebase = await hre.ethers.getContractFactory("Rebase");
    const rebase = await Rebase.deploy();

    //configs for Rebase Contract
    await rebase.setStablecoin(stableCoin.target);
    await oracle.register(rebase.target);
    await rebase.initialize({ value: ONE_ETH });

    return { oracle, stableCoin, rebase, owner, otherAccount };
  }

  describe("Rebase contract", function () {

    it("Should deposit", async function () {
      const { stableCoin, rebase, otherAccount } = await loadFixture(deployFixture);

      const instance = rebase.connect(otherAccount);
      await instance.deposit({ value: ONE_ETH });

      const balanceETH = await rebase.ethBalance(otherAccount.address);
      const balanceUSDA = await stableCoin.balanceOf(otherAccount.address);

      expect(Number(balanceETH)).to.equal(Number(ONE_ETH));
      expect(Number(balanceUSDA)).to.equal(Number(ETH_IN_WEI / WEI_CENT_RATIO));
    });

    it("Should withdraw in ETH", async function () {
      const { rebase, otherAccount } = await loadFixture(deployFixture);

      const instance = rebase.connect(otherAccount);
      await instance.deposit({ value: ONE_ETH });
      await instance.deposit({ value: ONE_ETH });
      await instance.withdrawETH(ONE_ETH);

      const balanceETH = await rebase.ethBalance(otherAccount.address);

      expect(Number(balanceETH)).to.equal(Number(ONE_ETH));
    });

    it("Should withdraw in USDA", async function () {
      const { stableCoin, rebase, otherAccount } = await loadFixture(deployFixture);

      const instance = rebase.connect(otherAccount);
      await instance.deposit({ value: ONE_ETH });
      await instance.deposit({ value: ONE_ETH });

      const ONE_ETH_IN_USDA = ETH_IN_WEI / WEI_CENT_RATIO;
      await instance.withdrawUSDA(ONE_ETH_IN_USDA);

      const balanceUSDA = await stableCoin.balanceOf(otherAccount.address);

      expect(Number(balanceUSDA)).to.equal(Number(ONE_ETH_IN_USDA));
    });

    it("Should get parity", async function () {
      const { rebase } = await loadFixture(deployFixture);
      expect(await rebase.getParity()).to.equal(100);
    });

    it("Should adjust supply down", async function () {
      const { rebase, stableCoin, oracle } = await loadFixture(deployFixture);

      await rebase.deposit({ value: ONE_ETH });
      const oldSupply = await stableCoin.totalSupply();
      await oracle.setEthPrice(ETH_IN_CENTS * 0.95); //-5%
      const newSupply = await stableCoin.totalSupply();

      expect(newSupply).to.equal(Number(oldSupply) * 0.95);
      expect(await rebase.getParity()).to.equal(100);
    });

    it.only("Should adjust supply up", async function () {
      const { rebase, stableCoin, oracle } = await loadFixture(deployFixture);

      await rebase.deposit({ value: ONE_ETH });
      const oldSupply = await stableCoin.totalSupply();
      await oracle.setEthPrice(ETH_IN_CENTS * 1.05); //+5%
      const newSupply = await stableCoin.totalSupply();

      expect(newSupply).to.equal(Number(oldSupply) * 1.05);
      expect(await rebase.getParity()).to.equal(100);
    });



  });










});