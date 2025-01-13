// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import "./Observer.sol";
import "./IStableCoin.sol";
import "./Subject.sol";

contract Rebase is Observer, Pausable, Ownable {
    address public oracle;
    address public stablecoin;
    uint public lastUpdate = 0; //timestamp em segundos
    uint private updtateTolerance = 300; //em segundos

    mapping(address => uint) public ethBalance; // customer => wei balance

    constructor() Ownable(msg.sender) {}

    function initialize(uint weisPerPenny) external payable onlyOwner {
        require(weisPerPenny > 0, "Wei ratio cannot be zero");
        require(
            msg.value >= weisPerPenny,
            "Value cannot be less than wei ratio"
        );
        require(stablecoin != address(0), "Must set stablecoin address");
        require(oracle != address(0), "Must set oracle address");

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
        require(
            newOracle != address(0),
            "Invalid oracle address (zero address)"
        );
        oracle = newOracle;
    }

    function setStablecoin(address newStablecoin) external onlyOwner {
        require(
            newStablecoin != address(0),
            "Invalid stablecoin address (zero address)"
        );
        stablecoin = newStablecoin;
    }

    function updtate(uint weisPerPenny) external {
        require(msg.sender == oracle, "Only the oracle can make this call");
        uint oldSupply = IStableCoin(oracle).totalSupply();//ERC20 function
        //TO_DO
        //ajustar o preço
        //ajustar o supply
        uint newSupply = 1;
        
        lastUpdate = block.timestamp;
        emit Updated(block.timestamp, oldSupply, newSupply);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function deposit() external payable whenNotPaused whenNotOutdated {
        uint weisPerPenny = Subject(oracle).getWeiRatio();
        require(msg.value >= weisPerPenny, "Insufficient deposit");
        ethBalance[msg.sender] += msg.value;
        uint amountUsda = msg.value / weisPerPenny;
        //aqui é o momento de cobrar taxas para emissão de tokens
        IStableCoin(stablecoin).mint(msg.sender, amountUsda);
    }

    function withdrawETH(uint amountEth) external whenNotPaused whenNotOutdated {
        require(ethBalance[msg.sender] >= amountEth, "Insufficient ETH balance");
        uint weisPerPenny = Subject(oracle).getWeiRatio();
        uint amountUsda = amountEth / weisPerPenny;
        require(IStableCoin(stablecoin).balanceOf(msg.sender) >= amountUsda, "Insufficient USDA balance");
        //tudo ok        
        ethBalance[msg.sender] -= amountEth;
        IStableCoin(stablecoin).burn(msg.sender, amountUsda);
        payable(msg.sender).transfer(amountEth);
    }

    function withdrawUSDA(uint amountUsda) external whenNotPaused whenNotOutdated {        
        require(IStableCoin(stablecoin).balanceOf(msg.sender) >= amountUsda, "Insufficient USDA balance");
        uint weisPerPenny = Subject(oracle).getWeiRatio();        
        uint amountEth = weisPerPenny * amountUsda;
        require(ethBalance[msg.sender] >= amountEth, "Insufficient ETH balance");
        //tudo ok        
        ethBalance[msg.sender] -= amountEth;
        IStableCoin(stablecoin).burn(msg.sender, amountUsda);        
        payable(msg.sender).transfer(amountEth);        
    }

    modifier whenNotOutdated() {
        require(
            lastUpdate >= (block.timestamp - updtateTolerance),
            "Rebase contract is paused"
        );
        _;
    }
}
