pragma solidity ^0.4.23;


import "./Whitelist.sol";
import 'zeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';


/// @title Pool contract functionality and configurations.
contract Pool is Whitelist {
    /// @dev Address points to a boolean indicating if the address has participated in the pool even if they have
    /// been refunded and balance is zero. This mapping internally helps us prevent duplicates from being pushed into swimmersList
    /// instead of iterating and popping from the list each time a users balance reaches 0.
    mapping(address => bool) public invested;

    /// @dev Address points to the current amount of wei the address has contributed to the pool.
    /// even after the wei has been transferred out, because the claim tokens function uses swimmers balances to calculate
    /// their claimable tokens.
    mapping(address => uint256) public swimmers;
    mapping(address => uint256) public swimmerReimbursements;
    mapping(address => mapping(address => uint256)) public swimmersTokensPaid;
    mapping(address => uint256) public totalTokensDistributed;

    address[] public swimmersList;
    address[] public tokenAddress;

    address public owner;
    address public poolPartyAddress;
    uint256 public adminWeiFee;
    uint256 public poolId;
    uint256 public weiRaised;

    event AdminFeePayout(uint256 value);
    event Deposit(address recipient, uint256 value);
    event EtherTransferredOut(uint256 value);
    event ProjectRefund(uint256 value);
    event Refund (address recipient, uint256 value);
    event TokenAdded(address tokenAddress);
    event TokenRemoved(address tokenAddress);
    event TokenClaimed (address recipient, uint256 value, address tokenAddress);

    /// @dev Verifies the msg.sender is the owner.
    modifier isOwner() {
        require(msg.sender == owner); // This is not the owner!
        _;
    }

    /// @dev Makes sure that the amount being transferred + the total amount previously sent
    /// is compliant with the configurations for the existing pool.
    modifier depositIsConfigCompliant() {
        require(msg.value > 0); // Value sent must be greater than 0!
        weiRaised = weiRaised.add(msg.value);
        uint256 amount = swimmers[msg.sender].add(msg.value);

        require(weiRaised <= maxAllocation); // Contribution will cause pool to be greater than max allocation!
        require(amount <= maxContribution); // Contribution is greater than max contribution!
        require(amount >= minContribution); // Contribution is less than minimum contribution!
        _;
    }

    /// @dev Verifies the user currently has funds in the pool.
    modifier userHasFundedPool(address _user) {
        require(swimmers[_user] > 0); // User does not have funds in the pool!
        _;
    }

    /// @notice Creates a new pool with the parameters as custom configurations.
    /// @dev Creates a new pool where:
    ///     - The creator of the pool will be the owner
    ///     - _admins become administrators for the pool contract and are automatically
    ///      added to whitelist, if it is enabled in the _configsBool
    ///     - Pool is initialised with the state set to OPEN
    /// @param _admins The list of admin addresses for the new pools. This list must include
    /// the creator of the pool.
    /// @param _configsUint256 Contains all of the uint256 configurations for the new pool.
    ///     - MAX_ALLOCATION
    ///     - MIN_CONTRIBUTION
    ///     - MAX_CONTRIBUTION
    ///     - ADMIN_FEE_PERCENTAGE_DECIMALS
    ///     - ADMIN_FEE_PERCENTAGE
    /// @param _configsBool Contains all of the boolean configurations for the new pool.
    ///     - HAS_WHITELIST
    ///     - ADMIN_FEE_PAYOUT
    /// @param _poolId The corresponding poolId.
    constructor(address[] _admins, uint256[] _configsUint256, bool[] _configsBool, uint256  _poolId) public {
        owner = tx.origin;
        state = PoolState.OPEN;
        poolPartyAddress = msg.sender;
        poolId = _poolId;

        createAdminsForPool(_admins);
        createConfigsForPool(_configsUint256, _configsBool);

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

    /// @notice Deposit Ether where the contribution is credited to the address specified in the parameter.
    /// @dev Allows a user to deposit on the behalf of someone else. Emits a Deposit event on success.
    /// Requires:
    ///     - The pool state is set to OPEN
    ///     - The amount is > 0
    ///     - The amount complies with the configurations of the pool
    ///     - If the whitelist configuration is enabled, verify the _user can deposit
    /// @param _user The address that will be credited with the deposit.
    function deposit(address _user) public payable isOpen canDeposit(_user) depositIsConfigCompliant {
        if (!invested[_user]){
            swimmersList.push(_user);
            invested[_user] = true;
        }

        swimmers[_user] = swimmers[_user].add(msg.value);

        emit Deposit(msg.sender, msg.value);
    }

    /// @notice Process a refund.
    /// @dev Allows refunds in the contract. Calls the internal refund function.
    /// Requires:
    ///     - The state of the pool is either OPEN or CANCELLED
    ///     - The user currently has funds in the pool
    function refund() public isUserRefundable userHasFundedPool(msg.sender) {
        address[] memory  users = new address[] (1);
        users[0] = msg.sender;
        refundInternal(users);
    }

    /// @notice claims available tokens.
    /// @dev Allows the user to claim their available tokens by calling the internal claimAddresses function.
    /// Requires:
    ///     - The msg.sender has funded the pool
    function claim() public userHasFundedPool(msg.sender) {
        address[] memory  users = new address[] (1);
        users[0] = msg.sender;
        claimAddresses(users);
    }

    /// @notice Process a claim function for a specified address.
    /// @dev Allows the user to claim tokens on behalf of someone else. Calls the claimAddresses function.
    /// Requires:
    ///     - The _address has funded the pool
    /// @param _address The address for which tokens should be redeemed.
    function claimAddress(address _address) public  userHasFundedPool(_address) {
        address[] memory  users = new address[] (1);
        users[0] = _address;
        claimAddresses(users);
    }

    /// @notice Distribute available tokens to everyone in the pool.
    /// @dev Allows anyone to call claim on all addresses stored in the pool which will distribute all available tokens accordingly.
    function claimAllAddresses() public {
        claimAddresses(swimmersList);
    }

    /// @notice Set a new token address where users can redeem ERC20 tokens.
    /// @dev Adds a new ERC20 address to the tokenAddress array and set the pool state to COMPLETED if it is not already
    /// Crucial that only valid ERC20 addresses be added with this function. In the event a bad one is entered, it can be removed with the removeToken() method.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is set to either AWAITING_TOKENS or COMPLETED
    ///     - The token address has not previously been added
    /// @param _tokenAddress The ERC20 address users can redeem from.
    function addToken(address _tokenAddress) public isAdmin isAwaitingOrCompleted {
        if (state != PoolState.COMPLETED){
            setPoolToCompleted();
        }

        for (uint256 i = 0; i < tokenAddress.length; ++i) {
            require(tokenAddress[i] != _tokenAddress); // The token address has already been added!
        }

        // @dev This verifies the address we are trying to add contains an ERC20 address. This does not completely protect
        // from having a bad address added, but it will reduce the likelihood. Any address that does not contain a balanceOf() method cannot be added.
        ERC20Basic token = ERC20Basic(_tokenAddress);
        require(token.balanceOf(this) >= 0); // The token being added is not an ERC20!

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
            if (tokenAddress[i] == _tokenAddress){
                tokenAddress[i] = tokenAddress[tokenAddress.length - 1];
                delete tokenAddress[tokenAddress.length - 1];
                tokenAddress.length--;
                break;
            }
        }

        if(tokenAddress.length == 0){
            setPoolToAwaitingTokens();
        }

        emit TokenRemoved(_tokenAddress);
    }

    /// @notice Removes a user from the whitelist and processes a refund.
    /// @dev Removes a user from the whitelist and removes their ability to contribute to the pool.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is currently set to OPEN or CLOSED or CANCELLED
    ///     - The pool has enabled whitelist functionality
    /// @param _address The address for which the refund is processed and removed from whitelist.
    function removeAddressFromWhitelistAndRefund(address _address) public isWhitelistEnabled canDeposit(_address) {
        whitelist[_address] = false;
        refundAddress(_address);
    }

    /// @notice Refund a given address for all the Ether they have contributed.
    /// @dev Processes a refund for a given address by calling the internal refund function.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is currently set to OPEN or CLOSED or CANCELLED
    /// @param _address The address for which the refund is processed.
    function refundAddress(address _address) public isAdmin isAdminRefundable userHasFundedPool(_address) {
        address[] memory  users = new address[] (1);
        users[0] = _address;
        refundInternal(users);
    }

    /// @notice This triggers a refund event for all users.
    /// @dev Uses the internal refund function on swimmersList.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is currently set to CANCELLED
    function refundAll() public isAdmin isCancelled {
        refundInternal(swimmersList);
    }

    /// @notice Provides a reimbursement, in the amount of the msg.value, for all participants of the pool at a pro-rata rate.
    /// @dev Iterates over the users and provides a refund relative to their contribution to the pool ie, pro-rata. This is the only way to
    /// refund users after the state of the pool has entered into the AWAITING_TOKENS or COMPLETED state.
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The state is either Awaiting or Completed
    function projectRefund() public payable isAdmin isAwaitingOrCompleted {
        uint256 refundTotal = msg.value;

        for (uint256 i = 0; i < swimmersList.length; ++i){
            address swimmersAddress = swimmersList[i];

            // @dev Using integer division, there is the potential to truncate the result. The effect is negligible because it is calculated in wei.
            // There will be dust, but the cost of gas for transferring it out costs more than its worth.
            uint256 amountContributed = swimmers[swimmersAddress];
            uint256 individualRefund = refundTotal.mul(amountContributed).div(weiRaised);

            if (individualRefund > 0){
                swimmersAddress.transfer(individualRefund);
                swimmerReimbursements[swimmersAddress] = swimmerReimbursements[swimmersAddress].add(individualRefund);
            }
        }

        emit ProjectRefund(msg.value);
    }

    /// @notice Sets the maximum allocation for the contract.
    /// @dev Set the uint256 configuration for maxAllocation to the _newMax parameter.
    /// If the new allocation is less than the amount of wei raised so far,
    /// then refund a proportional amount to each member so that the weiRaised is <= the new allocation
    /// by calling the internal function reduceContributionsProRata();
    /// Requires:
    ///     - The msg.sender is an admin
    ///     - The pool state is currently set to OPEN or CLOSED
    ///     - The _newMax must be >= max contribution
    /// @param _newMax The new maximum allocation for this pool contract.
    function setMaxAllocation(uint256 _newMax) public isAdmin isOpenOrClosed {
        if (_newMax >= weiRaised){
            maxAllocation = _newMax;
        } else {
            require(_newMax >= maxContribution); // Max Allocation cannot be below Max contribution!

            uint256 percentageOfOriginal = _newMax.mul(100).div(weiRaised);
            reduceContributionsProRata(percentageOfOriginal);
            maxAllocation = _newMax;
        }
    }

    /// @notice Transfers the Ether out of the contract to the given address parameter.
    /// @dev Transfers all Ether out. If admin fee is > 0, then call payOutAdminFee to distribute the admin fee.
    /// Sets the pool state to AWAITING_TOKENS.
    /// Requires:
    ///     - The pool state must be currently set to CLOSED
    ///     - msg.sender is the owner
    /// @param _contractAddress The address to send all Ether in the pool.
    function transferWei(address _contractAddress) public isOwner isClosed {
        uint256 weiForTransfer = weiRaised;

        if (adminFeePercentage > 0){
            weiForTransfer = payOutAdminFee();
        }

        require(weiForTransfer > 0); // No Ether to transfer!
        _contractAddress.transfer(weiForTransfer);

        setPoolToAwaitingTokens();

        emit EtherTransferredOut(weiForTransfer);
    }

    /// @dev The internal claim function for distributing available tokens. Goes through each of the token addresses
    /// set by the addToken function and calculates a pro-rata rate for each pool participant to be distributed.
    /// Emits a TokenClaimed event upon success.
    /// In the event that a bad token address is present, and the transfer function fails, this method cannot be processed until
    /// the bad address has been removed via the removeToken() method.
    /// Requires:
    ///     - The pool state must be set to COMPLETED
    ///     - The tokenAddress array must contain ERC20 compliant addresses.
    /// @param _addresses The addresses where available tokens will be distributed.
    function claimAddresses(address[] _addresses) internal isCompleted {
        for (uint256 i = 0; i < tokenAddress.length; ++i){
            ERC20Basic token = ERC20Basic(tokenAddress[i]);
            uint256 poolTokenBalance = token.balanceOf(this);

            for (uint256 j = 0; j < _addresses.length && poolTokenBalance > 0; ++j){
                address user = _addresses[j];
                uint256 totalTokensReceived = poolTokenBalance.add(totalTokensDistributed[token]);

                uint256 tokensOwedTotal = swimmers[user].mul(totalTokensReceived).div(weiRaised);
                uint256 tokensPaid = swimmersTokensPaid[user][token];
                uint256 tokensToBePaid = tokensOwedTotal.sub(tokensPaid);

                if (tokensToBePaid > 0){
                    swimmersTokensPaid[user][token] = tokensOwedTotal;
                    totalTokensDistributed[token] = totalTokensDistributed[token].add(tokensToBePaid);
                    require(token.transfer(user, tokensToBePaid)); // Token transfer failed!

                    emit TokenClaimed(user, tokensToBePaid, token);
                }

                poolTokenBalance = token.balanceOf(this);
            }
        }
    }

    /// @dev Payout the owner of this contract, depending on state of the adminFeePayoutIsToken boolean.
    /// true - The payout is in tokens. Each member of swimmersList is deducted the adminFeePercentage, which is then
    /// added into the owners contribution.
    /// false - The adminFeePercentage is deducted from the total amount of Ether that is transferred out of the contract.
    /// @return The amount of wei that will be transferred out of this function.
    function payOutAdminFee() internal returns (uint256 _weiForTransfer) {
        if (adminFeePayoutIsToken) {
            for (uint256 i = 0; i < swimmersList.length; ++i){
                address swimmersAddress = swimmersList[i];

                // @dev Using integer division, there is the potential to truncate the result. The effect is negligible because it is calculated in wei.
                uint256 individualFee = swimmers[swimmersAddress].mul(adminFeePercentage).div(feePercentageDivisor);

                swimmers[swimmersAddress] = swimmers[swimmersAddress].sub(individualFee);
                adminWeiFee = adminWeiFee.add(individualFee);
            }

            swimmers[owner] = swimmers[owner].add(adminWeiFee);
            _weiForTransfer = weiRaised;
        } else {
            adminWeiFee = weiRaised.mul(adminFeePercentage).div(feePercentageDivisor);

            _weiForTransfer = weiRaised.sub(adminWeiFee);

            if (adminWeiFee > 0){
                owner.transfer(adminWeiFee);

                emit AdminFeePayout(adminWeiFee);
            }
        }
    }

    /// @dev Applies an integer percentage value to every swimmers contribution, the difference is sent back to the user.
    function reduceContributionsProRata(uint256 _percentage) internal {
        for (uint256 i = 0; i < swimmersList.length; ++i){
            address swimmersAddress = swimmersList[i];

            // @dev Using integer division, there is the potential to truncate the result. The effect is negligible because it is calculated in wei.
            uint256 startingBalance = swimmers[swimmersAddress];
            uint256 adjustedBalance = startingBalance.mul(_percentage).div(100);

            if (adjustedBalance < startingBalance){
                uint256 amountToRefund = startingBalance.sub(adjustedBalance);
                weiRaised = weiRaised.sub(amountToRefund);

                swimmers[swimmersAddress] = adjustedBalance;
                swimmersAddress.transfer(amountToRefund);
            }
        }
    }

    /// @dev Processes a refund for a list of addresses internally. Emits a Refund event for each successful iteration.
    /// Requires:
    ///     - The address currently has funds in the pool
    /// @param _addresses The addresses for which the refund is processed.
    function refundInternal(address[] _addresses) internal {
        for (uint256 i = 0; i < _addresses.length; ++i){
            address user = _addresses[i];

            if (swimmers[user] > 0){
                uint256 amount = swimmers[user];

                swimmers[user] = 0;
                weiRaised = weiRaised.sub(amount);
                user.transfer(amount);

                emit Refund(user, amount);
            }
        }
    }
}
