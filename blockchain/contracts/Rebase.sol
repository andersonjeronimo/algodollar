// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import "./Observer.sol";
import "./IStableCoin.sol";

contract Rebase is Observer, Pausable, Ownable {
    address public oracle;
    address public stablecoin;
    uint public lastUpdate = 0;//timestamp em segundos
    uint private updtateTolerance = 300; //em segundos

    mapping (address => uint) public ethBalance; // customer => wei balance

    constructor() Ownable(msg.sender) {}

    function initialize(uint weisPerPenny)  external payable onlyOwner () {
        require(weisPerPenny > 0, "Wei ratio cannot be zero");
        require(msg.value >= weisPerPenny, "Value cannot be less than wei ratio");
        require(stablecoin != address(0), "Must set stablecoin address");
        
        ethBalance[msg.sender] = msg.value;        
        //por exemplo: se $0.01 = 100 weis (wei ratio),
        //caso o msg.value for 200 weis,
        //serão mintados 2 tokens (considerando ratio = 100 weis p/ cada U$0.01);
        IStableCoin(stablecoin).mint(msg.sender, msg.value / weisPerPenny);
        lastUpdate = block.timestamp;
    }

    function setUpdateTolerance(uint toleranceInSeconds) external onlyOwner {
        require(toleranceInSeconds > 0, "Tolerance in seconds cannot be zero");
        updtateTolerance = toleranceInSeconds;
    }

    function setOracle(address newOracle) external onlyOwner {
        require(newOracle != address(0), "Invalid oracle address (zero address)");
        oracle = newOracle;
    }

    function setStablecoin(address newStablecoin) external onlyOwner {
        require(newStablecoin != address(0), "Invalid stablecoin address (zero address)");
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

    function deposit() external payable whenNotPaused whenNotOutdated{}

    function withdraw() external whenNotPaused whenNotOutdated{}

    modifier whenNotOutdated {
        require(lastUpdate >= (block.timestamp - updtateTolerance), "Rebase contract is paused");
        _;
    }


}
