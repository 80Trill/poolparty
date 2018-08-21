
import expectThrow from './helpers/expectThrow';
const { ethSendTransaction, ethGetBalance } = require('./helpers/web3');


import toPromise from './helpers/toPromise';
const HasNoEtherTest = artifacts.require('PoolParty');
const ForceEther = artifacts.require('ForceEther');

const BigNumber = web3.BigNumber;

require('chai')
    .use(require('chai-bignumber')(BigNumber))
    .should();

contract('HasNoEther', function ([_, owner, anyone]) {
    const amount = web3.toWei('1000', 'ether');

    beforeEach(async function () {
        this.hasNoEther = await HasNoEtherTest.new({ from: owner });
    });

    it('should not accept ether', async function () {
        await expectThrow(
            ethSendTransaction({
                from: owner,
                to: this.hasNoEther.address,
                value: amount,
            }),
        );
    });

    it('should allow owner to reclaim ether', async function () {
        const startBalance = await ethGetBalance(this.hasNoEther.address);
        startBalance.should.be.bignumber.equal(0);

        // Force ether into it
        const forceEther = await ForceEther.new({ value: amount });
        await forceEther.destroyAndSend(this.hasNoEther.address);
        (await ethGetBalance(this.hasNoEther.address)).should.be.bignumber.equal(amount);

        // Reclaim
        const ownerStartBalance = await ethGetBalance(owner);
        await this.hasNoEther.reclaimEther({ from: owner });
        const ownerFinalBalance = await ethGetBalance(owner);
        ownerFinalBalance.should.be.bignumber.gt(ownerStartBalance);

        (await ethGetBalance(this.hasNoEther.address)).should.be.bignumber.equal(0);
    });

    it('should allow only owner to reclaim ether', async function () {
        // Force ether into it
        const forceEther = await ForceEther.new({ value: amount });
        await forceEther.destroyAndSend(this.hasNoEther.address);
        (await ethGetBalance(this.hasNoEther.address)).should.be.bignumber.equal(amount);

        // Reclaim
        await expectThrow(this.hasNoEther.reclaimEther({ from: anyone }));
    });
});
