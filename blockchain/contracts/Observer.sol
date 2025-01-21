// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

interface Observer {    
    event SupplyUpdated(uint indexed timestamp, uint oldSupply, uint newSupply);
    event Updated(uint indexed timestamp, uint weiCentRatio);

    function updtate(uint weiCentRatio) external;
}
