// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import "./Observer.sol";

contract Rebase is Observer {   

    function updtate(uint weisPerPenny) external {
        emit Updated(block.timestamp, 1, 1);
    }
}