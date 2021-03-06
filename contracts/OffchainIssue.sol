pragma solidity ^0.4.22;

// This contract implements the management of one proposals (known as issue) in an offchain manner,
// indicating the proposal details actually are stored offchain, e.g., on IPFS, while the hash and _uri
// of the details are stored in the contract.

import "./library/ERC1202.sol";
import "./library/Ownable.sol";
import "./library/VotingPowerSystem.sol";
import "./library/SafeMath.sol";
import "./library/IssueSheet.sol";

contract OffchainIssue is ERC1202, Ownable {
    using SafeMath for uint;

    struct Ballot {
        bool[] values;
        bool flag;
    }

    //title, desc, proposer, options
    string metaURI;
    bytes32 metaHash;

    VotingPowerSystem public vps;
    mapping(address => Ballot) public ballots;
    address[] voterAddrs;

    enum Status {
        New,
        Active,
        Paused,
        Ended
    }
    Status public status;

    bool public canRevote;
    uint public multiChoice;
    uint public optionCount;

    constructor(string _uri, bytes32 _hash, address _vpsAddress, uint _optionCount, bool _canRevote, uint8 _multiChoice) public {
        metaURI = _uri;
        metaHash = _hash;
        vps = VotingPowerSystem(_vpsAddress);
        optionCount = _optionCount;
        canRevote = _canRevote;
        if (_multiChoice == 0) {
            multiChoice = 1;
        } else {
            multiChoice = _multiChoice;
        }
        status = Status.New;
    }

    function pause() public onlyOwner {
        require(isActive());
        status = Status.Paused;
    }

    function unpause() public onlyOwner {
        require(isPaused());
        status = Status.Active;
    }

    function start() public onlyOwner {
        setStatus(true);
    }

    function end() public onlyOwner {
        setStatus(false);
    }

    function isNew() public view returns (bool) {
        return status == Status.New;
    }

    function isActive() public view returns (bool) {
        return status == Status.Active;
    }

    function isPaused() public view returns (bool) {
        return status == Status.Paused;
    }

    function isEnded() public view returns (bool) {
        return status == Status.Ended;
    }

    function voteInternal(uint[] _opts) internal returns (bool) {
        require(isActive());
        uint i;
        if (canRevote) {
            for (i = 0; i < optionCount; i++) {
                ballots[msg.sender].values[i] = false;
            }
        } else {
            uint existingVotes = 0;
            for (i = 0; i < optionCount; i++) {
                if (ballots[msg.sender].values[i]) {
                    existingVotes++;
                }
            }
            if (existingVotes > 0) {
                return false;
            }
        }
        for (i = 0; i < _opts.length; i++) {
            uint opt = _opts[i];
            require(opt > 0 && opt <= optionCount);
            ballots[msg.sender].values[opt - 1] = true;
            emit OnVote(msg.sender, opt);
        }
        return true;
    }

    function createBallotIfNotExist() internal {
        if (!ballots[msg.sender].flag) {
            voterAddrs.push(msg.sender);
            ballots[msg.sender] = Ballot(new bool[](optionCount), true);
        }
    }

    function vote(uint _opt) external returns (bool) {
        createBallotIfNotExist();
        uint[] memory opts = new uint[](1);
        opts[0] = _opt;
        return voteInternal(opts);
    }

    function voteMultiple(uint[] _opts) public returns (bool) {
        createBallotIfNotExist();
        return voteInternal(_opts);
    }

    function numOfVoters() public view returns (uint) {
        return voterAddrs.length;
    }

    function voters(uint _offset, uint _limit) public view returns (address[] addrs_) {
        if (_offset >= voterAddrs.length || _limit == 0) {
            return addrs_;
        }
        uint limit = voterAddrs.length - _offset;
        if (_limit < limit) {
            limit = _limit;
        }
        addrs_ = new address[](limit);
        for (uint i = 0; i < limit; i++) {
            addrs_[i] = voterAddrs[_offset + i];
        }
    }

    function voted(uint _opt, address[] _voters) external view returns (bool[] voted_) {
        require(_opt > 0 && _opt <= optionCount && _voters.length > 0);
        voted_ = new bool[](_voters.length);
        for (uint i = 0; i < _voters.length; i++) {
            if (ballots[_voters[i]].flag) {
                voted_[i] = ballots[_voters[i]].values[_opt - 1];
            }
        }
    }

    function setStatus(bool _isOpen) public onlyOwner returns (bool success) {
        if (_isOpen) {
            if (!isNew() || optionCount == 0) {
                return false;
            }
            status = Status.Active;
        } else {
            if (!isActive() && !isPaused()) {
                return false;
            }
            status = Status.Ended;
        }
        emit OnStatusChange(_isOpen);
        return true;
    }

    function ballotOf(address addr) external view returns (uint) {
        require(multiChoice <= 1);
        if (ballots[addr].flag) {
            for (uint i = 0; i < optionCount; i++) {
                if (ballots[addr].values[i]) {
                    return i + 1;
                }
            }
        }
        return 0;
    }

    function ballotsOf(address _addr) external view returns (uint[] ballots_) {
        uint i = 0;
        uint size = 0;
        for (i = 0; i < optionCount; i++) {
            if (ballots[_addr].values[i]) {
                size++;
            }
        }
        if (size != 0) {
            uint idx = 0;
            ballots_ = new uint[](size);
            for (i = 0; i < optionCount; i++) {
                if (ballots[_addr].values[i]) {
                    ballots_[idx++] = i + 1;
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

    function description() external view returns (string) {
        return "Not Applicable";
    }

    function optionDescription(uint _opt) external view returns (string) {
        require(_opt > 0 && _opt <= optionCount);
        return "Not Applicable";
    }

    function availableOptions() external view returns (uint[] options_) {
        options_ = new uint[](optionCount);
        for (uint i = 0; i < optionCount; i++) {
            options_[i] = i + 1;
        }
        return options_;
    }

}
