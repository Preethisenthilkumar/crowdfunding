// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";

import {CampaignManager} from "../src/CampaignManager.sol";
import {WithdrawalManager} from "../src/WithdrawalManager.sol";
import {VotingManager} from "../src/VotingManager.sol";
import {RewardManager} from "../src/RewardManager.sol";

contract TestBase is Test {

    address internal campaignAdmin = makeAddr("campaignAdmin");

    CampaignManager   internal campaignManager;
    WithdrawalManager internal withdrawalManager;
    VotingManager     internal votingManager;
    RewardManager     internal rewardManager;

    function setUp() public virtual {

        vm.startPrank(campaignAdmin);
        campaignManager   = new CampaignManager();
        withdrawalManager = new WithdrawalManager(address(campaignManager), 2, 1 weeks, 3 days);
        votingManager     = new VotingManager(address(campaignManager));
        rewardManager     = new RewardManager(address(campaignManager));

        campaignManager.setWithdrawalManager(address(withdrawalManager));
        campaignManager.setVotingManager(address(votingManager));
        campaignManager.setRewardManager(address(rewardManager));
        vm.stopPrank();
    }

}