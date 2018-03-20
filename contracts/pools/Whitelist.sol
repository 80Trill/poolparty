pragma solidity ^0.4.19;
import "./State.sol";

contract Whitelist is State{
  //--------------------------------------------------------------
  // VARIABLES
  /**
  * Holds the whitelist adresses for  each pool
  */
  mapping (uint256 => address[]) public whitelist_;



  //--------------------------------------------------------------
  // METHODS
  /**
  * @notice Creates a new entry in the whitelist_ mapping for the designated poolId
  *
  * @param poolId The id of the pool the admins are being set to.
  *
  * @dev throws an exception if the admins_ map for the poolId has more than one
  * address inside before the function is called.
  */
  function createWhitelistForPool(uint256 poolId) internal view{
    require(whitelist_[poolId].length == 0);
  }
}
