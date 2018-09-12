pragma solidity ^0.4.24;

import "./YesComplianceTokenImpl.sol";

contract WyreYesComplianceToken is YesComplianceTokenImpl {

    constructor() public YesComplianceTokenV1('WYRE-YES', 'Wyre YES Compliance Token') {

    }

}