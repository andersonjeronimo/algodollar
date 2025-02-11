// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";

const ETH_PRICE_IN_CENTS = 2000000;
const ETH_INITIAL_DEPOSIT = ethers.parseEther("0.01");

const AlgoDollarModule = buildModule("Algodollar", (m) => {

  const stablecoin = m.contract("StableCoin");
  const rebase = m.contract("Rebase");
  const oracle = m.contract("Oracle", [ETH_PRICE_IN_CENTS]);

  m.call(rebase, "setStablecoin", [stablecoin]);
  m.call(rebase, "pause", []);

  m.call(oracle, "register", [rebase]);

  m.call(rebase, "initialize", [], { value: ETH_INITIAL_DEPOSIT });

  return { stablecoin, oracle, rebase };
});

export default AlgoDollarModule;