pragma solidity ^0.4.24;

import "./library/IssueSheet.sol";
import "./library/Ownable.sol";
import "./library/Pausable.sol";
import "./library/Whitelist.sol";
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

    function register(address _issueAddr) public whenNotPaused payable returns (bool success) {
        require(msg.value >= registrationFee);
        require(canRegister(_issueAddr));
        SingleIssue issue = SingleIssue(_issueAddr);
        require(address(this) == issue.owner());
        if (sheet.addIssue(_issueAddr)) {
            issue.transferOwnership(address(sheet));
            emit Register(_issueAddr, msg.value);
            return true;
        }
        return false;
    }

    function canRegister(address _issueAddr) public view returns (bool) {
        SingleIssue issue = SingleIssue(_issueAddr);
        return isValidVPS(issue.vpsAddress()) && issue.isNew() && issue.optionCount() > 0;
    }

    function withdraw() public onlyOwner payable {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(owner, balance);
    }
}