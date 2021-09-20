pragma solidity ^0.8.0;
/*
# Course Final Project:

It is time to test your skills and the knowledge you have gained going through this course from start to finish!

Your mission is to write a decentralized auction DApplication which can at the minimum have the following functionality.
As long as you meet the minimum required functionality then you have passed this course with flying colors, however should you choose to exceed
the minimum and continue to expand upon the Auction then you are truly becoming a defi super star and I would love to see what you 
come up with so please share it in the discord! 

If you fall short - do not worry, take your time, ask questions in our Discord, do some research, and go as far as you can. And when you 
are ready go to the solution video and we can go through it all together as always. 

Final Exercise: Create an Auction DApplication (The Decentralized Ebay)

1. You must create a contract called auction which contains state variables to keep track of the beneficiary (auctioneer), 
the highest bidder, the auction end time, and the highest bid. 
[X]

2. There must be events set up which can emit whenever the highest bid changes both address and amount and an 
event for the auction ending emitting the winner address and amount. 
[X]

3. The contract must be deployed set to the beneficiary address and how long the auction will run for. 
[X]

4. There should be a bid function which includes at the minimum the following:
    a. revert the call if the bidding period is over.
    b. If the bid is not higher than the highest bid, send the money back.
    c. emit the highest bid has increased 
[X]

5. Bearing in mind the withdrawal pattern, there should be a withdrawal function 
to return bids based on a library of keys and values. 
[x]

6. There should be a function which ends the auction and sends the highest bid to 
the beneficiary!
[X]

Alirght - so this is your mission - good luck and may the defi be with you! 
*/

contract Auction {
    // state variables
    struct Highest {
        uint amount;
        address bidder;
    }
    
    Highest public highest;
    mapping (address => uint) balance;
    address public beneficiary;
    uint public auctionEndTime;
    bool auctionEnded = false;
    bool locked = false;

    event HighestBidUpdated(address newHighestBidderAddress, uint newHighestAmount);
    event AuctionEnded(address highestBidderAddress, uint highestAmount);

    constructor(uint auctionDurationDays, uint initialOffer) {
        beneficiary = msg.sender;
        auctionEndTime = block.timestamp + (auctionDurationDays * 1 days);
        
        highest = Highest({
           amount: initialOffer,
           bidder: beneficiary
        });
    }

    // modifiers
    modifier onlyNewHighest {
        require(getTotalBidderAmount() > highest.amount, 'You have to bid more that the previous highest');
        _;
    }
    
    modifier onlyBeneficiary {
        require(msg.sender == beneficiary, 'Not allowed to perform this operation');
        _;
    }
    
    modifier noReentrant {
        require(!locked, 'This contract was being used, please try again');
        locked = true;
        _;
        locked = false;
    }
    
    modifier onlyBalancePending {
        require(balance[msg.sender] > 0, 'You do not have is any pending balance to withdraw');
        _;
    }

    modifier exceptBeneficiary {
        require(msg.sender != beneficiary, 'The beneficiary can not participate in the bid');
        _;
    }
    
    modifier auctionWasNotManuallyEnded {
        require(!auctionEnded, 'Auction was already finished');
        _;
    }

    // functions
    function getTotalBidderAmount() private view returns(uint) {
        return msg.value + balance[msg.sender];
        // by default balance[msg.sender] = 0, this is to allow multiple bid from the same address
    }
    
    function endAuction() external onlyBeneficiary noReentrant auctionWasNotManuallyEnded {
        if (highest.bidder == beneficiary) {
            highest.amount = 0;
        } else {
            balance[beneficiary] = highest.amount;
        }
        
        auctionEnded = true;

        emit AuctionEnded({
            highestBidderAddress: highest.bidder,
            highestAmount: highest.amount
        });
    }

    function bid() external payable onlyNewHighest noReentrant exceptBeneficiary {
        if (auctionEnded || auctionEndTime <= block.timestamp) {
            revert('Auction expired');
        }
        
        // WARNING: this function should always be called before "balance[msg.sender] = 0;"
        uint totalAmount = getTotalBidderAmount();

        balance[highest.bidder] = highest.amount;
        balance[msg.sender] = 0; // in case of nth bid

        emit HighestBidUpdated({
            newHighestBidderAddress: highest.bidder = msg.sender,
            newHighestAmount: highest.amount = totalAmount
        });
    }

    function withdraw() external onlyBalancePending noReentrant {
        address payable owner = payable(msg.sender);
        
        uint amount = balance[owner];
        balance[owner] = 0;
        
        owner.transfer(amount);
    }
    
    function getBalance() external view returns (uint) {
        return highest.bidder == beneficiary ? 0 : balance[msg.sender];
    }
    
    function getContractAccountBalance() external view returns (uint) {
        return address(this).balance;
    }
}

/***
  * Personal notes
  * 
  * # Improvements
  * 
  * [X] Add more getters
  * [X] Set the initial data to amount 0 and the address the beneficiary
  * [X] Add a validation that forbids the withdrawal to the current highest (don't set the balance until there is a new highest)
  * [X] endAuction only should be call by the beneficiary
  * [X] Add no re-entrancy modifier
  * [X] Add test cases
  * [X] The beneficiary shouldn't be able to make a bid
  * [X] Allow multiple bid from the same address
  * [X] Add initial offer on contract creation
  * 
  * # Test Cases
  * 
  * ## Setting
  * From an account A deploy the contract setting the auction duration days (e.g. 1 day), the initial offer (e.g. 50 wei) and check:
  *     1. The "beneficiary" should be the address of the account A
  *     2. The "highest" should contain an amount = 0 and the address of the account A
  *     3. The auctionEndTime should be the current date + auction duration days
  *         3.1 we can validate this by parsing the date to a readable form on https://www.epochconverter.com/
  * 
  * ## Do the first bid
  * From an account B call the "bid" function with a "n" value, lets say 100 wei
  *     1. The "highest" should contain an amount = 100 wei and the address of the account B
  *     2. Now you should have an error if you try to bid with less or equal value as the highest bid from any account 
  *     3. The beneficiary (account A) should not be able to make a bid
  * 
  * ## Do the second and nth bid
  * From an account C call the "bid" function with a "n" + 1 value, in our example 101 wei
  *     1. The "highest" should contain an amount = 101 wei and the address of the account C
  *     2. The account B now will have a pending funds and will be enabled to call the "withdraw" function
  *         2.1. This is safer than just send the refund to account B (withdraw pattern)
  *         2.2. You can check the new balance of the account B calling "getBalance" from that account
  *     3. An account should be able to bid multiple times and the partial amounts should be considerated as a single one
  *         3.1. The account should be able to be set as a new highest if the current send value + the previous ones are larger than the current highest
  *         3.2. The pending blanace (if there was one) should be removed (be 0 again)
  * 
  * ## Withdraw pending funds
  * From the account B, an account that made a bid but its no longer the highest bid, call the "withdraw" function, after that:
  *     1. You should see the value of the account B bid back to the account
  *     2. If you click on "getBalance" from that account the function should return "0"
  * 
  * ## Complete the auction
  *  From the account A, the one that deployed the contract, call the "endAuction"
  *     1. Now account A should be able to see the highest bid as a pending balance and withdraw it
  *     2. It should not be any way to change the highest bid or bidder anymore, in our example account C will be the winner by being the last one
  *     3. All the other pending balance should continue be able to be withdrawn
  *     4. All of these conditions apply also when the bid was finished by auction timeout, in our example after 1 day of the deployment of the contract
  * 
  */

