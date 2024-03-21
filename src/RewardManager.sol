// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICampaignManager } from "./interfaces/ICampaignManager.sol";
import { IRewardManager }   from "./interfaces/IRewardManager.sol";

import { ERC20 } from "./ERC20.sol";

contract RewardManager is IRewardManager, ERC20 {

    address public campaignManager;

    mapping (address => bool) public withdrawn;

    constructor(address _campaignManager) {
        campaignManager = _campaignManager;
    }

    function redeem(address receiver, uint256 amount) external override {
        require(ICampaignManager(campaignManager).getCampaignStatus() == 1, "Campaign not successful");
        require(ICampaignManager(campaignManager).getContributorBalance(receiver) > 0, "No contribution");
        require(! withdrawn[receiver], "Already redeemed");

        withdrawn[receiver] = true;
        _mint(receiver, amount);

        emit RedeemSuccessful(receiver, amount);
    }

}