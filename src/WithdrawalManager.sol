// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICampaignManager }   from "./interfaces/ICampaignManager.sol";
import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";

contract WithdrawalManager is IWithdrawalManager {

    struct CycleConfig {
        uint64 installmentCycles;    // Identifier of the installment cycle.
        uint64 votingWindowDuration; // Duration of the voting window.
        uint64 claimWindowDuration;  // Duration of the claim window.
        uint256 initialCycleTime;    // Timestamp of the start of cycle
    }
    
    CycleConfig public cycleConfigs;

    uint64 public currentInstallmentCycle;

    address public campaignManager;

    modifier onlyAdmin() {
        require(msg.sender == ICampaignManager(campaignManager).getCampaignManager(), "Unauthorized");
        _;
    }

    constructor(
        address _campaignManager,
        uint64 _installmentCycles,
        uint64 _votingWindowDuration,
        uint64 _claimWindowDuration
        ) {
            campaignManager = _campaignManager;

            cycleConfigs = CycleConfig({
            installmentCycles:    _installmentCycles,
            initialCycleTime:     0,
            votingWindowDuration: _votingWindowDuration,
            claimWindowDuration:  _claimWindowDuration
        });
    }

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function startInstallmentCycle() external override onlyAdmin {
        require(ICampaignManager(campaignManager).getCampaignStatus() == 1, "Campaign not successful");
        require(currentInstallmentCycle < cycleConfigs.installmentCycles, "Installment cycle ended");

        cycleConfigs.initialCycleTime = block.timestamp;

        ++currentInstallmentCycle;

        emit InstallmentCycleStarted(block.timestamp, currentInstallmentCycle);
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function isValidVotingWindow() public view override returns(bool isValid) {
        isValid = block.timestamp > cycleConfigs.initialCycleTime && 
                  block.timestamp <= getVotingWindow();
    }

    function isValidClaimWindow() public view override returns(bool isValid) {
        isValid = block.timestamp > getVotingWindow() &&
                  block.timestamp <= getClaimWindow();
    }

    function getVotingWindow() public view override returns(uint256 _votingWindow) {
        _votingWindow = cycleConfigs.initialCycleTime + cycleConfigs.votingWindowDuration;
    }

    function getClaimWindow() public view override returns(uint256 _claimWindow) {
        _claimWindow = getVotingWindow() + cycleConfigs.claimWindowDuration;
    }

    function getInstallmentAmount() public view override returns(uint256 _installmentAmount) {
        if(currentInstallmentCycle != cycleConfigs.installmentCycles) {
            _installmentAmount = calculateInstallmentAmount();
        } else {
            _installmentAmount = campaignManager.balance;
        }
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function calculateInstallmentAmount() internal view returns(uint _amount) {
         if(ICampaignManager(campaignManager).getCampaignBalance() > 0) {
                _amount = ICampaignManager(campaignManager).getCampaignBalance() / cycleConfigs.installmentCycles;
            }  
    }

}