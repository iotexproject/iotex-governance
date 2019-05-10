pragma solidity ^0.4.24;

interface IssueSheet {
    event Approve(address issueAddress);

    function addIssue(address issueAddress) external returns (bool);

    function approve(address issue) external returns (bool);

    function approved(address issue) external view returns (bool);

    function contains(address addr) external view returns (bool);
}