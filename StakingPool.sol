// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./mocks/MockERC20.sol";

contract StakingPool {
    // state variables (stakingToken, rewardToken, rewardRate, totalStaked, mapping saldo, dll)

    constructor() {
        // simpan alamat token dan rewardRate
    }

    // 1. Lock token ke pool
    function stake(uint256 amount) external {
        
    }

    // 2. Ambil main token 
    function withdrawStake(uint256 amount) external {
        
    }

    // 3. Ambil reward tanpa ambil main token
    function claimReward() external {
        
    }

    // 4. View
    function getStakeBalance(address account) external view returns (uint256) {
        
        return 0;
    }

    function calculateReward(address account) public view returns (uint256) {
        
        return 0;
    }
}