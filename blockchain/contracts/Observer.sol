// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface Observer {    
    event Updated(uint indexed timestamp, uint oldSupply, uint newSupply);

    function updtate(uint weiCentRatio) external;
}
