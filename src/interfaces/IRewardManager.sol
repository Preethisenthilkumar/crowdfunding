// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardManager {

    // Emitted when redeem is successful.
    event RedeemSuccessful(address _receiver, uint256 amount);

    function redeem(address receiver, uint256 amount) external; 
}