import assertRevert from 'zeppelin-solidity/test/helpers/assertRevert.js';
import Constants from './TestConstants.js';


const CONTRACT = artifacts.require('PoolParty');


contract('USER -- Pool Creation with whitelist', function (accounts) {


    const USER_ADMIN_0 = accounts[0];
    const USER_ADMIN_1 = accounts[1];
    const USER_2 = accounts[2];
    const USER_3 = accounts[3];
    const USER_4 = accounts[4];
    const USER_5 = accounts[5];
    const USER_6 = accounts[6];

    const USER_ACCOUNTS = [USER_ADMIN_0, USER_ADMIN_1, USER_2, USER_3];
    const ADMIN_ACCOUNTS = [USER_ADMIN_0, USER_ADMIN_1];

    const baseAccountAmount = Constants.baseAccountAmount;

    beforeEach(async function () {
        // Sets up a PoolParty contract
        this.contract = await CONTRACT.new();

    });

    describe('when user has funds in a pool', function () {
        beforeEach(async function () {
            // Sets up a pool contract with whitelist enabled
            this.pool = await Constants.createBasePoolWhitelist(this.contract, ADMIN_ACCOUNTS);

            // Adds addresses to whitelist
            await this.pool.addAddressesToWhitelist(USER_ACCOUNTS, {from: USER_ADMIN_0});

            // Transfer default amount of wei to the pool from each user
            await Constants.sendWeiToContractDefault(USER_ACCOUNTS);
        });


        it('user successfully calls for refund', async function () {
            // Verify the pool has the new baseAccountAmount for the user
            assert(await Constants.checkPoolBalances([USER_2], [baseAccountAmount]));

            // Verifies the amount withdrawn is equal to the difference between the amount sent to contract
            let balance = await web3.eth.getBalance(USER_2).toNumber();
            let result = await this.pool.refund({from: USER_2});
            let gasUsed = result.receipt.gasUsed;
            let balanceAfterWithdraw = await web3.eth.getBalance(USER_2).toNumber();
            let diff = (balanceAfterWithdraw - balance + gasUsed);
            assert.equal(diff, baseAccountAmount);

            // Verify the pool has been emptied
            assert(await Constants.checkPoolBalances([USER_2], [0]));

            // User tries to refund again, when balance is already 0
            await assertRevert(this.pool.refund({from: USER_2}));
        });

        it('admin successfully refunds a user', async function () {
            // Verify the pool has the new baseAccountAmount for the user
            assert(await Constants.checkPoolBalances([USER_2], [baseAccountAmount]));

            // Verifies the amount withdrawn is equal to the difference between the amount sent to contract
            let balance = await web3.eth.getBalance(USER_2).toNumber();
            await this.pool.refundAddress(USER_2,{from: USER_ADMIN_0});
            let balanceAfterWithdraw = await web3.eth.getBalance(USER_2).toNumber();
            let diff = (balanceAfterWithdraw - balance);
            assert.equal(diff, baseAccountAmount);

            // Verify the pool has been emptied
            assert(await Constants.checkPoolBalances([USER_2], [0]));

            // User tries to refund again, when balance is already 0, gets a revert
            await assertRevert(this.pool.refundAddress(USER_2,{from: USER_ADMIN_0}));
        });

        it('admin adds a user to the whiteList', async function () {
            //  User not on list cannot send wei
            await assertRevert(Constants.sendWeiToContractDefault([USER_6]));

            // User on whitelist can send wei, before another user has been added
            await Constants.sendWeiToContract([USER_3], [20]);

            // User tries to send wei, and cannot.
            await assertRevert(Constants.sendWeiToContractDefault([USER_5]));

            // Admin adds them to the whitelist, now they can send wei
            await this.pool.addAddressesToWhitelist([USER_5] ,{from: USER_ADMIN_0});
            await Constants.sendWeiToContractDefault([USER_5]);
            assert(await Constants.checkPoolBalances([USER_5], [baseAccountAmount]));

            // User from before can still add wei, they are unaffected by the extra person being added to whitelist
            await Constants.sendWeiToContract([USER_2], [20]);

            //  User not on list can still not send wei even with another user added to whitelist
            await assertRevert(Constants.sendWeiToContractDefault([USER_6]));
        });

        it('admin removes an address from whitelist, and sends refund', async function () {
            // User was not on the original whitelist
            await assertRevert(this.pool.removeAddressFromWhitelistAndRefund(accounts[7], {from: USER_ADMIN_0}));

            // User on whitelist can send wei, before another user has been added
            await Constants.sendWeiToContract([USER_3], [10]);
            assert(await Constants.checkPoolBalances([USER_3], [baseAccountAmount + 10]));

            // User is removed from list and refunded
            await this.pool.removeAddressFromWhitelistAndRefund(USER_3, {from: USER_ADMIN_0});

            // User is no longer on the whitelist, and should revert when they try to send wei
            await assertRevert(Constants.sendWeiToContract([USER_3], [10]));
        });

        it('admin cancels pool, Users call for refunds', async function () {
            // Check the balances of Users before calling for refunds
            assert(await Constants.checkPoolBalances(USER_ACCOUNTS, [baseAccountAmount, baseAccountAmount, baseAccountAmount, baseAccountAmount]));

            // Calls refund for the USER_ACCOUNTS
            await Constants.claimRefunds(USER_ACCOUNTS);


            // Admin sets pool to cancelled, balances should be refunded
            await this.pool.setPoolToCancelled({from: USER_ADMIN_0});

            // Non Admin tries to call setPoolToCancelled
            await assertRevert(this.pool.setPoolToCancelled({from: USER_2}));
            assert(await Constants.checkPoolBalances(USER_ACCOUNTS, [0, 0, 0, 0]));
        });

        it('receiver gets all the wei in the contract', async function () {
            // Admin sets pool to CLOSED and checks that balances are correct

            await this.pool.setPoolToClosed({from: USER_ADMIN_0});
            assert(await Constants.checkPoolBalances(USER_ACCOUNTS, [baseAccountAmount, baseAccountAmount, baseAccountAmount, baseAccountAmount]));
            assert.equal(await this.pool.weiRaised(), baseAccountAmount * 4);

            // Gets the balance from before transferWei call
            let balance = await web3.eth.getBalance(USER_4).toNumber();

            // NonAdmin tries to call transferWei
            await assertRevert(this.pool.transferWei(USER_4, {from: accounts[7]}));

            // Admin gets the fee into his account,
            // Verifies the amount withdrawn is equal to the difference between the amount sent to contract
            let balanceAdmin = await web3.eth.getBalance(USER_ADMIN_0).toNumber();
            let resultAdmin = await this.pool.transferWei(USER_4, {from: USER_ADMIN_0});
            let gasUsedAdmin = resultAdmin.receipt.gasUsed;
            let balanceAfterWithdrawAdmin = await web3.eth.getBalance(USER_ADMIN_0).toNumber();
            let diffAdmin = (balanceAfterWithdrawAdmin - balanceAdmin + gasUsedAdmin);

            // check if the difference is == to the admin fee, 5% of 200 in this case
            assert.equal(diffAdmin, 10);

            // Verifies the amount transferred is the same amount as weiBalance_
            let balanceAfterTransfer = await web3.eth.getBalance(USER_4).toNumber();
            let diff = (balanceAfterTransfer - balance);
            assert.equal(diff, baseAccountAmount * 4 - diffAdmin);
        });

    });
});
