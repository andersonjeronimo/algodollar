// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import "./Observer.sol";

contract Rebase is Observer, Pausable, Ownable {
    address public oracle;
    address public stablecoin;

    constructor() Ownable(msg.sender) {}

    function setOracle(address newOracle) external onlyOwner {
        oracle = newOracle;
    }

    function setStablecoin(address newStablecoin) external onlyOwner {
        stablecoin = newStablecoin;
    }

    function updtate(uint weisPerPenny) external {
        emit Updated(block.timestamp, 1, 1);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function deposit() external payable whenNotPaused {}

    function withdraw() external whenNotPaused {}
}
