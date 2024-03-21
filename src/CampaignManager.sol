// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ICampaignManager }   from "./interfaces/ICampaignManager.sol";
import { IWithdrawalManager } from "./interfaces/IWithdrawalManager.sol";
import { IVotingManager }     from "./interfaces/IVotingManager.sol";
import { IRewardManager }     from "./interfaces/IRewardManager.sol";

contract CampaignManager is ICampaignManager {

    enum Status { STARTED, SUCCESS, STOPPED }

    struct Campaign {
        bool    campaignSuccessful; //  Flag indicating if the campaign was successful
        address campaignAdmin;      //  Address of the campaign administrator
        bytes32 details;            //  Details of the campaign
        bytes32 updates;            //  Updates posted for the campaign
        uint    startTime;          //  Start time of the campaign
        uint    deadline;           //  Deadline of the campaign
        uint    goal;               //  Funding goal of the campaign
        uint    totalFunding;       //  Total funds raised for the campaign
        Status  status;             //  Status of the campaign
        mapping(address => uint) contributions; //  Mapping of contributor addresses to their contributions
    }

    Campaign public campaign;

    uint256 internal _locked;

    address public WithdrawalManager;
    address public VotingManager;
    address public RewardManager;

    mapping(address => uint) public pendingRefunds;

    modifier onlyAdmin() {
        require(msg.sender == campaign.campaignAdmin, "Unauthorized");
        _;
    }

    modifier nonReentrant() {
        require(_locked == 1, "Reentrant");

        _locked = 2;
        _;

        _locked = 1;
    }

    constructor() {
        _locked = 1;
        campaign.campaignAdmin = msg.sender;
    }

    /**************************************************************************************************************************************/
    /*** Administrative Functions                                                                                                       ***/
    /**************************************************************************************************************************************/

    function startCampaign(bytes32 _details, uint _goal, uint _deadline) external override onlyAdmin {
        require(_deadline > block.timestamp, "Invalid deadline");

        campaign.details = _details;
        campaign.goal = _goal;
        campaign.startTime = block.timestamp;
        campaign.deadline = _deadline;
        campaign.status = Status(0);

        emit CampaignStarted(_details, _goal, _deadline);
    }

    function setGoal(uint _goal) external override onlyAdmin {
        emit GoalSet(campaign.goal, _goal);

        campaign.goal = _goal;
    }

    function setDeadline(uint _deadline) external override onlyAdmin {
        emit DeadlineSet(campaign.deadline, _deadline);

        campaign.deadline = _deadline;
    }

    function postUpdates(bytes32 _updates) external override onlyAdmin {
        campaign.updates = _updates;
    }

    function setCampaignStatus(uint8 _status) external override onlyAdmin {
        require(_status >= 0 && _status <= 2, "Invalid status");

        campaign.status = Status(_status);
    }

    function setWithdrawalManager(address _wm) external  override onlyAdmin {
        WithdrawalManager = _wm;
    }

    function setVotingManager(address _vm) external override onlyAdmin {
        VotingManager = _vm;
    }

    function setRewardManager(address _rm) external override onlyAdmin {
        RewardManager = _rm;
    }

    function claim(address receiver, uint amount) external override onlyAdmin nonReentrant {
        require(amount > 0 && 
                amount <= IWithdrawalManager(WithdrawalManager).getInstallmentAmount(), "Invalid amount");
        require(!(IVotingManager(VotingManager).getVotingResult()), "Voting passed");
        require(IWithdrawalManager(WithdrawalManager).isValidClaimWindow(), "Not in claim window");
        require(amount <= address(this).balance, "Insufficient balance");

        payable(receiver).transfer(amount);

        emit FundsClaimed(receiver, amount);
    } 

    /**************************************************************************************************************************************/
    /*** Contributor Functions                                                                                                          ***/
    /**************************************************************************************************************************************/

    function donate() nonReentrant external payable {
        uint256 funds = msg.value;

        require(funds > 0, "Zero amount");
        require(campaign.totalFunding < campaign.goal, "Goal met");
        require(campaign.status != Status(2), "Campaign Stopped");
        require(
            block.timestamp >= campaign.startTime && 
            block.timestamp < campaign.deadline, 
            "Campaign deadline passed");
        
        campaign.contributions[msg.sender] += funds;
        campaign.totalFunding += funds;

        emit DonationReceived(msg.sender, funds);
    }

    function requestRefund() external override nonReentrant {
        require(campaign.status == Status(2), "Campaign hasn't stopped");
        require(IVotingManager(VotingManager).getVotingResult(), "Voting did not pass");

        uint _contribution = campaign.contributions[msg.sender];

        require(_contribution > 0, "No contribution");

        uint _refundAmount = calculateRefund(_contribution);

        pendingRefunds[msg.sender] += _refundAmount;

        emit RefundRequested(msg.sender, _refundAmount);
    }

    function refund() external override nonReentrant {
        uint amount = pendingRefunds[msg.sender];
       
        pendingRefunds[msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit Refunded(msg.sender, amount);
    }

    function redeemReward() external override nonReentrant {
        uint amount = getContributorBalance(msg.sender);

        IRewardManager(RewardManager).redeem(msg.sender, amount);
    }

    /**************************************************************************************************************************************/
    /*** View Functions                                                                                                                 ***/
    /**************************************************************************************************************************************/

    function getCampaignManager() external view override returns(address _manager) {
        _manager = campaign.campaignAdmin;
    }

    function getDetails() external view override returns(bytes32 _details) {
        _details = campaign.details;
    }

    function getUpdates() external view override returns(bytes32 _updates) {
        _updates = campaign.updates;
    }

    function getGoal() external view override returns(uint _goal) {
        _goal = campaign.goal;
    }

    function getDeadline() external view override returns(uint _deadline) {
        _deadline = campaign.deadline;
    }

    function getCampaignBalance() public view override returns(uint _balance) {
        _balance = campaign.totalFunding;
    }

    function getCampaignStatus() external view override returns(uint8 _status) {
        _status = uint8(campaign.status);
    }

    function getContributorBalance(address _contributor) public view override returns(uint _contribution) {
        _contribution = campaign.contributions[_contributor];
    }

    /**************************************************************************************************************************************/
    /*** Internal Functions                                                                                                             ***/
    /**************************************************************************************************************************************/

    function calculateRefund(uint contribution) internal view returns(uint _refund) {
        uint _balance = address(this).balance;

        require(_balance > 0, "Insufficient balance");

        uint256 proportion = (contribution * 1e18) / getCampaignBalance();
        _refund = (_balance * proportion) / 1e18;
    }

}