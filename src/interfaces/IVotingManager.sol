// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVotingManager {

    function getVotingResult() external view returns(bool); 
}