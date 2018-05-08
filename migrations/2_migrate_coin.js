var MyContract = artifacts.require("WildCoin");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(MyContract);
};
