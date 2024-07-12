// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract WhiZper {
    address payable public owner;

    uint public currentGroupId = 0;
    mapping(uint => mapping(uint => bool)) public userGroupMapping;
    mapping(uint => string) public groupNameMapping;

    event Group(uint indexed groupId, uint indexed userId, string groupName);
    event Message(uint indexed groupId, uint indexed userId, string message);

    constructor() payable {
        owner = payable(msg.sender);
    }

    function createGroup(uint userId, string memory groupName) public {
        uint groupId = currentGroupId;
        groupNameMapping[groupId] = groupName;
        joinGroup(groupId, userId);
        currentGroupId++;
    }

    function joinGroup(uint groupId, uint userId) public {
        require(
            userGroupMapping[userId][groupId] == false,
            "User has joined the group"
        );
        require(msg.sender == owner, "You aren't the owner");
        string memory groupName = groupNameMapping[groupId];
        emit Group(groupId, userId, groupName);
        userGroupMapping[userId][groupId] = true;
    }

    function sendMessage(
        uint groupId,
        uint userId,
        string memory message
    ) public {
        require(
            userGroupMapping[userId][groupId],
            "User has not joined the group"
        );
        require(msg.sender == owner, "You aren't the owner");

        emit Message(groupId, userId, message);
    }
}
