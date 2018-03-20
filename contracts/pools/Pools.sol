pragma solidity ^0.4.19;
import "./Whitelist.sol";

contract Pools is Whitelist {
  event PoolCreated(
    uint256 poolId,
    address creator
  );

  //--------------------------------------------------------------
  // VARIABLES
  /**
  * Holds the user's ETH balance that they have transfered from their
  * accounts_ to a designated pool.
  */
  mapping (uint256 => mapping (address => uint256)) public pools_;

  /**
  * The maximum number of pool allowed in the contract
  *
  * @dev set to 2^256 -2 to prevent nextPoolId_ from overflowing to 0.
  */
   uint256 public constant maxPools_ = 2**256 -2;


  /**
  * When a new pool is created, this value is used as the poolId and then
  * it is incremented.
  */
  uint256 public nextPoolId_ = 0;

  //--------------------------------------------------------------
  // METHODS
  /**
  * @notice Creates a new pool with the pool creator as the admin.
  *
  * @param admins The list of admin addresses for the new pools. This list must include
  * the creator of the pool.
  * @param configsUint256 contains all of the configurations for the new pool.
  * refer to Config.sol file for a list of the configurations.
  * @param configsBool contains all of the configurations for the new pool.
  * refer to Config.sol file for a list of the configurations.
  *
  * @return the poolId for the created pool. Throws an exception on failure.
  */
  function createPool(address[] admins, uint256[] configsUint256, bool[] configsBool) public returns (uint256) {
    require(nextPoolId_ < maxPools_);

    createAdminsForPool(admins, nextPoolId_);
    createConfigsForPool(configsUint256, configsBool, nextPoolId_);
    createWhitelistForPool(nextPoolId_);

    PoolCreated(nextPoolId_, msg.sender);
    nextPoolId_ += 1;
    return nextPoolId_-1;
  }

}
