// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title Decentralized Voting System
 * @dev A transparent and secure voting system on the blockchain
 * @author Your Name
 */
contract Project {
    
    // Struct to represent a candidate
    struct Candidate {
        uint256 id;
        string name;
        uint256 voteCount;
        bool exists;
    }
    
    // Struct to represent a voting session
    struct VotingSession {
        string title;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 totalVotes;
    }
    
    // State variables
    address public owner;
    VotingSession public currentSession;
    uint256 public candidateCount;
    
    // Mappings
    mapping(uint256 => Candidate) public candidates;
    mapping(address => bool) public hasVoted;
    mapping(address => bool) public authorizedVoters;
    
    // Events
    event VotingSessionCreated(string title, uint256 startTime, uint256 endTime);
    event CandidateAdded(uint256 candidateId, string name);
    event VoteCasted(address voter, uint256 candidateId);
    event VoterAuthorized(address voter);
    event VotingSessionEnded(string title, uint256 totalVotes);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyAuthorizedVoter() {
        require(authorizedVoters[msg.sender], "You are not authorized to vote");
        _;
    }
    
    modifier votingActive() {
        require(currentSession.isActive, "No active voting session");
        require(block.timestamp >= currentSession.startTime, "Voting has not started yet");
        require(block.timestamp <= currentSession.endTime, "Voting has ended");
        _;
    }
    
    modifier hasNotVoted() {
        require(!hasVoted[msg.sender], "You have already voted");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        candidateCount = 0;
    }
    
    /**
     * @dev Core Function 1: Create a new voting session with candidates
     * @param _title Title of the voting session
     * @param _duration Duration of voting in seconds
     * @param _candidateNames Array of candidate names
     */
    function createVotingSession(
        string memory _title,
        uint256 _duration,
        string[] memory _candidateNames
    ) public onlyOwner {
        require(!currentSession.isActive, "A voting session is already active");
        require(_candidateNames.length > 1, "At least 2 candidates required");
        require(_duration > 0, "Duration must be greater than 0");
        
        // Reset previous session data
        _resetVotingData();
        
        // Set up new voting session
        currentSession = VotingSession({
            title: _title,
            startTime: block.timestamp,
            endTime: block.timestamp + _duration,
            isActive: true,
            totalVotes: 0
        });
        
        // Add candidates
        for (uint256 i = 0; i < _candidateNames.length; i++) {
            candidateCount++;
            candidates[candidateCount] = Candidate({
                id: candidateCount,
                name: _candidateNames[i],
                voteCount: 0,
                exists: true
            });
            emit CandidateAdded(candidateCount, _candidateNames[i]);
        }
        
        emit VotingSessionCreated(_title, currentSession.startTime, currentSession.endTime);
    }
    
    /**
     * @dev Core Function 2: Cast a vote for a candidate
     * @param _candidateId ID of the candidate to vote for
     */
    function castVote(uint256 _candidateId) public 
        onlyAuthorizedVoter 
        votingActive 
        hasNotVoted 
    {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        require(candidates[_candidateId].exists, "Candidate does not exist");
        
        // Record the vote
        candidates[_candidateId].voteCount++;
        hasVoted[msg.sender] = true;
        currentSession.totalVotes++;
        
        emit VoteCasted(msg.sender, _candidateId);
    }
    
    /**
     * @dev Core Function 3: Get voting results and end session
     * @return winnerName Name of the winning candidate
     * @return winnerVotes Number of votes received by winner
     * @return totalVotes Total votes cast in the session
     */
    function getResultsAndEndSession() public onlyOwner returns (
        string memory winnerName,
        uint256 winnerVotes,
        uint256 totalVotes
    ) {
        require(currentSession.isActive, "No active voting session");
        require(block.timestamp > currentSession.endTime, "Voting is still ongoing");
        
        // Find winner
        uint256 winningVoteCount = 0;
        uint256 winnerId = 0;
        
        for (uint256 i = 1; i <= candidateCount; i++) {
            if (candidates[i].voteCount > winningVoteCount) {
                winningVoteCount = candidates[i].voteCount;
                winnerId = i;
            }
        }
        
        // End the session
        currentSession.isActive = false;
        
        emit VotingSessionEnded(currentSession.title, currentSession.totalVotes);
        
        return (
            candidates[winnerId].name,
            candidates[winnerId].voteCount,
            currentSession.totalVotes
        );
    }
    
    /**
     * @dev Authorize a voter to participate in voting
     * @param _voter Address of the voter to authorize
     */
    function authorizeVoter(address _voter) public onlyOwner {
        require(_voter != address(0), "Invalid voter address");
        authorizedVoters[_voter] = true;
        emit VoterAuthorized(_voter);
    }
    
    /**
     * @dev Authorize multiple voters at once
     * @param _voters Array of voter addresses to authorize
     */
    function authorizeMultipleVoters(address[] memory _voters) public onlyOwner {
        for (uint256 i = 0; i < _voters.length; i++) {
            require(_voters[i] != address(0), "Invalid voter address");
            authorizedVoters[_voters[i]] = true;
            emit VoterAuthorized(_voters[i]);
        }
    }
    
    /**
     * @dev Get candidate information
     * @param _candidateId ID of the candidate
     * @return id Candidate ID
     * @return name Candidate name
     * @return voteCount Number of votes received
     */
    function getCandidate(uint256 _candidateId) public view returns (
        uint256 id,
        string memory name,
        uint256 voteCount
    ) {
        require(_candidateId > 0 && _candidateId <= candidateCount, "Invalid candidate ID");
        Candidate memory candidate = candidates[_candidateId];
        return (candidate.id, candidate.name, candidate.voteCount);
    }
    
    /**
     * @dev Get current voting session information
     * @return title Session title
     * @return startTime Session start time
     * @return endTime Session end time
     * @return isActive Whether session is active
     * @return totalVotes Total votes cast
     */
    function getCurrentSession() public view returns (
        string memory title,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 totalVotes
    ) {
        return (
            currentSession.title,
            currentSession.startTime,
            currentSession.endTime,
            currentSession.isActive,
            currentSession.totalVotes
        );
    }
    
    /**
     * @dev Check if an address is authorized to vote
     * @param _voter Address to check
     * @return bool Whether the address is authorized
     */
    function isAuthorizedVoter(address _voter) public view returns (bool) {
        return authorizedVoters[_voter];
    }
    
    /**
     * @dev Check if an address has already voted
     * @param _voter Address to check
     * @return bool Whether the address has voted
     */
    function hasVoterVoted(address _voter) public view returns (bool) {
        return hasVoted[_voter];
    }
    
    /**
     * @dev Internal function to reset voting data for new session
     */
    function _resetVotingData() private {
        // Reset candidate data
        for (uint256 i = 1; i <= candidateCount; i++) {
            delete candidates[i];
        }
        candidateCount = 0;
        
        // Note: In a production environment, you might want to implement
        // a more gas-efficient way to reset voter data, such as using
        // a mapping with session IDs
    }
    
    /**
     * @dev Emergency function to end voting session (only owner)
     */
    function emergencyEndSession() public onlyOwner {
        require(currentSession.isActive, "No active voting session");
        currentSession.isActive = false;
        emit VotingSessionEnded(currentSession.title, currentSession.totalVotes);
    }
}
