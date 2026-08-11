//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract FreelancingPlatform{
    ////////State variable////////
    uint public constant REPUTATION = 1;
    uint256 public listingFees = 0.001 ether;
    address public owner ;
    uint256 public totalJobs;
    ////////Structs////////
    struct Job{
        address client;
        address freelancer;
        uint256 bounty;
        string title;
        string description;
        JobStatus status;
    }
 
    ////////Mapping////////
    mapping(uint256 => Job) public jobs;
    mapping(address => uint256) public reputations;
    ////////Enum////////
    enum JobStatus{
        Open,
        Completed,
        Pending,
        Cancelled,
        Taken
    }
    ////////Event////////
    
    event jobCreated(uint256 indexed jobID, address indexed client , uint256 bounty);
    event jobTaken(uint256 indexed jobID, address freelancer);
    event jobComplited(uint256 indexed jobID, address freelancer);
    ////////Errors////////
    error insufficientFunds();
    ////////Modifier////////
    modifier onlyOwner(){
        require(msg.sender == owner , "your not the owner of this contract");
        _;
    }
    ////////Functions////////
    constructor(){
        owner = msg.sender;
    }
    
    function createJob(string calldata _title, string calldata _description)external payable {
        totalJobs++;
        require(msg.value >= listingFees ,insufficientFunds());

        jobs[totalJobs] = Job({
            client: msg.sender,
            bounty: msg.value - listingFees,
            freelancer: address(0),
            title: _title ,
            description: _description ,
            status: JobStatus.Open
       });
       emit jobCreated(totalJobs, msg.sender , msg.value - listingFees);
    } 
    
    function getJobs() external view returns(Job[] memory){
        Job[] memory allJobs = new Job[](totalJobs);
        for (uint i = 1; i <= totalJobs; i++){
            allJobs[i - 1] = jobs[i];
        }
        return allJobs;
    }
     function acceptJob(uint256 _jobId)external {
        Job storage theJob = jobs[_jobId];
        require(theJob.status == JobStatus.Open , "Job is not available");
        require(msg.sender != theJob.client , "the owner cant take the Job");
        theJob.freelancer = msg.sender;
        theJob.status = JobStatus.Taken;

        emit jobTaken(_jobId , theJob.freelancer);
    }
    function completedJob(uint256 _jobId)external {
        Job storage job = jobs[_jobId];
        require(job.status == JobStatus.Taken, "the job not taken yet");
        require(msg.sender == job.client, "you are not the owner of the job");
        job.status = JobStatus.Completed;
        reputations[job.freelancer] +=REPUTATION;

        emit jobComplited(_jobId,job.freelancer);
        (bool success,)=payable(job.freelancer).call{value:job.bounty}(""); 
        require(success, "the transaction faild");
    } 
    }