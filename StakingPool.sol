// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./mocks/MockERC20.sol";

contract StakingPool {
    // state variables (stakingToken, rewardToken, rewardRate, totalStaked, mapping saldo, dll)

    MockERC20 public stakingToken;
    MockERC20 public rewardToken;
    uint256 public rewardRate;
    uint256 public totalStaked;
    address public owner;

    mapping(address => uint256) public stakeBalance;
    mapping(address => uint256) public rewardDebt;
    mapping(address => uint256) public lastUpdateTime;

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRate) {
        // simpan alamat token dan rewardRate

        //VULN-2 : SC04 Lack of Input Validation
        // jd alamat si token ga dicheck atau bisa address(0) dan rewardRate nya ga dibatasin
        stakingToken = MockERC20(_stakingToken);
        rewardToken = MockERC20(_rewardToken);
        rewardRate = _rewardRate;
        owner = msg.sender;
    }

    // 1. Lock token ke pool
    function stake(uint256 amount) external {
        // VULN-3: SC04 Lack of Input Validation
        // ga ada require(amount > 0), jd user bisa manggil stake(0) dan update lastUpdateTime

        rewardDebt[msg.sender] = calculateReward(msg.sender);
        lastUpdateTime[msg.sender] = block.timestamp;

        stakeBalance[msg.sender] += amount;
        totalStaked += amount;

        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Transfer failed");
    }

    // 2. Ambil main token 
    function withdrawStake(uint256 amount) external {
        require(amount > 0, "Amount must be > 0");
        require(stakeBalance[msg.sender] >= amount, "Not enough stake");

        rewardDebt[msg.sender] = calculateReward(msg.sender);
        lastUpdateTime[msg.sender] = block.timestamp;

        stakeBalance[msg.sender] -= amount;
        totalStaked -= amount;

        require(stakingToken.transfer(msg.sender, amount), "Tranfer failed");
    }

    
    // 3. Ambil reward tanpa ambil main token
    function claimReward() external {
        
    }

    // 4. View
    function getStakeBalance(address account) external view returns (uint256) {
        
        return stakeBalance[account];
    }

    function calculateReward(address account) public view returns (uint256) {
        
        return 0;
    }
}