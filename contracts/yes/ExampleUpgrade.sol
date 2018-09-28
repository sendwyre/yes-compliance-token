pragma solidity ^0.4.24;

import "./YesComplianceTokenV1.sol";
import "./YesComplianceTokenImpl.sol";

contract YesComplianceTokenV2Example is YesComplianceTokenV1 {
    function getTestBullshit() external view returns(string);
}

contract YesComplianceTokenV2ExampleImpl is YesComplianceTokenV1Impl, YesComplianceTokenV2Example {

    string testBullshit;

    constructor(string _name, string _symbol) public YesComplianceTokenV1Impl(_name, _symbol) {}

    function _upgradeable_initialize() public {
        super._upgradeable_initialize();
        testBullshit = "that's some bullshit";
    }

    function getTestBullshit() external view returns(string) {
        return testBullshit;
    }
}

