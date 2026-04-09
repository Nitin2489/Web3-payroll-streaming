// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Payroll {
    struct Stream {
        address employer;
        address employee;
        address token;
        uint256 ratePerSecond;
        uint256 startTime;
        uint256 withdrawn;
        bool paused;
    }

    uint256 public nextStreamId;
    mapping(uint256 => Stream) public streams;
    mapping(address => uint256[]) public userStreams;

    event StreamCreated(uint256 indexed streamId, address indexed employer, address indexed employee);
    event Withdrawn(uint256 indexed streamId, uint256 amount);
    event StreamPaused(uint256 indexed streamId);
    event StreamResumed(uint256 indexed streamId);

    function createStream(address employee, address token, uint256 monthlySalary) external {}

    function withdraw(uint256 streamId) external {}

    function pauseStream(uint256 streamId) external {}

    function resumeStream(uint256 streamId) external {}

    function getWithdrawable(uint256 streamId) public view returns (uint256) {}
}