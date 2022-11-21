const TimeLockedWallet = artifacts.require('TimeLockedWallet');

module.exports = function (deployer) {
  deployer.deploy(TimeLockedWallet);
};
