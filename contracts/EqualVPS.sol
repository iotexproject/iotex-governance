pragma solidity ^0.4.24;

// This contract implements one strategy for voting power.
// As long as one stakes N IOTX within an account, this account has 1 vote power.

import "./library/VotingPowerSystem.sol";
import "./library/Whitelist.sol";

contract EqualVPS is VotingPowerSystem, Whitelist {
    struct Power {
        bool eligible;
        bool flag;
    }
    mapping(address => Power) public qualifiedVoters;
    address[] public voterAddrs;
    uint256 public numOfQualifiedVoters;
    bool public openToPublic;
    bool public canUpdateQualifiedVoters;
    bool public updating;
    modifier whenNotPaused() {
        require(!updating);
        _;
    }

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
        updating = true;
        for (uint i = 0; i < _voters.length; i++) {
            if (!qualifiedVoters[_voters[i]].flag) {
                voterAddrs.push(_voters[i]);
                qualifiedVoters[_voters[i]] = Power(true, true);
                numOfQualifiedVoters++;
            } else {
                if (!qualifiedVoters[_voters[i]].eligible) {
                    qualifiedVoters[_voters[i]].eligible = true;
                    numOfQualifiedVoters++;
                }
            }
            emit SetVotingPower(_voters[i], 1);
        }
    }

    function addQualifiedVoters(address[] _voters) external onlyWhitelisted qualifiedVotersUpdatable {
        addQualifiedVotersInternal(_voters);
    }

    function deleteQualifiedVoters(address[] _voters) external onlyWhitelisted qualifiedVotersUpdatable {
        updating = true;
        for (uint i = 0; i < _voters.length; i++) {
            if (qualifiedVoters[_voters[i]].flag) {
                if (qualifiedVoters[_voters[i]].eligible) {
                    qualifiedVoters[_voters[i]].eligible = false;
                    numOfQualifiedVoters--;
                }
            }
            emit SetVotingPower(_voters[i], 0);
        }
    }

    function totalPower() public whenNotPaused view returns (uint256) {
        if (openToPublic) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return numOfQualifiedVoters;
    }

    function powersOf(address[] _voters) external whenNotPaused view returns (uint256[] powers_) {
        if (_voters.length == 0) {
            return powers_;
        }
        powers_ = new uint256[](_voters.length);
        for (uint i = 0; i < _voters.length; i++) {
            if (openToPublic || qualifiedVoters[_voters[i]].eligible) {
                powers_[i] = 1;
            }
        }
    }

    function powerOf(address _voter) external whenNotPaused view returns (uint256) {
        if (openToPublic || qualifiedVoters[_voter].eligible) {
            return 1;
        }
        return 0;
    }

    function voters(uint256 _offset, uint256 _limit) public whenNotPaused view returns (address[] voters_) {
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

    function paused() public view returns (bool) {
        return updating;
    }

    function resume() external onlyWhitelisted {
        updating = false;
    }
}
