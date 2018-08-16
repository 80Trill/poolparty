
import expectThrow from './helpers/expectThrow';
import toPromise from './helpers/toPromise';
const HasNoEtherTest = artifacts.require('PoolParty');
const ForceEther = artifacts.require('ForceEther');

contract('HasNoEther', function (accounts) {
  const amount = 100000;

  it('should be constructorable', async function () {
    await HasNoEtherTest.new();
  });

  it('should allow owner to reclaim ether', async function () {
    // Create contract
    let hasNoEther = await HasNoEtherTest.new();
    const startBalance = await web3.eth.getBalance(hasNoEther.address);
    assert.equal(startBalance, 0);

    // Force ether into it
    let forceEther = await ForceEther.new({ value: amount });
    await forceEther.destroyAndSend(hasNoEther.address);
    const forcedBalance = await web3.eth.getBalance(hasNoEther.address);
    assert.equal(forcedBalance, amount);

    // Reclaim
    const ownerStartBalance = await web3.eth.getBalance(accounts[0]);
    await hasNoEther.reclaimEther();
    const ownerFinalBalance = await web3.eth.getBalance(accounts[0]);
    const finalBalance = await web3.eth.getBalance(hasNoEther.address);
    assert.equal(finalBalance, 0);
    assert.isAbove(ownerFinalBalance.c[0], ownerStartBalance.c[0]);
  });

  it('should allow only owner to reclaim ether', async function () {
    // Create contract
    let hasNoEther = await HasNoEtherTest.new({ from: accounts[0] });

    // Force ether into it
    let forceEther = await ForceEther.new({ value: amount });
    await forceEther.destroyAndSend(hasNoEther.address);
    const forcedBalance = await web3.eth.getBalance(hasNoEther.address);
    assert.equal(forcedBalance, amount);

    // Reclaim
    await expectThrow(hasNoEther.reclaimEther({ from: accounts[1] }));
  });
});
