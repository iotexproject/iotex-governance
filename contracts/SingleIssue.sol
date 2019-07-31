pragma solidity ^0.4.22;

import "./library/ERC1202.sol";
import "./library/Ownable.sol";
import "./library/VotingPowerSystem.sol";
import "./library/SafeMath.sol";
import "./IssueProposal.sol";

contract SingleIssue is  ERC1202, Ownable, IssueProposal {
    using SafeMath for uint;
    struct Ballot {
        bool[] values;
        bool flag;
    }

    mapping(address => Ballot) public ballots;
    address[] voterAddrs;

    address public proposer;
    uint public status; // 0: new; 1: started; 2: paused; 3: ended

    constructor(address _proposal, address _vpsAddress, string _title, string _desc, bool _multiChoice, bool _canRevote) public 
    IssueProposal( _vpsAddress, _title, _desc, _multiChoice, _canRevote){
        proposer = msg.sender;
        status = 0;   

        IssueProposal proposal = IssueProposal(_proposal);           
        optionCount= proposal.optionCount();
        for(uint i = 1; i <= optionCount; i++){
            options[i] = proposal.optionDescription(i); 
        }
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

    function vote(uint _opt) external returns (bool) {
        require(isActive());
        require(_opt > 0 && _opt <= optionCount);
        if (!ballots[msg.sender].flag) {
            //in case of first-voting 
            voterAddrs.push(msg.sender);
            ballots[msg.sender] = Ballot(new bool[](optionCount), true);
            ballots[msg.sender].values[_opt - 1] = true;
        } else {
            if (multiChoice) {
                //multiple-choice 
                ballots[msg.sender].values[_opt - 1] = true;
            } else {
                if (!canRevote) {
                    //single-choice, cannot re-vote 
                    return false;
                }
                //single-choice, can re-vote 
                for (uint i = 0; i < optionCount; i++) {
                    ballots[msg.sender].values[i] = i + 1 == _opt;
                }
            }
        }
        emit OnVote(msg.sender, _opt);

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

    function ballotOf(address addr) external view returns (uint) {
        require(!multiChoice);
        if (ballots[addr].flag) {
            for (uint i = 0; i < optionCount; i++) {
                if (ballots[addr].values[i]) {
                    return i + 1;
                }
            }
        }
        return 0;
    }

    function weightOf(address addr) external view returns (uint) {
        return vps.powerOf(addr);
    }

    function getStatus() external view returns (bool) {
        return isActive();
    }

    function weightedVoteCountsOf(uint _opt) external view returns (uint count_) {
        require(_opt > 0 && _opt <= optionCount);
        for (uint i = 0; i < voterAddrs.length; i++) {
            uint power = vps.powerOf(voterAddrs[i]);
            if (power != 0 && ballots[voterAddrs[i]].values[_opt - 1]) {
                count_ = SafeMath.add(count_, power);
            }
        }
        return count_;
    }

    function winningOption() external view returns (uint winningOption_) {
        uint[] memory counts = new uint[](optionCount);
        uint i;
        for (i = 0; i < voterAddrs.length; i++) {
            uint power = vps.powerOf(voterAddrs[i]);
            if (power != 0) {
                Ballot storage b = ballots[voterAddrs[i]];
                for (uint j = 0; j < optionCount; j++) {
                    if (b.values[j]) {
                        counts[j] = SafeMath.add(counts[j], power);
                    }
                }
            }
        }
        for (i = 0; i < optionCount; i++) {
            if (winningOption_ == 0 || counts[winningOption_ - 1] < counts[i]) {
                winningOption_ = i + 1;
            }
        }

        return winningOption_;
    }
}