var YesComplianceTokenV1Impl = artifacts.require("YesComplianceTokenV1Impl");
var YesComplianceTokenV1 = artifacts.require("YesComplianceTokenV1");
var Dispatcher = artifacts.require("Dispatcher");

// NOTE dunno why tf the async approach ain't a werkin
// module.exports = async function(deployer) {
//     // deployer.deploy(ConvertLib);
//     // deployer.link(ConvertLib, MetaCoin);
//
//     await deployer.deploy(Dispatcher, 1); //, WyreYesComplianceToken.address);
//     console.log("!!! Deployed Dispatcher ", Dispatcher.address);
//
//     await deployer.deploy(WyreYesComplianceToken);
//     console.log("!!! Deployed WyreYesComplianceToken: ", WyreYesComplianceToken.address);
// };


module.exports = function(deployer) {
    return deployer.deploy(YesComplianceTokenV1Impl, "WRONG", "Unused token").then(function(r1) {
        console.log("Code-only YesComplianceTokenImpl deployed at ", r1.address, ", initializing dispatcher+storage...");

        // that deployment is just for its code, not data.

        return deployer.deploy(Dispatcher, r1.address).then(function(r2) {
            console.log("Dispatcher proxy deployed at: ", r2.address);
            console.log("ZZ: ", YesComplianceTokenV1Impl.at(r2.address));

            let r2_yes = YesComplianceTokenV1.at(r2.address);

            return YesComplianceTokenV1Impl.at(r2.address).initialize("WYRE-YES", "Wyre Compliance Verification Token")
                .then(function(r3) {
                    console.log("Fully deployed");

                    // r2_yes.ownerAddress.call().then(function(r) {
                    //     console.log("2 ownerAddress: ", r);
                    // });

                    r2_yes.name.call().then(function(r) {
                        console.log("2 name: ", r);
                    });

                    // let r2_yes = YesComplianceTokenV1.at(r2.address);
                });
        });
    });
};
