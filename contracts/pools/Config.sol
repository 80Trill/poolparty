pragma solidity ^0.4.19;
import "./Admin.sol";

contract Config is Admin{
  //--------------------------------------------------------------
  //CONSTANTS
  enum OptionUint256{
    /**
    * In ETH
    */
    MAX_ALLOCATION,
    /**
    * In ETH
    */
    MIN_CONTRIBUTION,
    /**
    * In ETH
    */
    MAX_CONTRIBUTION,
    /**
    * number of decimal places for the ADMIN_FEE_PERCENTAGE --- capped at 20 decimal places
    */
    ADMIN_FEE_PERCENTAGE_DECIMALS,
    /**
    * uses ADMIN_FEE_PERCENTAGE_DECIMALS for the decimal places.
    */
    ADMIN_FEE_PERCENTAGE
  }
  uint8 public constant  OPTION_UINT256_SIZE = 5;

  enum OptionBool{
    /**
    * true when the pool requires a whitelist
    */
    HAS_WHITELIST
  }
  uint8 public constant  OPTION_BOOL_SIZE =1;
  uint8 public constant  FEE_PERCENTAGE_DECIMAL_CAP = 20;

  //--------------------------------------------------------------
  // VARIABLES
  /**
  * Holds the addresses of the admins for each pool
  */
  mapping (uint256 => uint256[]) public configsUint256_;
  mapping (uint256 => bool[]) public configsBool_;

  //--------------------------------------------------------------
  // METHODS
  /**
  * @notice Creates a new config entry in both the configsUint256_ command
  * configsBool_ maps for the poolId
  *
  * @param configsUint256 contains all of the configurations for the new pool.
  * if this method succeeds it will be added to the map configsUint256_ for
  * the poolId passed in.
  * @param configsBool contains all of the configurations for the new pool.
  * if this method succeeds it will be added to the map configsBool_ for
  * the poolId passed in.
  * @param poolId The id of the pool the admins are being set to.
  *
  * @return the poolId for the created pool. Throws an exception on failure.
  *
  * @dev throws an exception when:
  *     -the config maps for the poolId has been set
  *     -the config arrays are not the correct size
  *     -the MAX_CONTRIBUTION > MAX_ALLOCATION
  *     -the MIN_CONTRIBUTION > MAX_CONTRIBUTION
  *     -the ADMIN_FEE_PERCENTAGE_DECIMALS > FEE_PERCENTAGE_DECIMAL_CAP
  *     -the ADMIN_FEE_PERCENTAGE >= 100
  */
  function createConfigsForPool(uint256[] configsUint256, bool[] configsBool, uint256 poolId) internal {
    require(configsUint256_[poolId].length == 0);
    require(configsBool_[poolId].length == 0);

    //
    // Test validity of configsUint256
    require(configsUint256.length == OPTION_UINT256_SIZE);
    require(configsBool.length == OPTION_BOOL_SIZE);
    require(configsUint256[uint(OptionUint256.MAX_CONTRIBUTION)] <=  configsUint256[uint(OptionUint256.MAX_ALLOCATION)]);
    require(configsUint256[uint(OptionUint256.MIN_CONTRIBUTION)] <=  configsUint256[uint(OptionUint256.MAX_CONTRIBUTION)]);

    uint256 decimalPlaces = configsUint256[uint(OptionUint256.ADMIN_FEE_PERCENTAGE_DECIMALS)];
    require(decimalPlaces <=FEE_PERCENTAGE_DECIMAL_CAP);

    uint256 adminFeePercentage = configsUint256[uint(OptionUint256.ADMIN_FEE_PERCENTAGE)];

    // verify less than 100%
    require(adminFeePercentage < (10**decimalPlaces)*100);


    //
    // Test validity of configsBool
    require(configsBool.length == OPTION_BOOL_SIZE);

    //
    // saves the config if it passes the validity checking
    configsUint256_[poolId] = configsUint256;
    configsBool_[poolId] = configsBool;

  }



}
