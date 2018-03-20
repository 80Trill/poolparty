pragma solidity ^0.4.19;
import "./Accounts.sol";
import "./pools/Pools.sol";

contract PoolParty is Accounts, Pools{
    /**
     * @notice Constructor that gives msg.sender all of existing tokens.
     */
    function PoolParty() public {
      accountsBalance_ = 0;
    }
}
