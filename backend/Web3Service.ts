import oracleArtifacts from "./Oracle.json";
import rebaseArtifacts from "./Rebase.json";

import { ethers } from "ethers";

const provider = new ethers.AlchemyProvider(`${process.env.NETWORK}`, `${process.env.ALCHEMY_API_KEY}`);

async function getWeiRatio(): Promise<string> {
    const contract = new ethers.Contract(`${process.env.ORACLE_CONTRACT}`, oracleArtifacts.abi, provider);
    return contract.getWeiRatio();
}

async function getParity(): Promise<number> {
    const contract = new ethers.Contract(`${process.env.REBASE_CONTRACT}`, rebaseArtifacts.abi, provider);
    return contract.getParity();
}

async function setEthPrice(ethPriceInCents: number): Promise<string> {
    const wallet = new ethers.Wallet(`${process.env.PRIVATE_KEY}`, provider);
    const contract = new ethers.Contract(`${process.env.ORACLE_CONTRACT}`, oracleArtifacts.abi, wallet);

    const tx = await contract.setEthPrice(ethPriceInCents);
    await tx.wait();
    console.log(tx.hash);
    return tx.hash;
}

export default { setEthPrice, getWeiRatio, getParity }