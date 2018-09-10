pragma solidity ^0.4.24;

import "./YesComplianceTokenV1.sol";

contract WyreYesComplianceToken is YesComplianceTokenV1 {

    constructor() public YesComplianceTokenV1('WYRE-YES', 'Wyre YES Compliance Token') {
        ownerAddress = msg.sender;
    }

}