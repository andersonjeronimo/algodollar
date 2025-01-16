import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import hre from "hardhat";

describe("Rebase tests", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployFixture() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await hre.ethers.getSigners();

    const StableCoin = await hre.ethers.getContractFactory("StableCoin");
    const stableCoin = await StableCoin.deploy();

    const Oracle = await hre.ethers.getContractFactory("Oracle");
    const oracle = await Oracle.deploy(2000 * 100);//valor arbitrário para testes.

    const Rebase = await hre.ethers.getContractFactory("Rebase");
    const rebase = await Rebase.deploy();

    //configs 
    await oracle.register(rebase.target);
    
    await rebase.setStablecoin(stableCoin.target);    
    await rebase.initialize({ value: hre.ethers.parseEther("1") });   

    return { oracle, stableCoin, rebase, owner, otherAccount };
  }

  it("Should deposit", async function () {
    const { rebase, otherAccount } = await loadFixture(deployFixture);

    const instance = rebase.connect(otherAccount);
    
    await instance.deposit({ value: hre.ethers.parseEther("1") });

    const address = await otherAccount.getAddress();    
    const balanceETH = await rebase.ethBalance(address);
    //const balanceUSDA = await stableCoin.balanceOf(otherAccount.address);
    expect(Number(balanceETH)).to.equal(Number(hre.ethers.parseEther("1")));
  });





});