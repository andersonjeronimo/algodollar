// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.0.0
pragma solidity ^0.8.22;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "./IStableCoin.sol";

contract StableCoin is ERC20, IStableCoin, Ownable {
    address public rebase;

    constructor() ERC20("AlgoDollar", "USDA") Ownable(msg.sender) {}

    function setRebase(address newRebase) external onlyOwner {
        rebase = newRebase;
    }

    function mint(address to, uint256 amount) external onlyAdmin {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyAdmin {
        _burn(from, amount);
    }

    modifier onlyAdmin() {
        require(
            msg.sender == rebase || msg.sender == owner(),
            "Only rebase contract / contract owner can make this call"
        );
        _;
    }
}
