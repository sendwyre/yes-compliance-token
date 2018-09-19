//pragma solidity ^0.4.24;
//
//import "./YesComplianceTokenImpl.sol";
//
//contract WyreYesComplianceToken is YesComplianceTokenImplV1 {
//
//    constructor() public {
//        super.initialize('WRONG', 'Please don\'t use this contract', msg.sender);
//        // safety block: the real compliance token lives in the context of a Dispatcher
//    }
//
//    function initialize() public {
//        super.initialize('WYRE-YES', 'Wyre YES Compliance Token', msg.sender);
//    }
//
//}