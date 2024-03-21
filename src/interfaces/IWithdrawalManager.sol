// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWithdrawalManager {

    // Emitted when installment cycle starts.
    event InstallmentCycleStarted(uint256 startTime, uint64 cycle);

    // @dev Starts a new installment cycle.
    function startInstallmentCycle() external;

    // @dev Returns the duration of the voting window.
    function getVotingWindow() external view returns(uint256 _votingWindow);

    // @dev Returns the duration of the claim window.
    function getClaimWindow() external view returns(uint256 _claimWindow);

    // @dev Returns the claim amount in each installment.
    function getInstallmentAmount() external view returns(uint256 _installmentAmount);
    
    // @dev Checks if the current time falls within the voting window.
    function isValidVotingWindow() external view returns(bool isValid);

    // @dev Checks if the current time falls within the claim window.
    function isValidClaimWindow() external view returns(bool isValid);
}