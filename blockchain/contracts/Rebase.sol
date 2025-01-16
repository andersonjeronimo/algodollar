// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

import "./Observer.sol";
import "./IStableCoin.sol";
import "./Subject.sol";

contract Rebase is Observer, Pausable, Ownable {    
    address public stablecoin;    
    uint public lastUpdate = 0; //timestamp em segundos
    uint private updtateTolerance = 300; //em segundos
    uint public weisPerPenny = 0;

    mapping(address => uint) public ethBalance; // customer => wei balance

    constructor() Ownable(msg.sender) { }

    function initialize() external payable onlyOwner {
        require(weisPerPenny > 0, "Rebase must subscribe to an oracle");
        require(msg.value >= weisPerPenny, "Value cannot be less than wei ratio");
        require(stablecoin != address(0), "Invalid stablecoin address");        

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

    function setStablecoin(address _stablecoin) external onlyOwner {
        require(_stablecoin != address(0), "Invalid stablecoin address (zero address)");        
        stablecoin = _stablecoin;//IStableCoin(newStablecoin);
    }

    function updtate(uint _weisPerPenny) external {        
        //uint oldSupply = IStableCoin(stablecoin).totalSupply();//ERC20 function
        //TO_DO
        //ajustar o preço
        //ajustar o supply
        //uint newSupply = 1;
        
        //lastUpdate = block.timestamp;
        //emit Updated(block.timestamp, oldSupply, newSupply);
        emit Updated(block.timestamp, _weisPerPenny);
        weisPerPenny = _weisPerPenny;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }    

    function deposit() external payable whenNotPaused whenNotOutdated {        
        require(msg.value >= weisPerPenny, "Insufficient deposit");
        ethBalance[msg.sender] += msg.value;
        uint amountUsda = msg.value / weisPerPenny;
        //aqui é o momento de cobrar taxas pela emissão dos tokens
        IStableCoin(stablecoin).mint(msg.sender, amountUsda);
    }

    function withdrawETH(uint amountEth) external whenNotPaused whenNotOutdated {
        require(ethBalance[msg.sender] >= amountEth, "Insufficient ETH balance");        
        uint amountUsda = amountEth / weisPerPenny;
        require(IStableCoin(stablecoin).balanceOf(msg.sender) >= amountUsda, "Insufficient USDA balance");
        //tudo ok        
        ethBalance[msg.sender] -= amountEth;
        IStableCoin(stablecoin).burn(msg.sender, amountUsda);
        payable(msg.sender).transfer(amountEth);
    }

    function withdrawUSDA(uint amountUsda) external whenNotPaused whenNotOutdated {        
        require(IStableCoin(stablecoin).balanceOf(msg.sender) >= amountUsda, "Insufficient USDA balance");        
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
