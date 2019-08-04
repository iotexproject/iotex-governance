pragma solidity ^0.4.24;

import "./library/IssueSheet.sol";
import "./library/Ownable.sol";
import "./library/Pausable.sol";
import "./library/Whitelist.sol";
import "./IssueProposal.sol";
import "./SingleIssue.sol";

contract IssueRegistration is Ownable, Whitelist, Pausable  {
    event Withdraw(address _owner, uint256 _balance);
    event Register(address _issue, uint256 _fee);

    uint256 public registrationFee;
    IssueSheet sheet;

    mapping(address => bool) public validVPSs;

    constructor(uint256 _registrationFee, address _issueSheetAddr) public {
        registrationFee = _registrationFee;
        sheet = IssueSheet(_issueSheetAddr);
    }

    function isValidVPS(address _addr) public view returns (bool) {
        return validVPSs[_addr];
    }

    function issueSheet() public view returns(address) {
        return sheet;
    }

    function setIssueSheet(address _issueSheetAddr) public onlyWhitelisted {
        sheet = IssueSheet(_issueSheetAddr);
    }

    function setRegistrationFee(uint256 _fee) public onlyWhitelisted {
        registrationFee = _fee;
    }

    function addVPS(address _addr) public onlyWhitelisted {
        validVPSs[_addr] = true;
    }

    function deleteVPS(address _addr) public onlyWhitelisted {
        if (isValidVPS(_addr)) {
            delete validVPSs[_addr];
        }
    }

    function register(address _issueProposalAddr) public whenNotPaused payable returns (bool success) {
        require(msg.value >= registrationFee);
        require(canRegister(_issueProposalAddr));
        IssueProposal prop = IssueProposal(_issueProposalAddr);
        SingleIssue issue = new SingleIssue(_issueProposalAddr, prop.vpsAddress(), 
            prop.issueTitle(), prop.issueDescription(), prop.isMultiChoice(), prop.isCanRevote());
        if (sheet.addIssue(address(issue))) {
            issue.transferOwnership(address(sheet));
            emit Register(address(issue), msg.value);
            return true;
        }
        return false;
    }

    function canRegister(address _issueProposalAddr) public view returns (bool) {
        IssueProposal proposal = IssueProposal(_issueProposalAddr);
        return isValidVPS(proposal.vpsAddress()) && proposal.optionCount() > 0;
    }

    function withdraw() public onlyOwner payable {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(owner, balance);
    }
}