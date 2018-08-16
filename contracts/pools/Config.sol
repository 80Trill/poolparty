pragma solidity 0.4.24;


import "./State.sol";


/// @title Uint256 and boolean configurations for Pool.sol contracts.
contract Config is State {
    enum OptionUint256{
        MAX_ALLOCATION,
        MIN_CONTRIBUTION,
        MAX_CONTRIBUTION,

        // Number of decimal places for the ADMIN_FEE_PERCENTAGE - capped at FEE_PERCENTAGE_DECIMAL_CAP.
        ADMIN_FEE_PERCENT_DECIMALS,

        // The percentage of admin fee relative to the amount of ADMIN_FEE_PERCENT_DECIMALS.
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
    /// @dev This will not retroactively effect previous contributions.
    /// This will only be applied to contributions moving forward.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - Max contribution is <= the max allocation
    ///     - Minimum contribution is <= max contribution
    ///     - The pool state is currently set to OPEN or CLOSED
    /// @param _min The new minimum contribution for this pool.
    /// @param _max The new maximum contribution for this pool.
    function setMinMaxContribution(
        uint256 _min,
        uint256 _max
    )
        public
        isAdmin
        isOpenOrClosed
    {
        // Max contribution is greater than max allocation!
        require(_max <= maxAllocation);
        // Minimum contribution is greater than max contribution!
        require(_min <= _max);

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
    /// @param _configsUint contains all of the uint256 configurations.
    /// The indexes are as follows:
    ///     - MAX_ALLOCATION
    ///     - MIN_CONTRIBUTION
    ///     - MAX_CONTRIBUTION
    ///     - ADMIN_FEE_PERCENT_DECIMALS
    ///     - ADMIN_FEE_PERCENTAGE
    /// @param _configsBool contains all of the  boolean configurations.
    /// The indexes are as follows:
    ///     - HAS_WHITELIST
    ///     - ADMIN_FEE_PAYOUT
    function createConfigsForPool(
        uint256[] _configsUint,
        bool[] _configsBool
    )
        internal
    {
        // Wrong number of uint256 configurations!
        require(_configsUint.length == OPTION_UINT256_SIZE);
        // Wrong number of boolean configurations!
        require(_configsBool.length == OPTION_BOOL_SIZE);

        // Sets the uint256 configurations.
        maxAllocation = _configsUint[uint(OptionUint256.MAX_ALLOCATION)];
        minContribution = _configsUint[uint(OptionUint256.MIN_CONTRIBUTION)];
        maxContribution = _configsUint[uint(OptionUint256.MAX_CONTRIBUTION)];
        adminFeePercentageDecimals = _configsUint[uint(OptionUint256.ADMIN_FEE_PERCENT_DECIMALS)];
        adminFeePercentage = _configsUint[uint(OptionUint256.ADMIN_FEE_PERCENTAGE)];

        // Sets the boolean values.
        hasWhitelist = _configsBool[uint(OptionBool.HAS_WHITELIST)];
        adminFeePayoutIsToken = _configsBool[uint(OptionBool.ADMIN_FEE_PAYOUT_TOKENS)];

        // @dev Test the validity of _configsUint.
        // Number of decimals used for admin fee greater than cap!
        require(adminFeePercentageDecimals <= FEE_PERCENTAGE_DECIMAL_CAP);
        // Max contribution is greater than max allocation!
        require(maxContribution <= maxAllocation);
        // Minimum contribution is greater than max contribution!
        require(minContribution <= maxContribution);

        // Verify the admin fee is less than 100%.
        feePercentageDivisor = (10 ** adminFeePercentageDecimals).mul(100);
        // Admin fee percentage is >= %100!
        require(adminFeePercentage < feePercentageDivisor);
    }
}
