pragma solidity ^0.4.22;

import "./library/Ownable.sol";
import "./library/VotingPowerSystem.sol";
import "./library/SafeMath.sol";

contract SingleIssue is Ownable {
    using SafeMath for uint;
    struct Ballot {
        address voter;
        uint option;
    }
    string public title;
    string public description;
    address public proposer;
    VotingPowerSystem public vps;

    mapping(uint => Ballot) public ballots;
    mapping(address => uint[]) public voterBallots; 
    uint public ballotCount;

    mapping(uint => string) public options;
    uint public optionCount;

    uint public votingFee;
    uint public status; // 0: new; 1: started; 2: paused; 3: ended

    bool public canRevote;
    bool public multiChoice;

    constructor(address _vpsAddress, string _title, string _desc, bool _canRevote, bool _multiChoice, uint256 _votingFee) public {
        require(bytes(_title).length > 0 && bytes(_title).length < 20);
        require(bytes(_desc).length > 0);
        vps = VotingPowerSystem(_vpsAddress);
        title = _title;
        description = _desc;
        votingFee = _votingFee;
        canRevote = _canRevote;
        multiChoice = _multiChoice;
        proposer = msg.sender;
        optionCount = 0;
        ballotCount = 0;
        status = 0;
    }

    function addOption(string _option) external onlyOwner returns (uint) {
        require(isNew() && bytes(_option).length > 0);
        for (uint i = 1; i <= optionCount; i++) {
             if (keccak256(abi.encodePacked(_option)) == keccak256(abi.encodePacked(options[i]))) {
                return i;
            }
        }
        optionCount++;
        options[optionCount] = _option;
        return optionCount;
    }

    function pause() onlyOwner public {
        require(isActive());
        status = 2;
    }

    function unpause() onlyOwner public {
        require(isPaused());
        status = 1;
    }

    function start() onlyOwner public {
        setStatus(true);
    }

    function end() onlyOwner public {
        setStatus(false);
    }
    
    function vpsAddress() public view returns (address) {
        return vps;
    }

    function isNew() public view returns (bool) {
        return status == 0;
    }

    function isActive() public view returns (bool) {
        return status == 1;
    }

    function isPaused() public view returns (bool) {
        return status == 2;
    }

    function isEnded() public view returns (bool) {
        return status == 3;
    }

    function vote(uint _opt) external payable returns (bool) {
        require(isActive());
        require(_opt > 0 && _opt <= optionCount);
        require(msg.value >= votingFee);
        if (multiChoice) {
            ballots[ballotCount] = Ballot(msg.sender, _opt);
            ballotCount++;
        } else {
            if (voterBallots[msg.sender].length > 0) {
                if (!canRevote) {
                    return false;
                }
                ballots[voterBallots[msg.sender][0]].option = _opt;
            } else {
                ballots[ballotCount] = Ballot(msg.sender, _opt);
                ballotCount++;
            }
        }

        return true;
    }

    function setStatus(bool _isOpen) public onlyOwner returns (bool success) {
        if (_isOpen) {
            if (!isNew() || optionCount == 0) {
                return false;
            }
            status = 1;
        } else {
            if (!isActive() && !isPaused()) {
                return false;
            }
            status = 3;
        }
        emit OnStatusChange(_isOpen);
        return true;
    }

    function issueTitle() external view returns (string) {
        return title;
    }

    function issueDescription() external view returns (string) {
        return description;
    }

    function availableOptions() external view returns (uint[] options_) {
        options_ = new uint[](optionCount);
        for (uint i = 0; i < optionCount; i++) {
            options_[i] = i + 1;
        }
        return options_;
    }

    function optionDescription(uint _opt) external view returns (string) {
        require(_opt > 0 && _opt <= optionCount);
        return options[_opt];
    }

    function ballotOf(address addr) external view returns (uint) {
        require(!multiChoice);
        require(voterBallots[addr].length > 0);
        return voterBallots[addr][0];
    }

    function weightOf(address addr) external view returns (uint) {
        return vps.powerOf(addr);
    }

    function getStatus() external view returns (bool) {
        return isActive();
    }

    function weightedVoteCountsOf(uint _opt) external view returns (uint count_) {
        require(_opt > 0 && _opt <= optionCount);
        for (uint i = 0; i < ballotCount; i++) {
            if (ballots[i].option == _opt) {
                uint power = vps.powerOf(ballots[i].voter);
                if (power != 0) {
                    count_ = SafeMath.add(count_, power);
                }
            }
        }
        return count_;
    }

    function winningOption() external view returns (uint winningOption_) {
        uint[] memory counts = new uint[](optionCount);
        uint i;
        for (i = 0; i < ballotCount; i++) {
            uint power = vps.powerOf(ballots[i].voter);
            if (power != 0) {
                counts[ballots[i].option - 1] = SafeMath.add(counts[ballots[i].option - 1], power);
            }
        }
        for (i = 0; i < optionCount; i++) {
            if (winningOption_ == 0 || counts[winningOption_ - 1] < counts[i]) {
                winningOption_ = i + 1;
            }
        }

        return winningOption_;
    }

    event OnVote(address indexed _from, uint _value);
    event OnStatusChange(bool newIsOpen);
}