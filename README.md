# The Complete Solidity Course - Blockchain - Zero to Expert

## Certificate
[https://www.udemy.com/certificate/UC-e2ee187e-e8fe-4976-bd87-f878b15719ad/
](https://www.udemy.com/certificate/UC-e2ee187e-e8fe-4976-bd87-f878b15719ad/)

## Project Description

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

2. There must be events set up which can emit whenever the highest bid changes both address and amount and an 
event for the auction ending emitting the winner address and amount. 

3. The contract must be deployed set to the beneficiary address and how long the auction will run for. 

4. There should be a bid function which includes at the minimum the following: 

a. revert the call if the bidding period is over.
b. If the bid is not higher than the highest bid, send the money back.
c. emit the highest bid has increased 

4. Bearing in mind the withdrawal pattern, there should be a withdrawal function 
to return bids based on a library of keys and values. 

5. There should be a function which ends the auction and sends the highest bid to 
the beneficiary!

Alirght - so this is your mission - good luck and may the defi be with you!


# Personal notes
 
## Improvements

- [x] Add more getters
- [x] Set the initial data to amount 0 and the address the beneficiary
- [x] Add a validation that forbids the withdrawal to the current highest (don't set the balance until there is a new highest)
- [x] endAuction only should be call by the beneficiary
- [x] Add no re-entrancy modifier
- [x] Add test cases
- [x] The beneficiary shouldn't be able to make a bid
- [x] Allow multiple bid from the same address
- [x] Add initial offer on contract creation

## Test Cases

### Setting
From an account A deploy the contract setting the auction duration days (e.g. 1 day), the initial offer (e.g. 50 wei) and check:

1. The "beneficiary" should be the address of the account A
2. The "highest" should contain an amount = 0 and the address of the account A
3. The auctionEndTime should be the current date + auction duration days
    1. we can validate this by parsing the date to a readable form on https://www.epochconverter.com/

### Do the first bid
From an account B call the "bid" function with a "n" value, lets say 100 wei

1. The "highest" should contain an amount = 100 wei and the address of the account B
2. Now you should have an error if you try to bid with less or equal value as the highest bid from any account 
3. The beneficiary (account A) should not be able to make a bid

### Do the second and nth bid
From an account C call the "bid" function with a "n" + 1 value, in our example 101 wei

1. The "highest" should contain an amount = 101 wei and the address of the account C
2. The account B now will have a pending funds and will be enabled to call the "withdraw" function
    1. This is safer than just send the refund to account B (withdraw pattern)
    2. You can check the new balance of the account B calling "getBalance" from that account
3. An account should be able to bid multiple times and the partial amounts should be considerated as a single one
    1. The account should be able to be set as a new highest if the current send value + the previous ones are larger than the current highest
    2. The pending blanace (if there was one) should be removed (be 0 again)

### Withdraw pending funds
From the account B, an account that made a bid but its no longer the highest bid, call the "withdraw" function, after that:
    
1. You should see the value of the account B bid back to the account
2. If you click on "getBalance" from that account the function should return "0"

### Complete the auction
From the account A, the one that deployed the contract, call the "endAuction"

1. Now account A should be able to see the highest bid as a pending balance and withdraw it
2. It should not be any way to change the highest bid or bidder anymore, in our example account C will be the winner by being the last one
3. All the other pending balance should continue be able to be withdrawn
4. All of these conditions apply also when the bid was finished by auction timeout, in our example after 1 day of the deployment of the contract
