pragma solidity 0.4.24;


import "./Whitelist.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol";


/// @title Pool contract functionality and configurations.
contract Pool is Whitelist {
    /// @dev Address points to a boolean indicating if the address has participated in the pool.
    /// Even if they have been refunded and balance is zero
    /// This mapping internally helps us prevent duplicates from being pushed into swimmersList
    /// instead of iterating and popping from the list each time a users balance reaches 0.
    mapping(address => bool) public invested;

    /// @dev Address points to the current amount of wei the address has contributed to the pool.
    /// Even after the wei has been transferred out.
    /// Because the claim tokens function uses swimmers balances to calculate their claimable tokens.
    mapping(address => uint256) public swimmers;
    mapping(address => uint256) public swimmerReimbursements;
    mapping(address => mapping(address => uint256)) public swimmersTokensPaid;
    mapping(address => uint256) public totalTokensDistributed;
    mapping(address => bool) public adminFeePaid;

    address[] public swimmersList;
    address[] public tokenAddress;

    address public poolPartyAddress;
    uint256 public adminWeiFee;
    uint256 public poolId;
    uint256 public weiRaised;
    uint256 public reimbursementTotal;

    event AdminFeePayout(uint256 value);
    event Deposit(address recipient, uint256 value);
    event EtherTransferredOut(uint256 value);
    event ProjectReimbursed(uint256 value);
    event Refund(address recipient, uint256 value);
    event ReimbursementClaimed(address recipient, uint256 value);
    event TokenAdded(address tokenAddress);
    event TokenRemoved(address tokenAddress);
    event TokenClaimed(address recipient, uint256 value, address tokenAddress);

    /// @dev Verifies the msg.sender is the owner.
    modifier isOwner() {
        // This is not the owner!
        require(msg.sender == owner);
        _;
    }

    /// @dev Makes sure that the amount being transferred + the total amount previously sent
    /// is compliant with the configurations for the existing pool.
    modifier depositIsConfigCompliant() {
        // Value sent must be greater than 0!
        require(msg.value > 0);
        uint256 totalRaised = weiRaised.add(msg.value);
        uint256 amount = swimmers[msg.sender].add(msg.value);

        // Contribution will cause pool to be greater than max allocation!
        require(totalRaised <= maxAllocation);
        // Contribution is greater than max contribution!
        require(amount <= maxContribution);
        // Contribution is less than minimum contribution!
        require(amount >= minContribution);
        _;
    }

    /// @dev Verifies the user currently has funds in the pool.
    modifier userHasFundedPool(address _user) {
        // User does not have funds in the pool!
        require(swimmers[_user] > 0);
        _;
    }

    /// @dev Verifies the index parameters are valid/not out of bounds.
    modifier isValidIndex(uint256 _startIndex, uint256 _numberOfAddresses) {
        uint256 endIndex = _startIndex.add(_numberOfAddresses.sub(1));

        // The starting index is out of the array bounds!
        require(_startIndex < swimmersList.length);
        // The end index is out of the array bounds!
        require(endIndex < swimmersList.length);
        _;
    }

    /// @notice Creates a new pool with the parameters as custom configurations.
    /// @dev Creates a new pool where:
    ///     - The creator of the pool will be the owner
    ///     - _admins become administrators for the pool contract and are automatically
    ///      added to whitelist, if it is enabled in the _configsBool
    ///     - Pool is initialised with the state set to OPEN
    /// @param _poolOwner The owner of the new pool.
    /// @param _admins The list of admin addresses for the new pools. This list must include
    /// the creator of the pool.
    /// @param _configsUint Contains all of the uint256 configurations for the new pool.
    ///     - MAX_ALLOCATION
    ///     - MIN_CONTRIBUTION
    ///     - MAX_CONTRIBUTION
    ///     - ADMIN_FEE_PERCENT_DECIMALS
    ///     - ADMIN_FEE_PERCENTAGE
    /// @param _configsBool Contains all of the boolean configurations for the new pool.
    ///     - HAS_WHITELIST
    ///     - ADMIN_FEE_PAYOUT
    /// @param _poolId The corresponding poolId.
    constructor(
        address _poolOwner,
        address[] _admins,
        uint256[] _configsUint,
        bool[] _configsBool,
        uint256  _poolId
    )
        public
    {
        owner = _poolOwner;
        state = PoolState.OPEN;
        poolPartyAddress = msg.sender;
        poolId = _poolId;

        createAdminsForPool(_admins);
        createConfigsForPool(_configsUint, _configsBool);

        if (hasWhitelist) {
            addAddressesToWhitelistInternal(admins);
        }

        emit PoolIsOpen();
    }

    /// @notice The user sends Ether to the pool.
    /// @dev Calls the deposit function on behalf of the msg.sender.
    function() public payable {
        deposit(msg.sender);
    }

    /// @notice Returns the array of admin addresses.
    /// @dev This is used specifically for the Web3 DAPP portion of PoolParty,
    /// as the EVM will not allow contracts to return dynamically sized arrays.
    /// @return Returns and instance of the admins array.
    function getAdminAddressArray(
    )
        public
        view
        returns (address[] _arrayToReturn)
    {
        _arrayToReturn = admins;
    }

    /// @notice Returns the array of token addresses.
    /// @dev This is used specifically for the Web3 DAPP portion of PoolParty,
    /// as the EVM will not allow contracts to return dynamically sized arrays.
    /// @return Returns and instance of the tokenAddress array.
    function getTokenAddressArray(
    )
        public
        view
        returns (address[] _arrayToReturn)
    {
        _arrayToReturn = tokenAddress;
    }

    /// @notice Returns the amount of tokens currently in this contract.
    /// @dev This is used specifically for the Web3 DAPP portion of PoolParty.
    /// @return Returns the length of the tokenAddress arrau.
    function getAmountOfTokens(
    )
        public
        view
        returns (uint256 _lengthOfTokens)
    {
        _lengthOfTokens = tokenAddress.length;
    }

    /// @notice Returns the array of swimmers addresses.
    /// @dev This is used specifically for the DAPP portion of PoolParty,
    /// as the EVM will not allow contracts to return dynamically sized arrays.
    /// @return Returns and instance of the swimmersList array.
    function getSwimmersListArray(
    )
        public
        view
        returns (address[] _arrayToReturn)
    {
        _arrayToReturn = swimmersList;
    }

    /// @notice Returns the amount of swimmers currently in this contract.
    /// @dev This is used specifically for the Web3 DAPP portion of PoolParty.
    /// @return Returns the length of the swimmersList array.
    function getAmountOfSwimmers(
    )
        public
        view
        returns (uint256 _lengthOfSwimmers)
    {
        _lengthOfSwimmers = swimmersList.length;
    }

    /// @notice Deposit Ether where the contribution is credited to the address specified in the parameter.
    /// @dev Allows a user to deposit on the behalf of someone else. Emits a Deposit event on success.
    /// Requires:
    ///     - The pool state is set to OPEN
    ///     - The amount is > 0
    ///     - The amount complies with the configurations of the pool
    ///     - If the whitelist configuration is enabled, verify the _user can deposit
    /// @param _user The address that will be credited with the deposit.
    function deposit(
        address _user
    )
        public
        payable
        isOpen
        depositIsConfigCompliant
        canDeposit(_user)
    {
        if (!invested[_user]) {
            swimmersList.push(_user);
            invested[_user] = true;
        }

        weiRaised = weiRaised.add(msg.value);
        swimmers[_user] = swimmers[_user].add(msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Process a refund.
    /// @dev Allows refunds in the contract. Calls the internal refund function.
    /// Requires:
    ///     - The state of the pool is either OPEN or CANCELLED
    ///     - The user currently has funds in the pool
    function refund() public isUserRefundable userHasFundedPool(msg.sender) {
        processRefundInternal(msg.sender);
    }

    /// @notice This triggers a refund event for a subset of users.
    /// @dev Uses the internal refund function.
    /// Requires:
    ///     - The pool state is currently set to CANCELLED
    ///     - The indexes are within the bounds of the swimmersList
    /// @param _startIndex The starting index for the subset.
    /// @param _numberOfAddresses The number of addresses to include past the starting index.
    function refundManyAddresses(
        uint256 _startIndex,
        uint256 _numberOfAddresses
    )
        public
        isCancelled
        isValidIndex(_startIndex, _numberOfAddresses)
    {
        uint256 endIndex = _startIndex.add(_numberOfAddresses.sub(1));

        for (uint256 i = _startIndex; i <= endIndex; ++i) {
            address user = swimmersList[i];

            if (swimmers[user] > 0) {
                processRefundInternal(user);
            }
        }
    }

    /// @notice claims available tokens.
    /// @dev Allows the user to claim their available tokens.
    /// Requires:
    ///     - The msg.sender has funded the pool
    function claim() public {
        claimAddress(msg.sender);
    }

    /// @notice Process a claim function for a specified address.
    /// @dev Allows the user to claim tokens on behalf of someone else.
    /// Requires:
    ///     - The _address has funded the pool
    ///     - The pool is in the completed state
    /// @param _address The address for which tokens should be redeemed.
    function claimAddress(
        address _address
    )
        public
        isCompleted
        userHasFundedPool(_address)
    {
        for (uint256 i = 0; i < tokenAddress.length; ++i) {
            ERC20Basic token = ERC20Basic(tokenAddress[i]);
            uint256 poolTokenBalance = token.balanceOf(this);

            payoutTokensInternal(_address, poolTokenBalance, token);
        }
    }

    /// @notice Distribute available tokens to a subset of users.
    /// @dev Allows anyone to call claim on a specified series of addresses.
    /// Requires:
    ///     - The indexes are within the bounds of the swimmersList
    /// @param _startIndex The starting index for the subset.
    /// @param _numberOfAddresses The number of addresses to include past the starting index.
    function claimManyAddresses(
        uint256 _startIndex,
        uint256 _numberOfAddresses
    )
        public
        isValidIndex(_startIndex, _numberOfAddresses)
    {
        uint256 endIndex = _startIndex.add(_numberOfAddresses.sub(1));

        claimAddressesInternal(_startIndex, endIndex);
    }

    /// @notice Process a reimbursement claim.
    /// @dev Allows the msg.sender to claim a reimbursement
    /// Requires:
    ///     - The msg.sender has a reimbursement to withdraw
    ///     - The pool state is currently set to AwaitingOrCompleted
    function reimbursement() public {
        claimReimbursement(msg.sender);
    }

    /// @notice Process a reimbursement claim for a specified address.
    /// @dev Calls the internal method responsible for processing a reimbursement.
    /// Requires:
    ///     - The specified user has a reimbursement to withdraw
    ///     - The pool state is currently set to AwaitingOrCompleted
    /// @param _user The user having the reimbursement processed.
    function claimReimbursement(
        address _user
    )
        public
        isAwaitingOrCompleted
        userHasFundedPool(_user)
    {
        processReimbursementInternal(_user);
    }

    /// @notice Process a reimbursement claim for subset of addresses.
    /// @dev Allows anyone to call claimReimbursement on a specified series of address indexes.
    /// Requires:
    ///     - The pool state is currently set to AwaitingOrCompleted
    ///     - The indexes are within the bounds of the swimmersList
    /// @param _startIndex The starting index for the subset.
    /// @param _numberOfAddresses The number of addresses to include past the starting index.
    function claimManyReimbursements(
        uint256 _startIndex,
        uint256 _numberOfAddresses
    )
        public
        isAwaitingOrCompleted
        isValidIndex(_startIndex, _numberOfAddresses)
    {
        uint256 endIndex = _startIndex.add(_numberOfAddresses.sub(1));

        for (uint256 i = _startIndex; i <= endIndex; ++i) {
            address user = swimmersList[i];

            if (swimmers[user] > 0) {
                processReimbursementInternal(user);
            }
        }
    }

    /// @notice Set a new token address where users can redeem ERC20 tokens.
    /// @dev Adds a new ERC20 address to the tokenAddress array.
    /// Sets the pool state to COMPLETED if it is not already.
    /// Crucial that only valid ERC20 addresses be added with this function.
    /// In the event a bad one is entered, it can be removed with the removeToken() method.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is set to either AWAITING_TOKENS or COMPLETED
    ///     - The token address has not previously been added
    /// @param _tokenAddress The ERC20 address users can redeem from.
    function addToken(
        address _tokenAddress
    )
        public
        isAdmin
        isAwaitingOrCompleted
    {
        if (state != PoolState.COMPLETED) {
            setPoolToCompleted();
        }

        for (uint256 i = 0; i < tokenAddress.length; ++i) {
            // The address has already been added!
            require(tokenAddress[i] != _tokenAddress);
        }

        // @dev This verifies the address we are trying to add contains an ERC20 address.
        // This does not completely protect from having a bad address added, but it will reduce the likelihood.
        // Any address that does not contain a balanceOf() method cannot be added.
        ERC20Basic token = ERC20Basic(_tokenAddress);

        // The address being added is not an ERC20!
        require(token.balanceOf(this) >= 0);

        tokenAddress.push(_tokenAddress);

        emit TokenAdded(_tokenAddress);
    }

    /// @notice Remove a token address from the list of token addresses.
    /// @dev Removes a token address. This prevents users from calling claim on it. Does not preserve order.
    /// If it reduces the tokenAddress length to zero, then the state is set back to awaiting tokens.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is set to COMPLETED
    ///     - The token address is located in the list.
    /// @param _tokenAddress The address to remove.
    function removeToken(address _tokenAddress) public isAdmin isCompleted {
        for (uint256 i = 0; i < tokenAddress.length; ++i) {
            if (tokenAddress[i] == _tokenAddress) {
                tokenAddress[i] = tokenAddress[tokenAddress.length - 1];
                delete tokenAddress[tokenAddress.length - 1];
                tokenAddress.length--;
                break;
            }
        }

        if (tokenAddress.length == 0) {
            setPoolToAwaitingTokens();
        }

        emit TokenRemoved(_tokenAddress);
    }

    /// @notice Removes a user from the whitelist and processes a refund.
    /// @dev Removes a user from the whitelist and their ability to contribute to the pool.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is currently set to OPEN or CLOSED or CANCELLED
    ///     - The pool has enabled whitelist functionality
    /// @param _address The address for which the refund is processed and removed from whitelist.
    function removeAddressFromWhitelistAndRefund(
        address _address
    )
        public
        isWhitelistEnabled
        canDeposit(_address)
    {
        whitelist[_address] = false;
        refundAddress(_address);
    }

    /// @notice Refund a given address for all the Ether they have contributed.
    /// @dev Processes a refund for a given address by calling the internal refund function.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is currently set to OPEN or CLOSED or CANCELLED
    /// @param _address The address for which the refund is processed.
    function refundAddress(
        address _address
    )
        public
        isAdmin
        isAdminRefundable
        userHasFundedPool(_address)
    {
        processRefundInternal(_address);
    }

    /// @notice Provides a refund for the entire list of swimmers
    /// to distribute at a pro-rata rate via the reimbursement functions.
    /// @dev Refund users after the pool state is set to AWAITING_TOKENS or COMPLETED.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The state is either Awaiting or Completed
    function projectReimbursement(
    )
        public
        payable
        isAdmin
        isAwaitingOrCompleted
    {
        reimbursementTotal = reimbursementTotal.add(msg.value);

        emit ProjectReimbursed(msg.value);
    }

    /// @notice Sets the maximum allocation for the contract.
    /// @dev Set the uint256 configuration for maxAllocation to the _newMax parameter.
    /// If the amount of weiRaised so far is already past the limit,
    //  no further deposits can be made until the weiRaised is reduced
    /// Possibly by refunding some users.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is currently set to OPEN or CLOSED
    ///     - The _newMax must be >= max contribution
    /// @param _newMax The new maximum allocation for this pool contract.
    function setMaxAllocation(uint256 _newMax) public isAdmin isOpenOrClosed {
        // Max Allocation cannot be below Max contribution!
        require(_newMax >= maxContribution);

        maxAllocation = _newMax;
    }

    /// @notice Transfers the Ether out of the contract to the given address parameter.
    /// @dev If admin fee is > 0, then call payOutAdminFee to distribute the admin fee.
    /// Sets the pool state to AWAITING_TOKENS.
    /// Requires:
    ///     - The pool state must be currently set to CLOSED
    ///     - msg.sender is the owner
    /// @param _contractAddress The address to send all Ether in the pool.
    function transferWei(address _contractAddress) public isOwner isClosed {
        uint256 weiForTransfer = weiTransferCalculator();

        if (adminFeePercentage > 0) {
            weiForTransfer = payOutAdminFee(weiForTransfer);
        }

        // No Ether to transfer!
        require(weiForTransfer > 0);
        _contractAddress.transfer(weiForTransfer);

        setPoolToAwaitingTokens();

        emit EtherTransferredOut(weiForTransfer);
    }

    /// @dev Calculates the amount of wei to be transferred out of the contract.
    /// Adds the difference to the refund total for participants to withdraw pro-rata from.
    /// @return The difference between amount raised and the max allocation.
    function weiTransferCalculator() internal returns (uint256 _amountOfWei) {
        if (weiRaised > maxAllocation) {
            _amountOfWei = maxAllocation;
            reimbursementTotal = reimbursementTotal.add(weiRaised.sub(maxAllocation));
        } else {
            _amountOfWei = weiRaised;
        }
    }

    /// @dev Payout the owner of this contract, based on the adminFeePayoutIsToken boolean.
    ///  - adminFeePayoutIsToken == true -> The payout is in tokens.
    /// Each member will have their portion deducted from their contribution before claiming tokens.
    ///  - adminFeePayoutIsToken == false -> The adminFee is deducted from the total amount of wei
    /// that would otherwise be transferred out of the contract.
    /// @return The amount of wei that will be transferred out of this function.
    function payOutAdminFee(
        uint256 _weiTotal
    )
        internal
        returns (uint256 _weiForTransfer)
    {
        adminWeiFee = _weiTotal.mul(adminFeePercentage).div(feePercentageDivisor);

        if (adminFeePayoutIsToken) {
            // @dev In the event the owner has wei currently contributed to the pool,
            // their fee is collected before they get credited on line 420.
            if (swimmers[owner] > 0) {
                collectAdminFee(owner);
            } else {
                // @dev In the event the owner has never contributed to the pool,
                // they have their address added so they can be iterated over in the claim all method.
                if (!invested[owner]) {
                    swimmersList.push(owner);
                    invested[owner] = true;
                }

                adminFeePaid[owner] = true;
            }

            // @dev The admin gets credited for his fee upfront.
            // Then the first time a swimmer claims their tokens, they will have their portion
            // of the fee deducted from their contribution, via the collectAdminFee() method.
            swimmers[owner] = swimmers[owner].add(adminWeiFee);
            _weiForTransfer = _weiTotal;
        } else {
            _weiForTransfer = _weiTotal.sub(adminWeiFee);

            if (adminWeiFee > 0) {
                owner.transfer(adminWeiFee);

                emit AdminFeePayout(adminWeiFee);
            }
        }
    }

    /// @dev The internal claim function for distributing available tokens.
    /// Goes through each of the token addresses set by the addToken function,
    /// and calculates a pro-rata rate for each pool participant to be distributed.
    /// In the event that a bad token address is present, and the transfer function fails,
    /// this method cannot be processed until
    /// the bad address has been removed via the removeToken() method.
    /// Requires:
    ///     - The pool state must be set to COMPLETED
    ///     - The tokenAddress array must contain ERC20 compliant addresses.
    /// @param _startIndex The index we start iterating from.
    /// @param _endIndex The last index we process.
    function claimAddressesInternal(
        uint256 _startIndex,
        uint256 _endIndex
    )
        internal
        isCompleted
    {
        for (uint256 i = 0; i < tokenAddress.length; ++i) {
            ERC20Basic token = ERC20Basic(tokenAddress[i]);
            uint256 tokenBalance = token.balanceOf(this);

            for (uint256 j = _startIndex; j <= _endIndex && tokenBalance > 0; ++j) {
                address user = swimmersList[j];

                if (swimmers[user] > 0) {
                    payoutTokensInternal(user, tokenBalance, token);
                }

                tokenBalance = token.balanceOf(this);
            }
        }
    }

    /// @dev Calculates the amount of tokens to be paid out for a given user.
    /// Emits a TokenClaimed event upon success.
    /// @param _user The user claiming tokens.
    /// @param _poolBalance The current balance the pool has for the given token.
    /// @param _token The token currently being calculated for.
    function payoutTokensInternal(
        address _user,
        uint256 _poolBalance,
        ERC20Basic _token
    )
        internal
    {
        // @dev The first time a user tries to claim tokens,
        //they will have the admin fee subtracted from their contribution.
        // This is the pro-rata portion added to swimmers[owner], in the payoutAdminFee() function.
        if (!adminFeePaid[_user] && adminFeePayoutIsToken && adminFeePercentage > 0) {
            collectAdminFee(_user);
        }

        // The total amount of tokens the contract has received.
        uint256 totalTokensReceived = _poolBalance.add(totalTokensDistributed[_token]);

        uint256 tokensOwedTotal = swimmers[_user].mul(totalTokensReceived).div(weiRaised);
        uint256 tokensPaid = swimmersTokensPaid[_user][_token];
        uint256 tokensToBePaid = tokensOwedTotal.sub(tokensPaid);

        if (tokensToBePaid > 0) {
            swimmersTokensPaid[_user][_token] = tokensOwedTotal;
            totalTokensDistributed[_token] = totalTokensDistributed[_token].add(tokensToBePaid);

            // Token transfer failed!
            require(_token.transfer(_user, tokensToBePaid));

            emit TokenClaimed(_user, tokensToBePaid, _token);
        }
    }

    /// @dev Processes a reimbursement claim for a given address.
    /// Emits a ReimbursementClaimed event for each successful iteration.
    /// @param _user The address being processed.
    function processReimbursementInternal(address _user) internal {
        // @dev The first time a user tries to claim tokens or a Reimbursement,
        // they will have the admin fee subtracted from their contribution.
        // This is the pro-rata portion added to swimmers[owner], in the payoutAdminFee() function.
        if (!adminFeePaid[_user] && adminFeePayoutIsToken && adminFeePercentage > 0) {
            collectAdminFee(_user);
        }

        // @dev Using integer division, there is the potential to truncate the result.
        // The effect is negligible because it is calculated in wei.
        // There will be dust, but the cost of gas for transferring it out, costs more than it is worth.
        uint256 amountContributed = swimmers[_user];
        uint256 totalReimbursement = reimbursementTotal.mul(amountContributed).div(weiRaised);
        uint256 alreadyReimbursed = swimmerReimbursements[_user];

        uint256 reimbursementAvailable = totalReimbursement.sub(alreadyReimbursed);

        if (reimbursementAvailable > 0) {
            swimmerReimbursements[_user] = swimmerReimbursements[_user].add(reimbursementAvailable);
            _user.transfer(reimbursementAvailable);

            emit ReimbursementClaimed(_user, reimbursementAvailable);
        }
    }

    /// @dev Subtracts the admin fee from the user's contribution.
    /// This should only happen once per user.
    /// Requires:
    ///     - This is the first time a user has tried to claim tokens or a reimbursement.
    /// @param _user The user who is paying the admin fee.
    function collectAdminFee(address _user) internal {
        uint256 individualFee = swimmers[_user].mul(adminFeePercentage).div(feePercentageDivisor);

        // @dev adding 1 to the fee is for rounding errors.
        // This will result in some left over dust, but it will cost more to transfer, than gained.
        individualFee = individualFee.add(1);
        swimmers[_user] = swimmers[_user].sub(individualFee);

        // Indicates the user has paid their fee.
        adminFeePaid[_user] = true;
    }

    /// @dev Processes a refund for a given address.
    /// Emits a Refund event for each successful iteration.
    /// @param _user The address for which the refund is processed.
    function processRefundInternal(address _user) internal {
        uint256 amount = swimmers[_user];

        swimmers[_user] = 0;
        weiRaised = weiRaised.sub(amount);
        _user.transfer(amount);

        emit Refund(_user, amount);
    }
}
