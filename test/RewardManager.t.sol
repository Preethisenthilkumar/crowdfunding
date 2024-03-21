// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {TestBase} from "./TestBase.t.sol";

contract RewardManagerTest is TestBase {
    
    address internal contributor1 = makeAddr("contributor1");
    address internal contributor2 = makeAddr("contributor2");

    function setUp() public override {
        super.setUp();
        
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, block.timestamp + 1 weeks);

        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();
    }

    function test_redeem_campaignNotSuccessful() external {
        vm.expectRevert("Campaign not successful");
        rewardManager.redeem(contributor1, 1);
    }

    function test_redeem_noContribution() external {
        vm.prank(campaignAdmin);
        campaignManager.setCampaignStatus(1);

        vm.expectRevert("No contribution");
        rewardManager.redeem(contributor2, 1);
    }

    function test_redeem_alreadyRedeemed() external {
        vm.prank(campaignAdmin);
        campaignManager.setCampaignStatus(1);

        vm.startPrank(contributor1);
        campaignManager.redeemReward();

        vm.expectRevert("Already redeemed");
        campaignManager.redeemReward();
        vm.stopPrank();
    }

    function test_redeem_success() external {
        vm.prank(campaignAdmin);
        campaignManager.setCampaignStatus(1);

        vm.prank(contributor1);
        campaignManager.redeemReward();

        assertEq(rewardManager.withdrawn(contributor1), true);
        assertEq(rewardManager.balanceOf(contributor1), 5000000000000000000);
    }
    
}