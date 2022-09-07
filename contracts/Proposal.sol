// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Proposal is Ownable{

    uint32 public allocatorCount;
    uint256 public amountIncentive = 5 * 1e17;
    address payable qbWallet;

    mapping (address => proposalData) internal proposal;
    mapping (address => bool) internal addAllocator;
    mapping(address => uint256) internal addEvaluator;
    mapping (address => mapping( uint32 => milestoneData)) public milestone;
    mapping (address => rewards) public rewardSetting;
    mapping (address => uint32) internal milestoneRecord;

    struct proposalData {
        string title;
        string description;
        string content;
    }

    struct milestoneData {
        string milestone;
        bool status;
        uint timestamp;
    }

    struct rewards{
        uint96 allocators;
        uint96 propStream;
        uint96 evaluators;
    }

    event ProposalCreated(address indexed creator, string title, string description);
    event rewardsCreated(uint96 allocators, uint96 propStream, uint96 evaluators);

    modifier onlyAllocators(){
        require(addAllocator[msg.sender], "Not an Allocator");
        _;
    }

    modifier onlyEvaluators(){
        require(addEvaluator[msg.sender] == 0, "Not an Evaluator");
        _;
    }

    constructor(
        address payable _walletAddress,
        string memory _title, 
        string memory _description, 
        string memory _content, 
        uint96 _allocators, 
        uint96 _propStream,
        uint96 _evaluators)
         {
        qbWallet = _walletAddress;
        proposal[msg.sender] = proposalData(_title, _description, _content);
        rewardSetting[address(this)] = rewards(_allocators, _propStream, _evaluators);
        emit rewardsCreated(_allocators, _propStream, _evaluators);
        emit ProposalCreated(msg.sender, _title, _description);
    }

    // function checkAllocatorCredential(string _username)
    //     public 
    //     {
    //         // require(gateableFacet.has_credential(address(this)));
    //     }

    function editRewardSetting(
        uint32 _allocators, 
        uint32 _propStream, 
        uint32 _evaluators)
        public 
        {
            rewardSetting[address(this)] = rewards(_allocators, _propStream, _evaluators);
        }

    function getRewardSetting() public view returns (rewards memory){
        return rewardSetting[address(this)];
    }

    function addAllocators(address _allocator)
        public
        {
            require(_allocator != address(0), "Allocator cannot be the null address");
            require(!addAllocator[_allocator], "Allocator already added");
            addAllocator[_allocator] = true;
            allocatorCount++;
        }

    function addEvaluators(address _evaluator) 
        public
        {
            require(_evaluator != address(0), "Allocator cannot be the null address");
            require(addEvaluator[_evaluator] == 0, "Evaluator already added"); 
             addEvaluator[_evaluator] = block.timestamp;
        }
          
    function calculateEvaluatorReward(address _evaluator)
        public
        view
        returns (uint256)
        {
            require(_evaluator != address(0), "Allocator cannot be the null address");
            require(addEvaluator[_evaluator] != 0, "Evaluator has not been added"); 

            uint256 hoursWorked = (block.timestamp - addEvaluator[_evaluator])/60;
            return hoursWorked * (address(this).balance/rewardSetting[address(this)].evaluators);
        }

    function calculateAllocatorReward()
        public
        view
        returns(uint256, uint256){
            uint256 allocatorsReward = (address(this).balance/ 100) * rewardSetting[address(this)].allocators;
            uint256 perAllocator = allocatorsReward/allocatorCount;
        return (allocatorsReward, perAllocator);
        }

    function setMilestones(string memory _milestone)
        public {
        uint32 milestoneId = milestoneRecord[msg.sender];
        milestone[msg.sender][milestoneId] = milestoneData(_milestone, false, block.timestamp);
        milestoneRecord[msg.sender] = milestoneId++;
        }
    
    function approveMilestone(uint16 _milestoneId)
        public 
        onlyEvaluators()
        { //TO-DO: Only evaluator assigned to Milestone can approve milestone
            milestone[msg.sender][_milestoneId].status = true;
        }

    function sendReward(address payable _receiver, uint16 _milestoneId)
        public 
        onlyAllocators()
        {
            //TO-DO: Only evaluator assigned to Milestone can approve milestone
            if(milestone[msg.sender][_milestoneId].status){
                amountIncentive = 5 * 1e17 * 2;
            }else {
                amountIncentive = amountIncentive - 5 * 1e17;
            }
            _receiver.transfer(amountIncentive);
        }
    
    receive() external payable{
        uint256 platformFee = msg.value * rewardSetting[address(this)].propStream;
        qbWallet.transfer(platformFee);
    }
}