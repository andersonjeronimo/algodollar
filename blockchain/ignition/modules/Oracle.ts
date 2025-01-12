// This setup uses Hardhat Ignition to manage smart contract deployments.
// Learn more about it at https://hardhat.org/ignition

import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

const OracleModule = buildModule("OracleModule", (m) => {

  const oracle = m.contract("Oracle");
  const rebase = m.contract("Rebase");
  const stablecoin = m.contract("StableCoin");
  m.call(rebase, "pause", []);
  m.call(rebase, "setOracle", [oracle]);
  m.call(rebase, "setStablecoin", [stablecoin]);
  m.call(stablecoin, "setRebase", [rebase]);

  return { oracle, stablecoin, rebase };
});

export default OracleModule;
