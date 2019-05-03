pragma solidity ^0.4.24;

contract EqualVotingSystem {
    mapping(address => bool) public qualifiedVoters;
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
            }
        }
    }

    function addQualifiedVoters(address[] _voters) external qualifiedVotersUpdatable {
        addQualifiedVotersInternal(_voters);
    }

    function deleteQualifiedVoters(address[] _voters) external qualifiedVotersUpdatable {
        for (uint i = 0; i < _voters.length; i++) {
            delete qualifiedVoters[_voters[i]];
        }
    }

    function totalPower() public view returns (uint256) {
        if (openToPublic) {
            return 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }
        return numOfQualifiedVoters;
    }

    function powerOf(address addr) public view returns (uint256) {
        if (openToPublic) {
            return 1;
        }
        if (qualifiedVoters[addr]) {
            return 1;
        }
        return 0;
    }
}