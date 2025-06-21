// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.0/contracts/token/ERC20/IERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.0/contracts/access/Ownable.sol";


contract TokenStaking is Ownable {
    IERC20 public stakingToken;

    uint256 public rewardRate = 100; // 10% APR = 100 / 1000 per year
    uint256 public constant SECONDS_IN_YEAR = 365 days;
    uint256 public minStakingDuration = 7 days;

    struct StakeInfo {
        uint256 amount;
        uint256 stakedAt;
        uint256 lastClaimed;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 timestamp);
    event Unstaked(address indexed user, uint256 amount, uint256 reward, uint256 timestamp);
    event RewardClaimed(address indexed user, uint256 reward, uint256 timestamp);

    constructor(address _stakingToken) {
        stakingToken = IERC20(_stakingToken);
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake zero");

        require(stakingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        // If user already staked, calculate and add pending rewards
        if (stakes[msg.sender].amount > 0) {
            uint256 pending = calculateReward(msg.sender);
            stakes[msg.sender].amount += pending;
        }

        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].stakedAt = block.timestamp;
        stakes[msg.sender].lastClaimed = block.timestamp;

        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function unstake(uint256 _amount) external {
        require(_amount > 0, "Cannot unstake zero");
        require(stakes[msg.sender].amount >= _amount, "Not enough staked");
        require(block.timestamp >= stakes[msg.sender].stakedAt + minStakingDuration, "Staking period not yet passed");

        uint256 reward = calculateReward(msg.sender);

        stakes[msg.sender].amount -= _amount;
        stakes[msg.sender].lastClaimed = block.timestamp;

        require(stakingToken.transfer(msg.sender, _amount + reward), "Transfer failed");

        emit Unstaked(msg.sender, _amount, reward, block.timestamp);
    }

    function claimReward() external {
        require(stakes[msg.sender].amount > 0, "No stake found");

        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No reward yet");

        stakes[msg.sender].lastClaimed = block.timestamp;

        require(stakingToken.transfer(msg.sender, reward), "Reward transfer failed");

        emit RewardClaimed(msg.sender, reward, block.timestamp);
    }

    function calculateReward(address user) public view returns (uint256) {
        StakeInfo memory info = stakes[user];
        if (info.amount == 0) return 0;

        uint256 duration = block.timestamp - info.lastClaimed;
        uint256 yearlyReward = (info.amount * rewardRate) / 1000; // 10% = 100/1000
        return (yearlyReward * duration) / SECONDS_IN_YEAR;
    }

    function stakedBalance(address user) external view returns (uint256) {
        return stakes[user].amount;
    }

    // Optional: Owner can set reward rate or lock duration
    function setRewardRate(uint256 _rate) external onlyOwner {
        rewardRate = _rate;
    }

    function setMinStakingDuration(uint256 _duration) external onlyOwner {
        minStakingDuration = _duration;
    }
}
