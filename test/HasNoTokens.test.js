
import expectThrow from './helpers/expectThrow';


const HasNoTokens = artifacts.require('PoolParty');
const ERC223TokenMock = artifacts.require('ERC223TokenMock');

contract('HasNoTokens', function (accounts) {
  let hasNoTokens = null;
  let token = null;


    beforeEach(async () => {
        // Create contract and token
        hasNoTokens = await HasNoTokens.new();
        token = await ERC223TokenMock.new(accounts[0], 100);

        // Force token into contract
        await token.transfer(hasNoTokens.address, 10);
        let startBalance = await token.balanceOf.call(hasNoTokens.address);
        assert.equal(startBalance, 10);
    });


    it('should not accept ERC223 tokens', async function () {
    await expectThrow(token.transferERC223(hasNoTokens.address, 10, ''));
  });

  it('should allow owner to reclaim tokens', async function () {
    let ownerStartBalance = await token.balanceOf.call(accounts[0]);
    await hasNoTokens.reclaimToken(token.address);
    let ownerFinalBalance = await token.balanceOf.call(accounts[0]);
    let finalBalance = await token.balanceOf.call(hasNoTokens.address);
    assert.equal(finalBalance.c[0], 0);
    assert.equal(ownerFinalBalance.c[0] - ownerStartBalance.c[0], 10);
  });

  it('should allow only owner to reclaim tokens', async function () {
    await expectThrow(
      hasNoTokens.reclaimToken(token.address, { from: accounts[1] }),
    );
  });
});
