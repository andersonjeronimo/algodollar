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
    uint public weiCentRatio = 0;

    mapping(address => uint) public ethBalance; // customer => wei balance

    constructor() Ownable(msg.sender) {}

    function initialize() external payable onlyOwner {
        require(weiCentRatio > 0, "Rebase must subscribe to an oracle");
        require(
            msg.value >= weiCentRatio,
            "Value cannot be less than wei ratio"
        );
        require(stablecoin != address(0), "Invalid stablecoin address");

        ethBalance[msg.sender] = msg.value;
        //por exemplo: se $0.01 = 100 weis (wei ratio),
        //caso o msg.value for 200 weis,
        //serão mintados 2 tokens (considerando ratio = 100 weis p/ cada U$0.01);
        IStableCoin(stablecoin).mint(msg.sender, msg.value / weiCentRatio);
        adjustSupply();
        lastUpdate = block.timestamp;
    }

    function setUpdateTolerance(uint toleranceInSeconds) external onlyOwner {
        require(toleranceInSeconds > 0, "Tolerance in seconds cannot be zero");
        updtateTolerance = toleranceInSeconds;
    }

    function setStablecoin(address _stablecoin) external onlyOwner {
        require(
            _stablecoin != address(0),
            "Invalid stablecoin address (zero address)"
        );
        stablecoin = _stablecoin; //IStableCoin(newStablecoin);
    }

    function updtate(uint _weiCentRatio) external {
        weiCentRatio = _weiCentRatio;
        lastUpdate = block.timestamp;
        emit Updated(lastUpdate, weiCentRatio);
    }

    // 100 = 1:1, 97 = 0.97, 104 = 1.04, etc...
    function getParity() public view returns (uint) {
        require(weiCentRatio > 0, "Rebase must subscribe to an oracle");
        return
            (IStableCoin(stablecoin).totalSupply() * 100) /
            (address(this).balance / weiCentRatio);
    }

    function rebase() internal returns (uint) {
        uint parity = getParity();
        if (parity == 0) {
            _pause();
            return 0;
        }
        //ex.: totalSupply = 1000
        //parity = 104 = 4% acima = 40
        //
        if (parity > 100) {
            IStableCoin(stablecoin).burn(
                owner(),
                (IStableCoin(stablecoin).totalSupply() * (parity - 100)) / 100
            );
        }
        if (parity <= 100) {
            IStableCoin(stablecoin).mint(
                owner(),
                (IStableCoin(stablecoin).totalSupply() * (100 - parity)) / 100
            );
        }
        return IStableCoin(stablecoin).totalSupply();
    }

    function adjustSupply() internal {
        uint oldSupply = IStableCoin(stablecoin).totalSupply(); //ERC20 function
        uint newSupply = rebase();
        if (newSupply != 0) {
            lastUpdate = block.timestamp;
            emit SupplyUpdated(lastUpdate, oldSupply, newSupply);
        }
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function deposit() external payable whenNotPaused whenNotOutdated {
        require(msg.value >= weiCentRatio, "Insufficient deposit");
        ethBalance[msg.sender] += msg.value;
        uint amountUsda = msg.value / weiCentRatio;
        //aqui é o momento de cobrar taxas pela emissão dos tokens
        IStableCoin(stablecoin).mint(msg.sender, amountUsda);
    }

    function withdrawETH(
        uint amountEth
    ) external whenNotPaused whenNotOutdated {
        require(
            ethBalance[msg.sender] >= amountEth,
            "Insufficient ETH balance"
        );
        uint amountUsda = amountEth / weiCentRatio;
        require(
            IStableCoin(stablecoin).balanceOf(msg.sender) >= amountUsda,
            "Insufficient USDA balance"
        );
        //tudo ok
        ethBalance[msg.sender] -= amountEth;
        IStableCoin(stablecoin).burn(msg.sender, amountUsda);
        payable(msg.sender).transfer(amountEth);
    }

    function withdrawUSDA(
        uint amountUsda
    ) external whenNotPaused whenNotOutdated {
        require(
            IStableCoin(stablecoin).balanceOf(msg.sender) >= amountUsda,
            "Insufficient USDA balance"
        );
        uint amountEth = weiCentRatio * amountUsda;
        require(
            ethBalance[msg.sender] >= amountEth,
            "Insufficient ETH balance"
        );
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
