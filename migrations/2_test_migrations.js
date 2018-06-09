var PoolParty = artifacts.require("../contracts/PoolParty.sol");
module.exports = function(deployer) {
  deployer.deploy(PoolParty);
};
