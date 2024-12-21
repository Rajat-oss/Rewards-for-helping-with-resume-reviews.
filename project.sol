// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ResumeReviewRewards is ReentrancyGuard {
    struct Resume {
        address submitter;
        string resumeCID; // IPFS or decentralized storage link
        address reviewer;
        uint256 rewardAmount;
        bool reviewed;
    }

    IERC20 public rewardToken;
    uint256 private resumeCount;

    mapping(uint256 => Resume) public resumes;

    event ResumeSubmitted(uint256 resumeId, address indexed submitter, string resumeCID, uint256 rewardAmount);
    event ReviewAccepted(uint256 resumeId, address indexed reviewer, uint256 rewardAmount);
    event ReviewCompleted(uint256 resumeId, address indexed reviewer);

    constructor(address tokenAddress) {
        rewardToken = IERC20(tokenAddress);
    }

    // Submit a resume with a reward
    function submitResume(string memory resumeCID, uint256 rewardAmount) external {
        require(rewardToken.transferFrom(msg.sender, address(this), rewardAmount), "Token transfer failed");

        resumes[resumeCount] = Resume({
            submitter: msg.sender,
            resumeCID: resumeCID,
            reviewer: address(0),
            rewardAmount: rewardAmount,
            reviewed: false
        });

        emit ResumeSubmitted(resumeCount, msg.sender, resumeCID, rewardAmount);
        resumeCount++;
    }

    // Accept a resume for review
    function acceptReview(uint256 resumeId) external {
        Resume storage resume = resumes[resumeId];
        require(resume.submitter != address(0), "Resume does not exist");
        require(resume.reviewer == address(0), "Already accepted for review");
        require(resume.submitter != msg.sender, "Submitter cannot review their own resume");

        resume.reviewer = msg.sender;

        emit ReviewAccepted(resumeId, msg.sender, resume.rewardAmount);
    }

    // Complete the review and claim the reward
    function completeReview(uint256 resumeId) external nonReentrant {
        Resume storage resume = resumes[resumeId];
        require(resume.reviewer == msg.sender, "Only the assigned reviewer can complete the review");
        require(!resume.reviewed, "Review already completed");

        resume.reviewed = true;

        // Transfer the reward before emitting the event
        require(rewardToken.transfer(resume.reviewer, resume.rewardAmount), "Reward transfer failed");

        emit ReviewCompleted(resumeId, msg.sender);
    }

    // View resume details
    function getResume(uint256 resumeId) external view returns (Resume memory) {
        return resumes[resumeId];
    }
}