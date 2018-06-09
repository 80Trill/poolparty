pragma solidity ^0.4.23;


import "./State.sol";


/// @title Uint256 and boolean configurations for Pool.sol contracts.
contract Config is State {
    enum OptionUint256{
        MAX_ALLOCATION,
        MIN_CONTRIBUTION,
        MAX_CONTRIBUTION,

        // Number of decimal places for the ADMIN_FEE_PERCENTAGE - capped at FEE_PERCENTAGE_DECIMAL_CAP.
        ADMIN_FEE_PERCENTAGE_DECIMALS,

        // The percentage of admin fee relative to the amount of ADMIN_FEE_PERCENTAGE_DECIMALS.
        ADMIN_FEE_PERCENTAGE
    }

    enum OptionBool{
        // True when the pool requires a whitelist.
        HAS_WHITELIST,

        // Uses ADMIN_FEE_PAYOUT_METHOD - true = tokens, false = ether.
        ADMIN_FEE_PAYOUT_TOKENS
    }

    uint8 public constant  OPTION_UINT256_SIZE = 5;
    uint8 public constant  OPTION_BOOL_SIZE = 2;
    uint8 public constant  FEE_PERCENTAGE_DECIMAL_CAP = 5;

    uint256 public maxAllocation;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public adminFeePercentageDecimals;
    uint256 public adminFeePercentage;
    uint256 public feePercentageDivisor;

    bool public hasWhitelist;
    bool public adminFeePayoutIsToken;

    /// @notice Sets the min and the max contribution configurations.
    /// @dev This will not retroactively effect previous contributions. This will only be applied to contributions moving forward.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - Max contribution is <= the max allocation
    ///     - Minimum contribution is <= max contribution
    ///     - The pool state is currently set to OPEN or CLOSED
    /// @param _min The new minimum contribution for this pool.
    /// @param _max The new maximum contribution for this pool.
    function setMinMaxContribution(uint256 _min, uint256 _max) public isAdmin isOpenOrClosed {
        require(_max <= maxAllocation); // Max contribution is greater than max allocation!
        require(_min <= _max); // Minimum contribution is greater than max contribution!

        minContribution = _min;
        maxContribution = _max;
    }

    /// @dev Validates and sets the configurations for the new pool.
    /// Throws an exception when:
    ///     - The config arrays are not the correct size
    ///     - The maxContribution > maxAllocation
    ///     - The minContribution > maxContribution
    ///     - The adminFeePercentageDecimals > FEE_PERCENTAGE_DECIMAL_CAP
    ///     - The adminFeePercentage >= 100
    /// @param _configsUint256 contains all of the uint256 configurations.
    /// The indexes are as follows:
    ///     - MAX_ALLOCATION
    ///     - MIN_CONTRIBUTION
    ///     - MAX_CONTRIBUTION
    ///     - ADMIN_FEE_PERCENTAGE_DECIMALS
    ///     - ADMIN_FEE_PERCENTAGE
    /// @param _configsBool contains all of the  boolean configurations.
    /// The indexes are as follows:
    ///     - HAS_WHITELIST
    ///     - ADMIN_FEE_PAYOUT
    function createConfigsForPool(uint256[] _configsUint256, bool[] _configsBool) internal {
        require(_configsUint256.length == OPTION_UINT256_SIZE); // Wrong number of uint256 configurations!
        require(_configsBool.length == OPTION_BOOL_SIZE); // Wrong number of boolean configurations!

        // Sets the uint256 configurations.
        maxAllocation = _configsUint256[uint(OptionUint256.MAX_ALLOCATION)];
        minContribution = _configsUint256[uint(OptionUint256.MIN_CONTRIBUTION)];
        maxContribution = _configsUint256[uint(OptionUint256.MAX_CONTRIBUTION)];
        adminFeePercentageDecimals = _configsUint256[uint(OptionUint256.ADMIN_FEE_PERCENTAGE_DECIMALS)];
        adminFeePercentage = _configsUint256[uint(OptionUint256.ADMIN_FEE_PERCENTAGE)];
        // Sets the boolean values.
        hasWhitelist = _configsBool[uint(OptionBool.HAS_WHITELIST)];
        adminFeePayoutIsToken = _configsBool[uint(OptionBool.ADMIN_FEE_PAYOUT_TOKENS)];

        // Test the validity of _configsUint256.
        require(adminFeePercentageDecimals <= FEE_PERCENTAGE_DECIMAL_CAP); // Number of decimals used for admin fee greater than cap!
        require(maxContribution <= maxAllocation); // Max contribution is greater than max allocation!
        require(minContribution <= maxContribution); // Minimum contribution is greater than max contribution!

        // Verify the admin fee is less than 100%.
        feePercentageDivisor = (10 ** adminFeePercentageDecimals).mul(100);
        require(adminFeePercentage < feePercentageDivisor); // Admin fee percentage is >= %100
    }
}
