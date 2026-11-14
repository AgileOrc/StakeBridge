// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./mocks/MockERC20.sol";

contract StakingPool {
    MockERC20 public stakingToken;
    MockERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public totalStaked;
    address public owner;

    mapping(address => uint256) public stakeBalance;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public lastUpdateTime;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event RewardDeposited(address indexed sender, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event EmergencyWithdrawn(address indexed owner, uint256 amount);

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) {
        // simpan alamat token dan rewardRate

        stakingToken = MockERC20(_stakingToken);
        rewardToken = MockERC20(_rewardToken);
        rewardRate = _rewardRate;
        owner = msg.sender;
    }

    // 1. Staking & user function
    function stake(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");

        rewardDebt[msg.sender] = calculateReward(msg.sender);
        lastUpdateTime[msg.sender] = block.timestamp;

        stakeBalance[msg.sender] += amount;
        totalStaked += amount;

        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        emit Staked(msg.sender, amount);
    }

    // VULN-3: SC04:2025 Lack of Input Validation (Integer Underflow)
    // Celah: Tidak memvalidasi apakah amount <= stakeBalance[msg.sender].
    // Digunakan blok unchecked agar pada Solidity 0.8 tidak revert, melainkan mengalami underflow
    function withdrawStake(uint256 amount) external {
        rewardDebt[msg.sender] = calculateReward(msg.sender);
        lastUpdateTime[msg.sender] = block.timestamp;

        unchecked {
            stakeBalance[msg.sender] -= amount;
            totalStaked -= amount;
        }

        require(stakingToken.transfer(msg.sender, amount), "Transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    function claimReward() external {
        uint256 reward = calculateReward(msg.sender);
        require(reward > 0, "No reward to claim");

        rewardDebt[msg.sender] = 0;
        lastUpdateTime[msg.sender] = block.timestamp;

        require(rewardToken.balanceOf(address(this)) >= reward, "Insufficient reward in pool");
        require(rewardToken.transfer(msg.sender, reward), "Reward transfer failed");
        emit RewardClaimed(msg.sender, reward);
    }

    // 2. Administrative & vulnerability functions
    // VULN-1: SC01:2025 Access Control Vulnerabilities
    // Celah: Tidak ada pengecekan onlyOwner. Siapa pun dapat mengganti owner kontrak.
    function changeOwner(address newOwner) external {
        require(newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // VULN-2: SC01:2025 Access Control Vulnerabilities
    // Celah: Tidak ada pengecekan onlyOwner. Siapa pun dapat memanipulasi rewardRate menjadi sangat besar/kecil.
    function setRewardRate(uint256 _newRate) external {
        rewardRate = _newRate;
        emit RewardRateUpdated(_newRate);
    }

    function emergencyWithdraw() external {
        require(msg.sender == owner, "Only owner can call emergency withdraw");
        uint256 balance = stakingToken.balanceOf(address(this));
        require(stakingToken.transfer(owner, balance), "Transfer failed");
        emit EmergencyWithdrawn(owner, balance);
    }

    function depositReward(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(rewardToken.transferFrom(msg.sender, address(this), amount), "Deposit failed");
        emit RewardDeposited(msg.sender, amount);
    }

    // 3. View functions
    function getStakeBalance(address account) external view returns (uint256) {
        return stakeBalance[account];
    }

    function calculateReward(address account) public view returns (uint256) {
        if (stakeBalance[account] == 0) {
            return rewardDebt[account];
        }
        uint256 timeElapsed = block.timestamp - lastUpdateTime[account];
        uint256 accrued = (stakeBalance[account] * rewardRate * timeElapsed) / 1e18;
        return rewardDebt[account] + accrued;
    }
}
