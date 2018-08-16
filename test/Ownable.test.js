import shouldBehaveLikeOwnable from './Ownable.behaviour';

const Ownable = artifacts.require('PoolParty');

contract('Ownable', function (accounts) {
  beforeEach(async function () {
    this.ownable = await Ownable.new();
  });

  shouldBehaveLikeOwnable(accounts);
});
