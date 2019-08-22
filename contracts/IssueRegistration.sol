pragma solidity ^0.4.24;

import "./library/IssueSheet.sol";
import "./library/Ownable.sol";
import "./library/Pausable.sol";
import "./library/Whitelist.sol";
import "./IssueProposal.sol";
import "./SingleIssue.sol";
import "./OffchainIssue.sol";

contract IssueRegistration is Ownable, Whitelist, Pausable  {
    event Withdraw(address _owner, uint256 _balance);
    event Register(address _issue, uint256 _fee);

    uint256 public registrationFee;
    IssueSheet sheet;

    address public weightedVPSAddress;
    address public equalVPSAddress;

    constructor(uint256 _registrationFee, address _issueSheetAddr, address _weightedVPS, address _equalVPS) public {
        registrationFee = _registrationFee;
        sheet = IssueSheet(_issueSheetAddr);
        weightedVPSAddress = _weightedVPS;
        equalVPSAddress = _equalVPS;
    }

    function setWeightedVPSAddress(address _addr) public onlyWhitelisted {
        weightedVPSAddress = _addr;
    }

    function setEqualVPSAddress(address _addr) public onlyWhitelisted {
        equalVPSAddress = _addr;
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

    function register(
        string _metaURI,
        bytes32 _metaHash,
        bool _weighted,
        uint _optionCount,
        bool _canRevote,
        uint8 _maxNumOfChoices) public whenNotPaused payable returns (bool) {
        require(msg.value >= registrationFee);
        address vpsAddress = equalVPSAddress;
        if (_weighted) {
            vpsAddress = weightedVPSAddress;
        }
        OffchainIssue issue = new OffchainIssue (
            _metaURI,
            _metaHash,
            vpsAddress,
            _optionCount,
            _canRevote,
            _maxNumOfChoices);
        if (sheet.addIssue(address(issue))) {
            issue.transferOwnership(address(sheet));
            emit Register(address(issue), msg.value);
            return true;
        }
        return false;
    }

    function withdraw() public onlyOwner payable {
        uint256 balance = address(this).balance;
        owner.transfer(balance);
        emit Withdraw(owner, balance);
    }
}