// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {TestBase} from "./TestBase.t.sol";

contract WithdrawalManagerTest is TestBase {

    function setUp() public override {
        super.setUp();
    }

    function test_startInstallmentCycle_notAdmin() external {
        vm.expectRevert("Unauthorized");
        withdrawalManager.startInstallmentCycle();
    }

    function test_startInstallmentCycle_campaignUnsuccessful() external {
        vm.expectRevert("Campaign not successful");
        vm.prank(campaignAdmin);
        withdrawalManager.startInstallmentCycle();
    }

    function test_startInstallmentCycle_cyclesEnded() external {
        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();
        withdrawalManager.startInstallmentCycle();
        vm.stopPrank();

        // Installment cycles = 2
        // Revert on starting third cycle
        vm.expectRevert("Installment cycle ended");
        vm.prank(campaignAdmin);
        withdrawalManager.startInstallmentCycle();
    }

    function test_startInstallmentCycle_success() external {
        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();
        vm.stopPrank();

        (,uint _votingWindowDuration, uint _claimWindowDuration, ) = withdrawalManager.cycleConfigs();

        assertEq(withdrawalManager.currentInstallmentCycle(), uint(1));
        assertEq(withdrawalManager.getVotingWindow(), block.timestamp + _votingWindowDuration);
        assertEq(withdrawalManager.getClaimWindow(), block.timestamp + _votingWindowDuration + _claimWindowDuration);
    }

    function test_getVotingWindow() external {
        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();
        vm.stopPrank();

        (,uint _votingWindowDuration, , ) = withdrawalManager.cycleConfigs();
        assertEq(withdrawalManager.getVotingWindow(), block.timestamp + _votingWindowDuration);
    }

    function test_getClaimWindow() external {
        vm.startPrank(campaignAdmin);
        campaignManager.setCampaignStatus(1);
        withdrawalManager.startInstallmentCycle();
        vm.stopPrank();

        (,uint _votingWindowDuration ,uint _claimWindowDuration , ) = withdrawalManager.cycleConfigs();
        assertEq(withdrawalManager.getClaimWindow(), block.timestamp + _votingWindowDuration + _claimWindowDuration);
    }

}