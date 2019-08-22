pragma solidity ^0.4.22;

contract IssueBase {
    string public title;
    string public description;
    bool public canRevote;
    uint8 public maxNumOfChoices;
    uint256 public duration;

    function description() external view returns (string) {
        return description;
    }
}
