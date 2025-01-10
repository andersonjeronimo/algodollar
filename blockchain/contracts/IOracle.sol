// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface IOracle {
    event Subscribed(address indexed subscriber);
    event Unsubscribed(address indexed subscriber);
    event AllUpdated(address[] subscribers);

    function setEthPrice(uint ethPriceInPenny) external;

    function getWeiRatio() external view returns (uint);

    function subscribe(address subscriber) external;

    function unsubscribe(address subscriber) external;
}
