
var WyreYesComplianceToken = artifacts.require("./WyreYesComplianceToken");

module.exports = function(deployer) {
  // deployer.deploy(ConvertLib);
  // deployer.link(ConvertLib, MetaCoin);
  deployer.deploy(WyreYesComplianceToken);
};
