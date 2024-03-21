// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICampaignManager {

    // Emitted when a campaign is started.
    event CampaignStarted(bytes32 _details, uint _goal, uint _deadline);

    // Emitted when the campaign goal is set.
    event GoalSet(uint256 _previousGoal, uint256 _currentGoal);

    // Emitted when the campaign deadline is set.
    event DeadlineSet(uint256 _previousDeadline, uint256 _currentDeadline);

    // Emitted when a donation is received by contributors.
    event DonationReceived(address _contributor, uint amount);

    // Emitted when funds are claimed by campaign admin.
    event FundsClaimed(address _receiver, uint amount);

    // Emitted when a refund is requested by contributor.
    event RefundRequested(address _receiver, uint amount);

    // Emitted when a refund is successful.
    event Refunded(address _receiver, uint amount);

    /**
     * @dev   Sets campaign details.
     * @param _details  Details of the campaign.
     * @param _goal     Funding goal of the campaign.
     * @param _deadline Deadline of the campaign.
     */
    function startCampaign(bytes32 _details, uint _goal, uint _deadline) external;

    /**
     * @dev   Sets the campaign goal.
     * @param _goal New funding goal.
     */
    function setGoal(uint _goal) external;

    /**
     * @dev   Sets the campaign deadline.
     * @param _deadline New deadline.
     */
    function setDeadline(uint _deadline) external;

    /**
     * @dev   Posts updates about the campaign.
     * @param _updates Updates to be posted.
     */
    function postUpdates(bytes32 _updates) external;

    /**
     * @dev   Sets the campaign status.
     * @param _status New status of the campaign.
     */
    function setCampaignStatus(uint8 _status) external;

    /**
     * @dev   Sets the withdrawal manager address.
     * @param _wm Address of the withdrawal manager.
     */
    function setWithdrawalManager(address _wm) external;

    /**
     * @dev   Sets the voting manager address.
     * @param _vm Address of the voting manager.
     */
    function setVotingManager(address _vm) external;

    /**
     * @dev   Sets the reward manager address.
     * @param _rm Address of the reward manager.
     */
    function setRewardManager(address _rm) external;

    /**
     * @dev   Claims funds for a receiver.
     * @param receiver Address of the receiver.
     * @param amount   Amount to be claimed.
     */
    function claim(address receiver, uint amount) external;

    // @dev Contributors can request a refund.
    function requestRefund() external;

    // @dev Refunds funds to contributors.
    function refund() external;

    // @dev Redeems rewards to contributors.
    function redeemReward() external;

    /**
     * @dev   Gets the address of the campaign manager.
     * @return _manager Address of the campaign manager.
     */
    function getCampaignManager() external view returns(address _manager);

    // @dev Gets the campaign details.
    function getDetails() external view returns(bytes32 _details);

    // @dev Gets the campaign goal.
    function getGoal() external view returns(uint _goal);

    // @dev Gets the campaign deadline.
    function getDeadline() external view returns(uint _deadline);

    // @dev Gets updates about the campaign.
    function getUpdates() external view returns(bytes32 _updates);

    // @dev Gets the campaign funding balance.
    function getCampaignBalance() external view returns(uint _balance);

    // @dev Gets the campaign status.
    function getCampaignStatus() external view returns(uint8 _status);

    /**
     * @dev    Gets the balance contributed by a specific contributor.
     * @param  _contributor  Address of the contributor.
     * @return _contribution Balance contributed by the contributor.
     */
    function getContributorBalance(address _contributor) external view returns(uint _contribution);
}