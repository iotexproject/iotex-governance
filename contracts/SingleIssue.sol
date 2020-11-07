pragma solidity ^0.4.22;

// This contract implements the storage and management of a single proposal (known as issue).

import "./library/ERC1202.sol";
import "./library/Ownable.sol";
import "./library/VotingPowerSystem.sol";
import "./library/SafeMath.sol";
import "./IssueProposal.sol";
import "./library/IssueSheet.sol";

contract SingleIssue is ERC1202, IssueBase, Ownable {
    using SafeMath for uint;
    event NewOption(uint256 index, string description);
    struct Ballot {
        uint[] counts;
        bool flag;
    }

    mapping(address => Ballot) public ballots;
    address[] voterAddrs;
    VotingPowerSystem public vps;
    string[] private optionDescriptions;
    uint256 public endHeight;

    address public proposer;
    uint public status; // 0: new; 1: started; 2: paused; 3: ended

    constructor(address _proposal, address _vpsAddress) public {
        IssueProposal proposal = IssueProposal(_proposal);
        vps = VotingPowerSystem(_vpsAddress);
        title = proposal.title();
        description = proposal.description();
        canRevote = proposal.canRevote();
        maxNumOfChoices = proposal.maxNumOfChoices();
        if (maxNumOfChoices == 0) {
            maxNumOfChoices = 1;
        }
        proposer = msg.sender;
        status = 0;

        for(uint i = 0; i < proposal.optionCount(); i++) {
            optionDescriptions.push(proposal.getOptionDescription(i));
        }
    }

    function availableOptions() external view returns (uint[] options_) {
        uint l = optionCount();
        if (l == 0) {
            return options_;
        }
        options_ = new uint[](l);
        for (uint i = 0; i < l; i++) {
            options_[i] = i;
        }
    }

    function optionDescription(uint _opt) external view returns (string) {
        return optionDescriptions[_opt];
    }

    function optionCount() public view returns (uint) {
        return optionDescriptions.length;
    }

    function pause() public onlyOwner {
        require(isActive());
        status = 2;
    }

    function unpause() public onlyOwner {
        require(isPaused());
        status = 1;
    }

    function start() public onlyOwner {
        setStatus(true);
    }

    function end() public onlyOwner {
        setStatus(false);
    }

    function isNew() public view returns (bool) {
        return status == 0;
    }

    function isActive() public view returns (bool) {
        return status == 1 && (endHeight == 0 || block.number <= endHeight);
    }

    function isPaused() public view returns (bool) {
        return status == 2;
    }

    function isEnded() public view returns (bool) {
        return status == 3;
    }

    function voteInternal(uint[] _opts) internal returns (bool) {
        require(isActive() && _opts.length > 0, "invalid status");
        if (!ballots[msg.sender].flag) {
            voterAddrs.push(msg.sender);
            ballots[msg.sender] = Ballot(new uint[](optionCount()), true);
        }
        uint l = optionCount();
        uint i;
        if (canRevote) {
            for (i = 0; i < l; i++) {
                ballots[msg.sender].counts[i] = 0;
            }
        } else {
            for (i = 0; i < l; i++) {
                if (ballots[msg.sender].counts[i] > 0) {
                    return false;
                }
            }
        }
        uint unique = 0;
        for (i = 0; i < _opts.length; i++) {
            uint opt = _opts[i];
            require(opt < l, "out of range");
            if (ballots[msg.sender].counts[opt] == 0) {
                unique++;
            }
            ballots[msg.sender].counts[opt]++;
            emit OnVote(msg.sender, opt);
        }
        require(unique <= maxNumOfChoices, "two many choices");
        return true;
    }

    function vote(uint _opt) external returns (bool) {
        uint[] memory opts = new uint[](1);
        opts[0] = _opt;
        return voteInternal(opts);
    }

    function voteMultiple(uint[] _opts) public returns (bool) {
        return voteInternal(_opts);
    }

    function numOfVoters() public view returns (uint) {
        return voterAddrs.length;
    }

    function voters(uint _offset, uint _limit) public view returns (address[] addrs_) {
        require(_offset < numOfVoters() && _limit > 0, "invalid parameters");
        uint limit = numOfVoters() - _offset;
        if (_limit < limit) {
            limit = _limit;
        }
        addrs_ = new address[](limit);
        for (uint i = 0; i < limit; i++) {
            addrs_[i] = voterAddrs[_offset + i];
        }
    }

    function voted(uint _opt, address[] _voters) external view returns (uint[] voted_) {
        require(_opt < optionCount() && _voters.length > 0, "invalid parameters");
        voted_ = new uint[](_voters.length);
        for (uint i = 0; i < _voters.length; i++) {
            if (ballots[_voters[i]].flag) {
                voted_[i] = ballots[_voters[i]].counts[_opt];
            }
        }
    }

    function setStatus(bool _isOpen) public onlyOwner returns (bool success) {
        if (_isOpen) {
            if (!isNew() || optionCount() == 0) {
                return false;
            }
            if (duration > 0) {
                endHeight = block.number + duration;
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
        require(maxNumOfChoices == 1, "not a single choice issue");
        if (!ballots[addr].flag) {
            return optionCount();
        }
        for (uint i = 0; i < optionCount(); i++) {
            if (ballots[addr].counts[i] > 0) {
                return i;
            }
        }
        revert("invalid ballot");
    }

    function ballotsOf(address _addr) external view returns (uint[] ballots_) {
        if (!ballots[_addr].flag) {
            return ballots_;
        }
        uint i = 0;
        uint size = 0;
        for (i = 0; i < optionCount(); i++) {
            if (ballots[_addr].counts[i] > 0) {
                size++;
            }
        }
        if (size != 0) {
            uint idx = 0;
            ballots_ = new uint[](size);
            for (i = 0; i < optionCount(); i++) {
                if (ballots[_addr].counts[i] > 0) {
                    ballots_[idx++] = i;
                }
            }
        }
    }

    function weightOf(address addr) external view returns (uint) {
        return vps.powerOf(addr);
    }

    function getStatus() external view returns (bool) {
        return isActive();
    }

    function weightedVoteCountsOf(uint _opt) external view returns (uint count_) {
        require(_opt < optionCount(), "out of range");
        for (uint i = 0; i < voterAddrs.length; i++) {
            uint power = vps.powerOf(voterAddrs[i]);
            if (power != 0 && ballots[voterAddrs[i]].flag) {
                count_ = SafeMath.add(count_, SafeMath.mul(power, ballots[voterAddrs[i]].counts[_opt]));
            }
        }
        return count_;
    }

    function winningOption() external view returns (uint winningOption_) {
        uint l = optionCount();
        uint[] memory counts = new uint[](l);
        uint i;
        for (i = 0; i < voterAddrs.length; i++) {
            uint power = vps.powerOf(voterAddrs[i]);
            Ballot storage b = ballots[voterAddrs[i]];
            if (power != 0 && b.flag) {
                for (uint j = 0; j < l; j++) {
                    counts[j] = SafeMath.add(counts[j], SafeMath.mul(power, b.counts[j]));
                }
            }
        }
        winningOption_ = l;
        for (i = 0; i < l; i++) {
            if (winningOption_ == l || counts[winningOption_] < counts[i]) {
                winningOption_ = i;
            }
        }
    }
}
