// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICampaignManager } from "./interfaces/ICampaignManager.sol";
import { IVotingManager }   from "./interfaces/IVotingManager.sol";

contract VotingManager is IVotingManager {

    bool hasVotingPassed;

    address public campaignManager;

    modifier onlyAdmin() {
        require(msg.sender == ICampaignManager(campaignManager).getCampaignManager(), "Unauthorized");
        _;
    }

    constructor(address _campaignManager) {
            campaignManager = _campaignManager;
    }

    function setVotingResults(bool status) external onlyAdmin {
        hasVotingPassed = status;
    }

    function getVotingResult() external view override returns(bool) {
        return hasVotingPassed;
    }

}