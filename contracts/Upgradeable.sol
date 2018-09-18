pragma solidity ^0.4.24;


contract Upgradeable {
    mapping(bytes4=>uint32) _upgradeable_sizes;
    address _upgradeable_impl;

    // function getRValueSigs() returns (mapping(bytes4=>uint32));
    function initializeForUpgrades();

    /**
     * Performs a handover to a new implementing contract.
     */
    function replace(address target) internal {
        _upgradeable_impl = target;
        // _upgradeable_sizes = Upgradeable(target).getRValueSigs();
        // Upgradeable(target).
        // target.delegatecall(bytes4(keccak256("initializeForUpgrades()")));
    }
}

contract Dispatcher is Upgradeable {

    constructor(address target) {
        replace(target);
    }

    event Upgraded(address indexed implementation);

    function initialize() {
        // Should only be called by on target contracts, not on the dispatcher
        revert();
    }

    function () payable public {
        address _impl = _upgradeable_impl;
        require(_upgradeable_impl != address(0));
        bytes memory data = msg.data;
        assembly {
          let result := delegatecall(gas, _impl, add(data, 0x20), mload(data), 0, 0)
          let size := returndatasize
          let ptr := mload(0x40)
          returndatacopy(ptr, 0, size)
          switch result
          case 0 { revert(ptr, size) }
          default { return(ptr, size) }
        }
    }

//    function() payable public {
//        bytes4 sig;
//        assembly { sig := calldataload(0) }
//        var len = _sizes[sig];
//        var target = _dest;
//        // bytes memory data = msg.data;
//
//        assembly {
//            calldatacopy(0x0, 0x0, calldatasize)
//            delegatecall(sub(gas, 10000), target, 0x0, calldatasize, 0, len)
//            return(0, len)
//        }
//    }
}

//contract Example is Upgradeable {
//    uint _value;
//
//    function initialize() {
//        _sizes[bytes4(sha3("getUint()"))] = 32;
//    }
//
//    function getUint() returns (uint) {
//        return _value;
//    }
//
//    function setUint(uint value) {
//        _value = value;
//    }
//}