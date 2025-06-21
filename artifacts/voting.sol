// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.0/contracts/token/ERC20/ERC20.sol";
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.0/contracts/access/Ownable.sol";


contract DAOGovernance is Ownable {
    IERC20 public governanceToken;
    uint256 public proposalCount;
    uint256 public quorumPercent = 20; // % of total supply required to reach quorum
    uint256 public votingDuration = 6 days;

    enum ProposalStatus { Active, Executed, Rejected }

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 deadline;
        ProposalStatus status;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => Proposal) public proposals;

    event ProposalCreated(uint256 indexed id, address indexed proposer, string description, uint256 deadline);
    event Voted(uint256 indexed id, address indexed voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed id);
    event ProposalRejected(uint256 indexed id);

    constructor(address _governanceToken) {
        governanceToken = IERC20(_governanceToken);
    }

    modifier onlyTokenHolders() {
        require(governanceToken.balanceOf(msg.sender) > 0, "Only token holders can vote");
        _;
    }

    function createProposal(string calldata _description) external onlyTokenHolders {
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.description = _description;
        p.deadline = block.timestamp + votingDuration;
        p.status = ProposalStatus.Active;

        emit ProposalCreated(p.id, msg.sender, _description, p.deadline);
    }

    function vote(uint256 _proposalId, bool support) external onlyTokenHolders {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp <= p.deadline, "Voting ended");
        require(p.status == ProposalStatus.Active, "Not active");
        require(!p.hasVoted[msg.sender], "Already voted");

        uint256 weight = governanceToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        p.hasVoted[msg.sender] = true;

        if (support) {
            p.votesFor += weight;
        } else {
            p.votesAgainst += weight;
        }

        emit Voted(_proposalId, msg.sender, support, weight);
    }

    function executeProposal(uint256 _proposalId) external {
        Proposal storage p = proposals[_proposalId];
        require(block.timestamp > p.deadline, "Voting not ended");
        require(p.status == ProposalStatus.Active, "Not executable");

        uint256 totalVotes = p.votesFor + p.votesAgainst;
        uint256 totalSupply = governanceToken.totalSupply();
        uint256 quorumVotes = (quorumPercent * totalSupply) / 100;

        if (totalVotes >= quorumVotes && p.votesFor > p.votesAgainst) {
            p.status = ProposalStatus.Executed;
            emit ProposalExecuted(_proposalId);
            // logic to take action based on proposal description
        } else {
            p.status = ProposalStatus.Rejected;
            emit ProposalRejected(_proposalId);
        }
    }

    // Admin functions
    function updateQuorum(uint256 _percent) external onlyOwner {
        require(_percent <= 100, "Invalid quorum");
        quorumPercent = _percent;
    }

    function updateVotingDuration(uint256 _duration) external onlyOwner {
        votingDuration = _duration;
    }
}
