// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./Subject.sol";
import "./Observer.sol";

contract Oracle is Subject, Ownable {
    uint public constant ETH_IN_WEI = 10 ** 18;
    uint private lastRatio = 0;
    uint private lastUpdate = 0;
    address[] subscribers;

    constructor(uint ethPriceInCents) Ownable(msg.sender) {
        lastRatio = calcWeiCentRatio(ethPriceInCents);
        lastUpdate = block.timestamp;
    }

    function calcWeiCentRatio(
        uint ethPriceInCents
    ) internal pure returns (uint) {
        return (ETH_IN_WEI / ethPriceInCents);
    }

    function setEthPrice(uint ethPriceInCents) external {
        require(ethPriceInCents > 0, "ETH price cannot be zero");
        uint weiCentRatio = calcWeiCentRatio(ethPriceInCents);
        require(weiCentRatio > 0, "Wei/cent ratio cannot be zero");

        lastRatio = weiCentRatio;
        lastUpdate = block.timestamp;

        notify();
    }

    function getWeiRatio() external view returns (uint) {
        return lastRatio;
    }

    function register(address subscriber) external onlyOwner {
        require(subscriber != address(0), "Invalid subscriber address");
        emit Subscribed(subscriber);
        for (uint i = 0; i < subscribers.length; i++) {
            if (subscribers[i] == subscriber) {
                return;
            }
        }
        for (uint i = 0; i < subscribers.length; i++) {
            if (subscribers[i] == address(0)) {
                subscribers[i] = subscriber;
                Observer(subscriber).updtate(lastRatio);
                return;
            }
        }
        subscribers.push(subscriber);
        Observer(subscriber).updtate(lastRatio);        
    }

    function unregister(address subscriber) external onlyOwner {
        require(subscriber != address(0), "Invalid subscriber address");
        for (uint i = 0; i < subscribers.length; i++) {
            if (subscribers[i] == subscriber) {
                delete subscribers[i];
                emit Unsubscribed(subscriber);
                return;
            }
        }
    }

    function notify() internal {
        uint count = 0;
        for (uint i = 0; i < subscribers.length; i++) {
            if (subscribers[i] != address(0)) {
                Observer(subscribers[i]).updtate(lastRatio);
                count++;
            }
        }
        if (count > 0) {
            emit AllUpdated(subscribers);
        }
    }
}