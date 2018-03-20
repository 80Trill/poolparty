pragma solidity ^0.4.19;
import "./Config.sol";

contract State is Config{
  enum PoolState{
    /**
    * Pool is accepting ETH. Users can refund themeselves in this state.
    */
    OPEN,
    /**
    * Pool is closed and the funds are locked. No refunds allowed.
    */
    CLOSED,
    /**
    * Token is distributed to users and the eth is transfered from their accounts
    * to the admin pool creator account.
    */
    COMPLETE,
    /**
    * Eth is refunded into the accounts_ of the users and the pool is not longer
    * accepthing ETH.
    */
    CANCELLED
  }
  uint8 public constant  POOL_STATE_SIZE = 4;

  //--------------------------------------------------------------
  // VARIABLES
  /**
  * Holds the state for each of pool
  */
  mapping (uint256 => uint8) public state_;

}
