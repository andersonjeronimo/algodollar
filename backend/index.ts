import dotenv from "dotenv";
dotenv.config();

const Module = require("module");
Module.prototype.require = new Proxy(Module.prototype.require, {
    apply(target, thisArg, argumentsList) {
        const name = argumentsList[0];
        if (/patch-core/g.test(name))
            return {};

        return Reflect.apply(target, thisArg, argumentsList);
    }
})

import Binance from "node-binance-api";
import Web3Service from "./Web3Service";

const MAX_INTERVAL = parseInt(`${process.env.MAX_INTERVAL}`);
const MIN_INTERVAL = parseInt(`${process.env.MIN_INTERVAL}`);
const PRICE_TRIGGER = parseInt(`${process.env.PRICE_TRIGGER}`);

const binance = new Binance({ family: 0, test: false });

let lastReceivedPrice = 0;
let lastRegisteredPrice = 0;
let lastRegisteredTimestamp = 0;

type TickerData = {
    close: number;
}

async function registerPrice() {
    if (!lastReceivedPrice) {
        return console.log("Price not received yet.");
    }
    lastRegisteredPrice = lastReceivedPrice;
    lastRegisteredTimestamp = Date.now();
    await Web3Service.setEthPrice(parseInt(`${lastReceivedPrice * 100}`));
    console.log("Price updated!");
}

const streamUrl = binance.websockets.prevDay("MATICUSDT", async (data: any, converted: TickerData) => {
    lastReceivedPrice = converted.close;
    lastRegisteredTimestamp = Date.now();
    if (!lastRegisteredPrice) {
        lastRegisteredPrice = converted.close;
    }
    const aMinuteAgo = Date.now() - MIN_INTERVAL;
    const priceChange = ((lastReceivedPrice * 100) / lastRegisteredPrice) - 100;

    console.log(lastReceivedPrice);
    console.log(`${priceChange.toFixed(2)} %`);

    if (Math.abs(priceChange) >= PRICE_TRIGGER && lastRegisteredTimestamp < aMinuteAgo) {
        //console.log("Price updated!");
        await registerPrice();
    }
}, true);

console.log(`Stream connected at ${streamUrl}`);

async function updateCycle() {
    console.log("Executing the update cycle...");
    const aHourAgo = Date.now() - MAX_INTERVAL;
    if (lastRegisteredTimestamp < aHourAgo) {
        console.log("Price updated!");
    }
    //console.log("Finishing the update cycle...");
    await registerPrice();

}

//only for test
setTimeout(updateCycle, 10000);

setInterval(updateCycle, MAX_INTERVAL);
 
setInterval(async () => {
    const weiRatio = await Web3Service.getWeiRatio();
    const parity = await Web3Service.getParity();
    console.log(`Wei ratio: ${weiRatio}`);
    console.log(`Parity: ${parity}`);
}, 60 * 1000);
