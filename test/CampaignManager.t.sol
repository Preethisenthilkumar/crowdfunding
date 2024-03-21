// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {TestBase} from "./TestBase.t.sol";

contract CampaignManagerTest is TestBase {

    address internal contributor1 = makeAddr("contributor1");
    address internal contributor2 = makeAddr("contributor2");

    uint256 start = block.timestamp;

    event CampaignStarted(bytes32 _details, uint _goal, uint _deadline);

    function setUp() public override {
        super.setUp();
    }

    function test_startCampaign_notAdmin() external {
        vm.expectRevert("Unauthorized");
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start);
    }

    function test_startCampaign_invalidDeadline() external {
        vm.expectRevert("Invalid deadline");
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start);
    }

    function test_startCampaign_success() external {
        vm.expectEmit();
        emit CampaignStarted("crowdfunding_campaign", 5 ether, start + 1 weeks);

        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 1 weeks);

        assertEq(campaignManager.getDetails(), "crowdfunding_campaign");
        assertEq(campaignManager.getGoal(), 5 ether);
        assertEq(campaignManager.getDeadline(), start + 1 weeks);
    }

    function test_setGoal_notAdmin() external {
        vm.expectRevert("Unauthorized");
        campaignManager.setGoal(10 ether);
    }

    function test_setGoal_success() external {
        vm.prank(campaignAdmin);
        campaignManager.setGoal(10 ether);

        assertEq(campaignManager.getGoal(), 10 ether);
    }

    function test_setDeadline_notAdmin() external {
        vm.expectRevert("Unauthorized");
        campaignManager.setDeadline(start + 10 weeks);
    }

    function test_setDeadline_success() external {
        vm.prank(campaignAdmin);
        campaignManager.setDeadline(start + 10 weeks);

        assertEq(campaignManager.getDeadline(),start + 10 weeks); 
    }

    function test_postUpdates_notAdmin() external {
        vm.expectRevert("Unauthorized");
        campaignManager.postUpdates("Campaign_successful");
    }

    function test_postUpdates_success() external {
        vm.prank(campaignAdmin);
        campaignManager.postUpdates("Campaign_goal_not_met");

        assertEq(campaignManager.getUpdates(), "Campaign_goal_not_met");
    }

    function test_setCampaignStatus_notAdmin() external {
        vm.expectRevert("Unauthorized");
        campaignManager.setCampaignStatus(1);
    }

    function test_setCampaignStatus_success() external {
        vm.prank(campaignAdmin);
        campaignManager.setCampaignStatus(1);

        assertEq(campaignManager.getCampaignStatus(), uint(1));
    }

    function test_setWithdrawalManager_notAdmin() external {
        vm.expectRevert("Unauthorized");
        campaignManager.setWithdrawalManager(address(1));
    }

    function test_setWithdrawalManager_success() external {
        vm.prank(campaignAdmin);
        campaignManager.setWithdrawalManager(address(1));

        assertEq(campaignManager.WithdrawalManager(), address(1));
    }

    function test_setVotingManager_notAdmin() external {
         vm.expectRevert("Unauthorized");
        campaignManager.setVotingManager(address(1));
    }

    function test_setVotingManager_success() external {
        vm.prank(campaignAdmin);
        campaignManager.setVotingManager(address(1));

        assertEq(campaignManager.VotingManager(), address(1));
    }

    function test_setRewardManager_notAdmin() external {
         vm.expectRevert("Unauthorized");
        campaignManager.setRewardManager(address(1));
    }

    function test_setRewardManager_success() external {
        vm.prank(campaignAdmin);
        campaignManager.setRewardManager(address(1));

        assertEq(campaignManager.RewardManager(), address(1));
    }

    function test_donate_zeroAmount() external {
        vm.expectRevert("Zero amount");
        campaignManager.donate();
    }

    function test_donate_goalMet() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();

        vm.expectRevert("Goal met");
        vm.prank(contributor1);
        campaignManager.donate{value: 1 ether}();
    }

    function test_donate_campaignStopped() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        vm.prank(campaignAdmin);
        campaignManager.setCampaignStatus(2);

        vm.expectRevert("Campaign Stopped");
        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();
    }

    function test_donate_deadlinePassed() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        vm.warp(start + 10 days);

        vm.expectRevert("Campaign deadline passed");
        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();
    }

    function test_donate_success() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();

        assertEq(address(campaignManager).balance, 5 ether);
        assertEq(campaignManager.getContributorBalance(contributor1), 5 ether);
    }

    function test_requestRefund_campaignNotStopped() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 3 ether);
        campaignManager.donate{value: 2 ether}();

        vm.expectRevert("Campaign hasn't stopped");
        vm.prank(contributor1);
        campaignManager.requestRefund();
    }

    function test_requestRefund_votingNotPassed() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 3 ether);
        campaignManager.donate{value: 2 ether}();

        vm.prank(campaignAdmin);
        campaignManager.setCampaignStatus(2);

        vm.expectRevert("Voting did not pass");
        vm.prank(contributor1);
        campaignManager.requestRefund();
    }

    function test_requestRefund_nonContributor() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(2);
        votingManager.setVotingResults(true);
        vm.stopPrank();

        vm.expectRevert("No contribution");
        vm.prank(contributor1);
        campaignManager.requestRefund();
    }

    function test_requestRefund_success() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 3 ether);
        campaignManager.donate{value: 2 ether}();

        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(2);
        votingManager.setVotingResults(true);
        vm.stopPrank();

        vm.prank(contributor1);
        campaignManager.requestRefund();

        assertEq(campaignManager.pendingRefunds(contributor1), 2 ether);
    }

    function test_refund_success() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 3 ether);
        campaignManager.donate{value: 2 ether}();

        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(2);
        votingManager.setVotingResults(true);
        vm.stopPrank();

        vm.startPrank(contributor1);
        campaignManager.requestRefund();
        campaignManager.refund();
        vm.stopPrank();

        assertEq(campaignManager.pendingRefunds(contributor1), 0);
        assertEq(address(campaignManager).balance, 0);
    }

    function test_claim_notAdmin() external {
        vm.expectRevert("Unauthorized");
        campaignManager.claim(campaignAdmin, 1);
    }

    function test_claim_invalidAmount() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();

        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();

        vm.expectRevert("Invalid amount");
        campaignManager.claim(campaignAdmin, 6 ether);
        vm.stopPrank();
    }

    function test_claim_votingPassed() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();

        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();
        votingManager.setVotingResults(true);

        vm.expectRevert("Voting passed");
        campaignManager.claim(campaignAdmin, 1 ether);
        vm.stopPrank();
    }

    function test_claim_notInClaimWindow() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();

        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();
        
        vm.warp(block.timestamp + withdrawalManager.getClaimWindow() + 1 days);

        vm.expectRevert("Not in claim window");
        campaignManager.claim(campaignAdmin, 1 ether);
        vm.stopPrank();
    }

    function test_claim_success() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 5 ether, start + 10 days);

        hoax(contributor1, 6 ether);
        campaignManager.donate{value: 5 ether}();

        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();
        
        vm.warp(block.timestamp + withdrawalManager.getClaimWindow() - 1 days);
        campaignManager.claim(campaignAdmin, 1 ether);

        assertEq(campaignAdmin.balance, 1 ether);
        assertEq(address(campaignManager).balance, 4 ether);
    }

    function test_refund_afterClaim() external {
        vm.prank(campaignAdmin);
        campaignManager.startCampaign("crowdfunding_campaign", 4 ether, start + 10 days);

        hoax(contributor1, 3 ether);
        campaignManager.donate{value: 2 ether}();

        hoax(contributor2, 4 ether);
        campaignManager.donate{value: 2 ether}();

        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();
        
        vm.warp(block.timestamp + withdrawalManager.getClaimWindow() - 1 days);
        campaignManager.claim(campaignAdmin, withdrawalManager.getInstallmentAmount());

        // voting passed in second cycle 
        vm.warp(block.timestamp + withdrawalManager.getClaimWindow() + 1 days);
        withdrawalManager.startInstallmentCycle();
        votingManager.setVotingResults(true);
        campaignManager.setCampaignStatus(2);
        vm.stopPrank();

        // contributor1 requests for refund
        vm.prank(contributor1);
        campaignManager.requestRefund();

        assertEq(campaignManager.pendingRefunds(contributor1), 1 ether);
        assertEq(address(campaignManager).balance, 2 ether);

        vm.prank(contributor1);
        campaignManager.refund();

        assertEq(campaignManager.pendingRefunds(contributor1), 0);
        assertEq(address(campaignManager).balance, 1 ether);
    }

}