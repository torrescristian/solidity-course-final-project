pragma solidity ^0.8.0;

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

