# Crowdfunding System Design

## 1. Introduction
The Crowdfunding Solution aims to provide a platform for project managers to raise capital from diverse sources through crowdfunding. This system allows project managers to start campaigns, set goals and deadlines, offer rewards, post updates and claim donations. Contributors can donate to campaigns, vote, receive rewards, and get refunds if the goals are not met or if a vote of no confidence is passed.

## 2. High-Level Architecture
The system is designed to be secure, gas-efficient, reliable and modular with scalability in mind, ensuring efficient use of blockchain resources. It consists of several modules including Campaign Manager, Withdrawal Manager(refund and claim), Voting Manager, Reward Manager, and Permission Manager. These modules interact with each other to facilitate campaign creation, management, funding, reward distribution, and voting processes.

![crowdfunding](https://github.com/Trust-Machines-Interview/Preethi-smart-contracts-interview/assets/26243138/74ba3621-4286-4f8e-8012-09a51c7c05e7)


### 2.1 Overview
Each module will be implemented as a separate smart contract following the Factory Pattern for creating upgradeable instances which makes it easier to efficiently deploy, track, and reduce gas fees. Factories are managed in an allowlist in the Permission Manager, maintained by the Admins. This allows contracts to verify on-chain that contracts have been vetted by the Campaign DAO avoiding malicious campaigns being created and donations being made to malicious campaigns. 
 
#### 2.1.1 Campaign Manager

This contract will act as an interface/router and the actors only need to interact with this interface to participate in the campaign. It includes all the administrative functions for campaign admins to start a campaign, set goals, deadlines, edit, set voting parameters and other functions to donate, vote, request refund and redeem rewards.

#### 2.1.2 Withdrawal Manager
The withdrawal manager handles the calculation for distribution of funds in installments after campaign goals are met and also for refunds in case goals are not met or if a vote of no confidence is passed. This module ensures proportional refund distribution to contributors.
The withdrawal (refund/claim) is cycle-based, which means there will be multiple cycles within which there will be voting and claim windows. 

#### 2.1.3 Voting Manager
The Voting Manager module oversees the voting process in instances of a vote of no confidence, assessing whether the campaign warrants cancellation according to the voting outcome. It is responsible for managing a weighted vote based system.

#### 2.1.4 Reward Manager
Merkle proofs will be employed to manage the allocation and distribution of rewards to contributors, if the campaign goals are met. This is a scalable approach which ensures that the blockchain network is not congested and there is no need to pay the gas cost required to initialize all of those balances. The contributors can claim at their own cost upon verification.

#### 2.1.5 Permission Manager
This is a singleton contract responsible for holding system-wide parameters. The administrative actor can configure all the needed parameters in a central place. It can be used to perform upgrades, pause and allowlist.

#### 2.1.6 Campaign Deployer
The campaign deployer contract facilitates the atomic deployment, initialization, and configuration of all contracts necessary to run a campaign. It ensures seamless setup for each  crowdfunding campaign.

### 2.2. Communication Flow
Admin multisig (DAO) deploys the Permission Manager contract, all the factory contracts with the Permission Manager contract address in `constructor` and the Campaign deployer contract. Allowlisted Campaign admins/creators calls the `deployCampaign` function in the allowlisted Campaign deployer contract which automatically deploys instances (via CREATE2) of Campaign manager, withdrawal manager, voting manager, reward manager, configures and returns the Campaign manager address. The deployed instance addresses will be allowlisted by Admin multisig to make sure no malicious code has been used and there is a single campaign admin for each campaign. The users of the system - campaign admins and contributors/donors can interact with the Campaign manager interface which routes the call to respective modules. Campaign admins configure the campaign details and start the campaign. The  contributors can continue to donate until the deadline by simply calling the `donate` function by passing campaign address and amount. If the goal is met then rewards can be claimed by the contributors leveraging merkle drop. The voting cycle starts at the beginning of each installment (number of installment will be configured before the campaign starts). At the end of the voting cycle the claim/distribution window opens or refund starts depending on the voting results. The voting results will be calculated depending on the donation weight.

## 3. Detailed Components
### 3.1 Campaign Manager
The Campaign contract is the core unit that keeps track of contributor funds and transfer capabilities. It's the only necessary contract for contributors to interact with and it contains all necessary functions to donate, vote,  request refunds and claim rewards. Also for the campaign admins to start, set, edit and post campaign details, start vote, initiate refund and rewards. It contains the minimum necessary logic and allows for a high degree of flexibility for future development. 

#### 3.1.1 Administrative functions
- `setGoal(uint goal)` - set the number representing the funding goal
- `setDeadline(uint deadline)` - set the campaign deadline represented in Unix timestamp
- `setInstallment(uint cycles)` - sets the number of installment cycles
- `postUpdate(bytes update)` - Campaign updates encoded as bytes
- `setAsset(address donation, address reward)` - sets the address of donation and reward asset
- `setWithdrawalManager(address wm)` - sets the address of withdrawal manager contract instance
- `setVotingManager(address vm)` - sets the address of voting manager contract instance
- `setRewardManager(address rm)` - sets the address of reward manager contract instance
- `setRoot(bytes32 root)` - sets merkle root

- `startCampaign(bytes data)` - stores the donation details in bytes and allows donation
- `stopCampaign()` - Disallows donation
- `claim(address owner, uint amount)` - Transfers funding to campaign admin
- `startInstallmentCycle()` - Starts voting  cycle
- `stopInstallmentCycle()` - Stops voting cycle and determines the result

#### 3.1.2 Contributor functions
- `donate(address campaign, uint amount)` - Transfers specified amount to campaign
- `vote(bool vote)` 
- `redeemRewards()` - mints reward tokens 

### 3.2 Withdrawal manager
Since the entire campaign funds cannot be claimed all at once and needs to follow an installment and voting process a cycle-based approach is used. The number of cycles is nothing but the number of installments set before the start of the campaign. Each installment cycle has a voting window duration and claim window duration which will be set in the `constructor`. The voting window will be at the start of each installment cycle and the claim window will start at the end of the voting window. The cycle cannot be started when the campaign goal is not met.

The cycle starts when the campaign admin  calls the `startInstallmentCycle` function.The next cycle starts at the end of the previous claim window and the cycles continue until the last installment cycle or until stopped. When the voting is passed the cycle will be stopped by calling `stopInstallmentCycle`. 

![withdraw](https://github.com/Trust-Machines-Interview/Preethi-smart-contracts-interview/assets/26243138/e945dc9a-d3f6-40be-a3e7-fc1ea441f7a7)


If the amount is not fully claimed in the claim window it will be rolled over to the next cycle claim window and if in that cycle, vote has been passed then the amount cannot be claimed and it will be part of the refund to contributors. The contributors can request for a refund when the vote has been passed. When the `requestRefund` function is called the current available amount in the campaign will be distributed proportionally. This withdrawal method would eliminate the need for running loops over a huge list of contributors. 

For example,
Five contributors donated different amounts totaling 100 tokens, from which 25% have been claimed in the first installment cycle. In the second cycle vote has been passed and refund has been requested. After spending 25%, we will be left with 75% which is 75 tokens.

Now, to find out each member’s initial contribution proportion,
Member 1’s proportion = (Member 1’s initial donation) / (Total initial donation)
Member 2’s proportion = (Member 2’s initial donation) / (Total initial donation)

If Member 1’s initial contribution was 20 tokens and Member 2’s was 30 tokens their proportion would be:
Member 1’s proportion = 20/100 = 0.2
Member 2’s proportion = 30/100 = 0.3

So, Member 1 would withdraw 0.2 * 75 = 15 and Member 2 would withdraw 0.3 * 75 = 22.

In case, the campaign deadline is not met the contributors can call requestRefund and the full amount can be withdrawn. Also, in case a vote is passed the campaign stops, installment cycles will stop and cannot be started again.

### 3.3 Voting Manager
Enabling donors to initiate a vote of no-confidence prior to the release of funds empowers donors to express discontent with the campaign’s direction or execution, potentially resulting in its cancellation and the refunding of remaining funds. Two design choices:
Simple majority vote: In this approach, each donor’s vote carries equal weight irrespective of their contribution amount. While straightforward to implement and perceived as fair, it may inadequately represent overall sentiment.
Weight vote based on donation proportions: In this approach, each donor’s voting power aligns with their contribution to the campaign. This ensures that larger contributors exert more influence, potentially better reflecting their vested interest in the campaign’s success. The implementation is complex as it necessitates tracking donation amounts and computing voting weights accordingly.

To implement weighted voting based on token donations, the campaign owner after posting updates will start the installment cycle with a proposal via startInstallmentCycle which opens up the voting window. The contributors can vote either ‘yes’ or ’no’ where weight of each vote is based on their donation amount. 

```
// Calculate voting weight based on token donation
uint votingWeight = (voters[msg.sender].tokensDonated * 100) / tokensDonated;`

// Record the vote with weighted count
voters[msg.sender].hasVoted = true;
If (choice) {
yesVotes += votingWeight;
} else {
noVotes += votingWeight;
} 
```

Once the voting deadline is reached and all the votes have been casted campaign owner calls stopInstallmentCycle which closes the voting window and determines the outcome. If the weighted count of ‘yes’ exceeds ‘no’ the proposal is considered passed.

In the next iteration, Permit based voting through signatures can be developed which allows token holders to authorize others to vote on their behalf using signed messages, reducing gas costs and simplifying the voting process.

### 3.4 Reward Manager
Once the campaign funding goal is met, reward distribution starts. Instead of directly transferring reward tokens to the contributors by paying gas to initialize all those balances and spamming the blockchain with thousands of transactions, Merkle drop mechanism can be used. 

Merkle proofs are a way to provide proof that a certain value is part of a set of data without the need of exposing the complete set of data. In the Merkle drop, a merkle proof that a wallet address is included within the merkle root needs to be provided to the merkle drop contract in order for the eligible person to claim the allocated token.

Let’s say the number of reward tokens is equal to the number of donation tokens. Off-Chain a file is constructed with the mapping of contributor address to reward token balances. Merkle tree is built with the contents of this file using `merklejs`. Now the root is fetched from the constructed tree via `merkletree.getHexRoot()` and a proof is generated for each set of address and balance for verification. On verification the tokens for the assigned amount will be initialized for donors to claim/mint. This proof is a route to the address/balance pair in the merkle tree.

The campaign admin will set the merkle root in reward manager contract via `setRoot` function. The contributors can call the `claim` function. In the background, the wallet address and reward balance will be fetched and a merkle proof is generated. The reward manager will verify if this proof is part of the merkle tree. If the verification is successful the tokens can be claimed/minted and a mapping will be updated that the tokens were claimed successfully.

### 3.5 Permission Manager
This contract will be used by admin multisig to set system wide parameters that the campaigns must abide by and controls instance deployment and pause features.

#### 3.5.1 Functions:
setCampaignAdmin(address admin) - set/allow campaign admin
setContractPause(address campaign, bool pause) - pause/unpause campaigns
setValidInstance(address campaign, bool isValid) - Sets valid campaign instance
setValidDeployer(address deployer) - sets valid campaign deployer

### 3.6 Campaign Deployer
The `deployCampaign` function in this contract handles the deployment of contract instances from valid factories.

```
deployCampaign(
        address campaignManagerFactory,
        address withdrawalManagerFactory,
        address rewardManagerFactory,
        address votingManagerFactory,
        address donationAsset,
        address rewardAsset,
        uint deadline,
        uint goal,
        bytes details,
        string memory name_
    )
```


