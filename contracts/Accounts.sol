pragma solidity ^0.4.19;
import "./helpers/SafeMath.sol";

contract Accounts{
  using SafeMath for uint256;

  //--------------------------------------------------------------
  // VARIABLES
  /**
  * Holds the user's ETH balance that they have deposited. User's
  * can with withdraw or deposit the their account at anytime. To
  * participate in an pool, the user must call TODO method to transfer
  * from their account in the PoolParty contract to a existing pool.
  */
  mapping (address => uint256) public accounts_;

  /**
  * Keeps a running total of all Eth being held in accounts_
  */
  uint256 public accountsBalance_ = 0;

  //--------------------------------------------------------------
  // EVENTS
  event Deposit (
    address recipient,
    uint256 value
  );

  event Withdraw (
    address recipient,
    uint256 value
  );



  //--------------------------------------------------------------
  // METHODS
  /**
  * @notice Deposits money into the the user's account. The
  * user then has to decide how they want to spend the money.
  *
  * @dev Requires the user sends a positive amount of ETH.
  * Sends out a Deposit event on success.
  */
   function () public payable {
       require(msg.value > 0);
       accounts_[msg.sender] = accounts_[msg.sender].add(msg.value);
       //
       // Updates the running total balance
       accountsBalance_ = accountsBalance_.add(msg.value);

       //
       // Sends out the deposit event
       Deposit(msg.sender, msg.value);
   }

   /**
   * @notice Withdraws all ether from the user's account.
   *
   * @dev Requires the user sends a positive amount of ETH.
   * Requires the accountsBalance_ is greater than or equal to
   * the amount. Sends out a Deposit event on success.
   */
   function withdrawAll() public {
       require(accounts_[msg.sender] > 0);

        //
        // Remove all ETH from the user's account and sends
        // to the user's address.
        uint256 amount = accounts_[msg.sender];
        accounts_[msg.sender] = 0;
        msg.sender.transfer(amount);

        //
        // Updates the running total balance
        accountsBalance_ = accountsBalance_.sub(amount);

        //
        // Sends out the withdraw event
        Withdraw(msg.sender, amount);
    }
}
