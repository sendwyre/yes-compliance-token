/*

this file shows the steps required to upgrade the on-chain contract, here
referring to the contracts in ExampleUpgrade.sol

 */
var YesComplianceTokenV2ExampleImpl = artifacts.require("YesComplianceTokenV2ExampleImpl");
var Dispatcher = artifacts.require("Dispatcher");

module.exports = function(deployer) {
    // deploy the code
    return deployer.deploy(YesComplianceTokenV2ExampleImpl, "WRONG", "Unused token").then(function(v2) {
        console.log("YesComplianceTokenV2ExampleImpl deployed at ", v2.address, ", initializing dispatcher proxy...");

        // YesComplianceTokenV2Impl.at(v2.address).name.call().then(function(tb) {
        //     console.log("**** name: ", tb); // outputs WRONG
        // });

        // upgrade the dispatcher
        return Dispatcher.at(Dispatcher.address)._upgradeable_assign_delegate(v2.address).then(function(V) {

            YesComplianceTokenV2ExampleImpl.at(Dispatcher.address).name.call().then(function(tb) {
                console.log("**** dispatcher.name: ", tb);
            });

            YesComplianceTokenV2ExampleImpl.at(Dispatcher.address).getTestBullshit.call().then(function(tb) {
                console.log("**** dispatcher.getTestBullshit: ", tb);
            });

            return V;
        });
    });
};

