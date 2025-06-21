// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.0/contracts/access/Ownable.sol";


contract DataRewardToken is ERC20, Ownable {
    constructor() ERC20("DataRewardToken", "DRT") {
        _mint(msg.sender, 3_000_000 * 10 ** decimals());
    }

    function rewardUser(address user, uint256 amount) external onlyOwner {
        _transfer(owner(), user, amount * 10 ** decimals());
    }
}
