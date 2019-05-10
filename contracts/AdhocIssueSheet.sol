pragma solidity ^0.4.24;

import "./library/IssueSheet.sol";
import "./library/Ownable.sol";
import "./library/Pausable.sol";
import "./library/Whitelist.sol";
import "./SingleIssue.sol";

contract AdhocIssueSheet is Ownable, IssueSheet, Whitelist {
    struct Issue {
        uint id;
        bool approved;
        bool flag;
    }
    event Approve(address _issue);

    mapping(uint256 => address) public issueAddresses;
    mapping(address => Issue) public issues;
    uint256 public issueCount;

    constructor() public {
        issueCount = 0;
    }

    function addIssue(address _issue) public onlyWhitelisted returns (bool) {
        if (!issues[_issue].flag) {
            return false;
        }
        issues[_issue] = Issue(issueCount, false, true);
        issueAddresses[issueCount] = _issue;
        issueCount++;
        return true;
    }

    function transferIssuesTo(address _issueSheetAddress) public onlyOwner {
        IssueSheet newIssueSheet = IssueSheet(_issueSheetAddress);
        for (uint i = 0; i < issueCount; i++) {
            address issueAddr = issueAddresses[i];
            SingleIssue issue = SingleIssue(issueAddr);
            require(newIssueSheet.addIssue(issueAddr));
            issue.transferOwnership(_issueSheetAddress);
            if (approved(issueAddr)) {
                require(newIssueSheet.approve(issueAddr));
            }
        }
    }

    function approve(address _issue) public onlyWhitelisted returns (bool) {
        if (!issues[_issue].flag || issues[_issue].approved) {
            return false;
        }
        issues[_issue].approved = true;
        emit Approve(_issue);
        return true;
    }

    function approved(address _issue) public view returns (bool) {
        require(issues[_issue].flag);
        return issues[_issue].approved;
    }

    function contains(address _issue) public view returns (bool) {
        return issues[_issue].flag;
    }

    function startIssue(address _issue) public onlyWhitelisted returns (bool) {
        if (!contains(_issue) || !approved(_issue)) {
            return false;
        }
        SingleIssue issue = SingleIssue(_issue);
        if (!issue.isNew()) {
            return false;
        }
        issue.start();
        return true;
    }

    function pauseIssue(address _issue) public onlyWhitelisted returns (bool) {
        if (!contains(_issue) || !approved(_issue)) {
            return false;
        }
        SingleIssue issue = SingleIssue(_issue);
        if (!issue.isActive()) {
            return false;
        }
        issue.pause();
        return true;
    }

    function resumeIssue(address _issue) public onlyWhitelisted returns (bool) {
        if (!contains(_issue) || !approved(_issue)) {
            return false;
        }
        SingleIssue issue = SingleIssue(_issue);
        if (!issue.isPaused()) {
            return false;
        }
        issue.unpause();
        return true;
    }

    function endIssue(address _issue) public onlyWhitelisted returns (bool) {
        if (!contains(_issue) || !approved(_issue)) {
            return false;
        }
        SingleIssue issue = SingleIssue(_issue);
        if (issue.isEnded() || issue.isNew()) {
            return false;
        }
        issue.end();
        return true;
    }
}