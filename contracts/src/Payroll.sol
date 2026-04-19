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
        bool paused;
    }

    uint256 public nextStreamId;

    mapping(uint256 => Stream) public streams;
    mapping(address => uint256[]) public userStreams;

    event StreamCreated(
        uint256 indexed streamId,
        address indexed employer,
        address indexed employee,
        uint256 ratePerSecond
    );

    event Withdrawn(uint256 indexed streamId, uint256 amount);

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
            paused: false
        });

        userStreams[msg.sender].push(nextStreamId);
        userStreams[employee].push(nextStreamId);

        emit StreamCreated(nextStreamId, msg.sender, employee, ratePerSecond);

        nextStreamId++;
    }

    function withdraw(uint256 streamId) external {
        Stream storage stream = streams[streamId];

        require(msg.sender == stream.employee, "not employee");
        require(!stream.paused, "stream paused");

        uint256 elapsed = block.timestamp - stream.startTime;
        uint256 totalEarned = elapsed * stream.ratePerSecond;
        uint256 withdrawable = totalEarned - stream.withdrawn;

        require(withdrawable > 0, "nothing to withdraw");

        stream.withdrawn += withdrawable;

        require(
            IERC20(stream.token).transfer(stream.employee, withdrawable),
            "transfer failed"
        );

        emit Withdrawn(streamId, withdrawable);
    }

    function getWithdrawable(uint256 streamId) public view returns (uint256) {
        Stream memory stream = streams[streamId];

        if (stream.paused) return 0;

        uint256 elapsed = block.timestamp - stream.startTime;
        uint256 totalEarned = elapsed * stream.ratePerSecond;

        if (totalEarned <= stream.withdrawn) return 0;

        return totalEarned - stream.withdrawn;
    }
}