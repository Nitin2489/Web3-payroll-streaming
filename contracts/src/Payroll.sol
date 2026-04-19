// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

contract Payroll {
    struct Stream {
        address employer;
        address employee;
        address token;
        uint256 ratePerSecond;
        uint256 startTime;
        uint256 withdrawn;
        uint256 totalAmount;
        uint256 pauseTime;
        uint256 totalPausedTime;
        bool paused;
    }

    uint256 public nextStreamId;

    mapping(uint256 => Stream) public streams;
    mapping(address => uint256[]) public userStreams;

    event StreamCreated(uint256 indexed id, address employer, address employee);
    event Withdrawn(uint256 indexed id, uint256 amount);
    event Paused(uint256 indexed id);
    event Resumed(uint256 indexed id);

    function createStream(
        address employee,
        address token,
        uint256 monthlySalary
    ) external {
        require(employee != address(0), "invalid employee");
        require(monthlySalary > 0, "invalid salary");

        uint256 ratePerSecond = monthlySalary / 30 days;

        require(
            IERC20(token).transferFrom(msg.sender, address(this), monthlySalary),
            "transfer failed"
        );

        streams[nextStreamId] = Stream({
            employer: msg.sender,
            employee: employee,
            token: token,
            ratePerSecond: ratePerSecond,
            startTime: block.timestamp,
            withdrawn: 0,
            totalAmount: monthlySalary,
            pauseTime: 0,
            totalPausedTime: 0,
            paused: false
        });

        userStreams[msg.sender].push(nextStreamId);
        userStreams[employee].push(nextStreamId);

        emit StreamCreated(nextStreamId, msg.sender, employee);

        nextStreamId++;
    }

    function withdraw(uint256 id) external {
        Stream storage s = streams[id];

        require(msg.sender == s.employee, "not employee");

        uint256 withdrawable = getWithdrawable(id);
        require(withdrawable > 0, "nothing");

        s.withdrawn += withdrawable;

        require(
            IERC20(s.token).transfer(s.employee, withdrawable),
            "transfer failed"
        );

        emit Withdrawn(id, withdrawable);
    }

    function pause(uint256 id) external {
        Stream storage s = streams[id];

        require(msg.sender == s.employer, "not employer");
        require(!s.paused, "already paused");

        s.paused = true;
        s.pauseTime = block.timestamp;

        emit Paused(id);
    }

    function resume(uint256 id) external {
        Stream storage s = streams[id];

        require(msg.sender == s.employer, "not employer");
        require(s.paused, "not paused");

        uint256 pausedDuration = block.timestamp - s.pauseTime;
        s.totalPausedTime += pausedDuration;

        s.paused = false;

        emit Resumed(id);
    }

    function getWithdrawable(uint256 id) public view returns (uint256) {
        Stream memory s = streams[id];

        uint256 effectiveTime;

        if (s.paused) {
            effectiveTime = s.pauseTime - s.startTime - s.totalPausedTime;
        } else {
            effectiveTime = block.timestamp - s.startTime - s.totalPausedTime;
        }

        uint256 totalEarned = effectiveTime * s.ratePerSecond;

        if (totalEarned > s.totalAmount) {
            totalEarned = s.totalAmount;
        }

        if (totalEarned <= s.withdrawn) return 0;

        return totalEarned - s.withdrawn;
    }
}