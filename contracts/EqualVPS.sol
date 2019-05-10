pragma solidity ^0.4.24;

import "./library/VotingPowerSystem.sol";
import "./library/Whitelist.sol";

contract EqualVPS is VotingPowerSystem, Whitelist {
    mapping(address => bool) public qualifiedVoters;
    address[] public voterAddrs;
    uint256 public numOfQualifiedVoters;
    bool public openToPublic;
    bool public canUpdateQualifiedVoters;

    modifier qualifiedVotersUpdatable() {
        require(!openToPublic && canUpdateQualifiedVoters);
        _;
    }

    constructor(bool _openToPublic, bool _canUpdateQualifiedVoters, address[] _qualifiedVoters) public {
        openToPublic = _openToPublic;
        if (!openToPublic) {
            canUpdateQualifiedVoters = _canUpdateQualifiedVoters;
            addQualifiedVotersInternal(_qualifiedVoters);
        }
    }

    function addQualifiedVotersInternal(address[] _voters) internal {
        for (uint i = 0; i < _voters.length; i++) {
            if (!qualifiedVoters[_voters[i]]) {
                numOfQualifiedVoters++;
                qualifiedVoters[_voters[i]] = true;
                emit SetVotingPower(_voters[i], 1);
                voterAddrs.push(_voters[i]);
            }
        }
    }

    function addQualifiedVoters(address[] _voters) external onlyWhitelisted qualifiedVotersUpdatable {
        addQualifiedVotersInternal(_voters);
    }

    function deleteQualifiedVoters(address[] _voters) external onlyWhitelisted qualifiedVotersUpdatable {
        for (uint i = 0; i < _voters.length; i++) {
            qualifiedVoters[_voters[i]] = false;
            emit SetVotingPower(_voters[i], 0);
        }
    }

    function totalPower() public view returns (uint256) {
        if (openToPublic) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return numOfQualifiedVoters;
    }

    function powersOf(address[] _voters) external view returns (uint256[] powers_) {
        if (_voters.length == 0) {
            return powers_;
        }
        powers_ = new uint256[](_voters.length);
        for (uint i = 0; i < _voters.length; i++) {
            if (openToPublic || qualifiedVoters[_voters[i]]) {
                powers_[i] = 1;
            }
        }
    }

    function powerOf(address _voter) external view returns (uint256) {
        if (openToPublic || qualifiedVoters[_voter]) {
            return 1;
        }
        return 0;
    }

    function voters(uint256 _offset, uint256 _limit) public view returns (address[] voters_) {
        require(_limit <= 200);
        if (_limit == 0 || _offset >= voterAddrs.length || openToPublic) {
            return voters_;
        }
        uint256 l = voterAddrs.length - _offset;
        if (l > _limit) {
            l = _limit;
        }
        voters_ = new address[](l);
        for (uint i = 0; i < l; i++) {
            voters_[i] = voterAddrs[_offset + i];
        }
    }
}