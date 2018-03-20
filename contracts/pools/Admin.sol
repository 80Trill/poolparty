pragma solidity ^0.4.19;
import "../helpers/SafeMath.sol";

contract Admin{
  using SafeMath for uint256;

  //--------------------------------------------------------------
  // VARIABLES
  /**
  * Holds the addresses of the admins for each pool
  */
  mapping (uint256 => address[]) public admins_;



  //--------------------------------------------------------------
  // METHODS
  /**
  * @notice Creates a new entry in the admins_ mapping for the designated poolId
  *
  * @param admins The list of admin addresses for the new pools. This list must include
  * the creator of the pool.
  * @param poolId The id of the pool the admins are being set to.
  *
  * @dev throws an exceptionwhen admins is empty, or if the admins_ map for the
  * poolId has more than one address inside before the function is called.
  */
  function createAdminsForPool(address[] admins, uint256 poolId) internal {
    require(admins_[poolId].length == 0);
    require(admins.length > 0);
    admins_[poolId] = admins;
  }
}
