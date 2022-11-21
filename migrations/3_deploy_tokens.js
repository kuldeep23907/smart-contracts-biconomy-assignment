const MintableERC20 = artifacts.require('MintableERC20');

module.exports = async function (deployer) {
  // await deployer.deploy(MintableERC20, 'Token A', 'TOKENA');
  // const tokenA = await MintableERC20.deployed();
  // await tokenA.mint(web3.utils.toWei('100000', 'kether')); // 100,000,000 TOKENA

  await deployer.deploy(MintableERC20, 'Token B', 'TOKENB');
  const tokenB = await MintableERC20.deployed();
  await tokenB.mint(web3.utils.toWei('100000', 'kether')); // 100,000,000 TOKENB
};
