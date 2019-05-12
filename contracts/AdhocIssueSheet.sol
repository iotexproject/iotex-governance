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
        if (issues[_issue].flag) {
            return false;
        }
        issues[_issue] = Issue(issueCount, false, true);
        issueAddresses[issueCount] = _issue;
        issueCount++;
        return true;
    }

    function transferIssueOwnership(uint256 _offset, uint256 _limit, address _issueSheetAddress) public onlyOwner {
        if (_offset >= issueCount) {
            return;
        }
        uint256 end = _offset + _limit;
        if (end > issueCount) {
            end = issueCount;
        }
        for (uint i = _offset; i < end; i++) {
            SingleIssue issue = SingleIssue(issueAddresses[i]);
            issue.transferOwnership(_issueSheetAddress);
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

    function getIssues(uint256 _offset, uint256 _limit) public view returns (address[] issueAddrs_) {
        if (_offset >= issueCount || _limit == 0) {
            return issueAddrs_;
        }
        uint256 l = issueCount - _offset;
        if (l > _limit) {
            l = _limit;
        }
        issueAddrs_ = new address[](l);
        for (uint256 i = 0; i < l; i++) {
            issueAddrs_[i] = issueAddresses[_offset + i];
        }
    }
}