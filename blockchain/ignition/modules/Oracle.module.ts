// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import { ethers } from "hardhat";

const ETH_PRICE_IN_CENTS = 2000000;
const ETH_INITIAL_DEPOSIT = ethers.parseEther("0.01");

const OracleModule = buildModule("OracleModule", (m) => {

  const oracle = m.contract("Oracle", [ETH_PRICE_IN_CENTS]);
  const rebase = m.contract("Rebase");
  const stablecoin = m.contract("StableCoin");

  //m.call(rebase, "pause", []);

  m.call(rebase, "setStablecoin", [stablecoin]);
  m.call(rebase, "initialize", [], {value:ETH_INITIAL_DEPOSIT});

  m.call(oracle, "register", [rebase]);

  /*
    await oracle.register(rebase.target);
    await rebase.setStablecoin(stableCoin.target);
    await rebase.initialize({ value: ONE_ETH });
   */

  return { oracle, stablecoin, rebase };
});

export default OracleModule;
