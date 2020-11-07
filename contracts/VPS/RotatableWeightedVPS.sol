pragma solidity ^0.4.24;

import "./WeightedVPS.sol";
import "./ViewBasedVPS.sol";
import "../library/Whitelist.sol";

contract RotatableWeightedVPS is ViewBasedVPS, Whitelist {
    struct WVPS {
        WeightedVPS vps;
        uint256 viewID;
    }

    WVPS[] private vpss;
    uint256 public activeVPSIndex;

    constructor(address[] _addrs, uint256[] _viewIDs) public {
        require(_addrs.length == 2 && _viewIDs.length == 2);
        vpss.push(WVPS(WeightedVPS(_addrs[0]), _viewIDs[0]));
        vpss.push(WVPS(WeightedVPS(_addrs[1]), _viewIDs[1]));
        activeVPSIndex = 1;
    }

    function activeVPS() public view returns (WeightedVPS) {
        return vpss[activeVPSIndex].vps;
    }

    function inactiveVPS() public view returns (WeightedVPS) {
        return vpss[(activeVPSIndex + 1) % 2].vps;
    }

    // rotate to the other wvps and set its view ID
    function rotate(uint256 newViewID) external onlyWhitelisted {
        uint256 currentViewID = viewID();
        activeVPSIndex = (activeVPSIndex + 1) % 2;
        require(currentViewID < newViewID);
        vpss[activeVPSIndex].viewID = newViewID;
        activeVPS().unpause();
    }

    function updateVotingPowers(address[] _voters, uint256[] _powers) external onlyWhitelisted {
        vpss[(activeVPSIndex + 1) % 2].vps.updateVotingPowers(_voters, _powers);
    }

    function totalPower() external view returns (uint256) {
        return activeVPS().totalPower();
    }

    function powersOf(address[] _voters) external view returns (uint256[]) {
        return activeVPS().powersOf(_voters);
    }

    function powerOf(address _voter) external view returns (uint256) {
        return activeVPS().powerOf(_voter);
    }

    function voters(uint256 _offset, uint256 _limit) public view returns (address[] voters_) {
        return activeVPS().voters(_offset, _limit);
    }

    function paused() external view returns (bool) {
        return activeVPS().paused();
    }

    function viewID() public view returns (uint256) {
        return vpss[activeVPSIndex].viewID;
    }

    function inactiveViewID() public view returns (uint256) {
        return vpss[(activeVPSIndex + 1) % 2].viewID;
    }
}
