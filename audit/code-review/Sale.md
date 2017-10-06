# Sale

Source file [../../contracts/Sale.sol](../../contracts/Sale.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.15;

// BK Ok - Carefully check for new commits between testing and mainnet deployment
import 'zeppelin-solidity/contracts/math/SafeMath.sol';
// BK Next 2 Ok
import './Token.sol';
import './MultiOwners.sol';


// BK Ok
contract Sale is MultiOwners {
    // BK Ok
    using SafeMath for uint256;

    // Minimal possible cap in ethers
    // BK Ok
    uint256 public softCap;

    // Maximum possible cap in ethers
    // BK Ok
    uint256 public hardCap;

    // totalEthers received
    // BK Ok
    uint256 public totalEthers;

    // Ssale token
    // BK Ok
    Token public token;

    // Withdraw wallet
    // BK Ok
    address public wallet;

    // Maximum available to sell tokens
    // BK Ok
    uint256 public maximumTokens;

    // Minimal ether
    // BK Ok
    uint256 public minimalEther;

    // Token per ether
    // BK Ok
    uint256 public weiPerToken;

    // start and end timestamp where investments are allowed (both inclusive)
    // BK Next 2 Ok
    uint256 public startTime;
    uint256 public endTime;

    // refund if softCap is not reached
    // BK Ok
    bool public refundAllowed;

    // 
    // BK Ok
    mapping(address => uint256) public etherBalances;

    // 
    // BK Ok
    mapping(address => uint256) public whitelist;

    // bounty tokens
    // BK Ok
    uint256 public bountyReward;

    // team tokens
    // BK Ok
    uint256 public teamReward;

    // founder tokens
    // BK Ok
    uint256 public founderReward;

    // BK Ok
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 amount);

    // BK Ok
    modifier validPurchase() {
        // BK Ok
        bool withinPeriod = (now >= startTime && now <= endTime);
        // BK Ok
        bool nonZeroPurchase = msg.value != 0;

        // BK Ok
        require(withinPeriod && nonZeroPurchase);

        // BK Ok
        _;        
    }

    // BK Ok - Not used
    modifier isStarted() {
        // BK Ok
        require(now >= startTime);

        // BK Ok
        _;        
    }

    // BK Ok
    modifier isExpired() {
        // BK Ok
        require(now > endTime);

        // BK Ok
        _;        
    }

    // BK Ok - Constructor
    function Sale(uint256 _startTime, address _wallet) {
        // BK Ok
        require(_startTime >=  now);
        // BK Ok
        require(_wallet != 0x0);

        // BK Ok
        token = new Token();

        // BK Ok
        wallet = _wallet;
        // BK Ok
        startTime = _startTime;

        // BK Next 5 Ok
        minimalEther = 1e16; // 0.01 ether
        endTime = _startTime + 28 days;
        weiPerToken = 1e18 / 100e8; // token price
        hardCap = 57142e18;
        softCap = 3350e18;

    
        // We love our Pre-ITO backers
        // BK Next block Ok
        token.mint(0x992066a964C241eD4996E750284d039B14A19fA5, 11199999999860);
        token.mint(0x1F4df63B8d32e54d94141EF8475c55dF4db2a02D, 9333333333170);
        token.mint(0xce192Be11DdE37630Ef842E3aF5fBD7bEA15C6f9, 2799999999930);
        token.mint(0x18D2AD9DFC0BA35E124E105E268ebC224323694a, 1120000000000);
        token.mint(0x4eD1db98a562594CbD42161354746eAafD1F9C44, 933333333310);
        token.mint(0x00FEbfc7be373f8088182850FeCA034DDA8b7a67, 896000000000);
        token.mint(0x86850f5f7D035dD96B07A75c484D520cff13eb58, 634666666620);
        token.mint(0x08750DA30e952B6ef3D034172904ca7Ec1ab133A, 616000000000);
        token.mint(0x4B61eDe41e7C8034d6bdF1741cA94910993798aa, 578666666620);
        token.mint(0xdcb018EAD6a94843ef2391b3358294020791450b, 560000000000);
        token.mint(0xb62E27446079c2F2575C79274cd905Bf1E1e4eDb, 560000000000);
        token.mint(0xFF37732a268a2ED27627c14c45f100b87E17fFDa, 560000000000);
        token.mint(0x7bDeD0D5B6e2F9a44f59752Af633e4D1ed200392, 80000000000);
        token.mint(0x995516bb1458fa7b192Bb4Bab0635Fc9Ab447FD1, 48000000000);
        token.mint(0x95a7BEf91A5512d954c721ccbd6fC5402667FaDe, 32000000000);
        token.mint(0x3E10553fff3a5Ac28B9A7e7f4afaFB4C1D6Efc0b, 24000000000);
        token.mint(0x7C8E7d9BE868673a1bfE0686742aCcb6EaFFEF6F, 17600000000);

        // BK Ok
        maximumTokens = token.totalSupply() + 8000000e8;

        // Also we like KYC
        // BK Ok
        whitelist[0x38C0fC6F24013ED3F7887C05f95d17A8883be4bA] = 100e18;
    }

    // BK Ok
    function hardCapReached() constant public returns (bool) {
        // BK Ok
        return ((hardCap * 999) / 1000) <= totalEthers;
    }

    // BK Ok
    function softCapReached() constant public returns(bool) {
        // BK Ok
        return totalEthers >= softCap;
    }

    /*
     * @dev fallback for processing ether
     */
    // BK Ok
    function() payable {
        // BK Ok
        return buyTokens(msg.sender);
    }

    /*
     * @dev calculate amount
     * @param  _value - ether to be converted to tokens
     * @param  at - current time
     * @return token amount that we should send to our dear investor
     */
    // BK Ok
    function calcAmountAt(uint256 _value, uint256 at) public constant returns (uint256) {
        // BK Ok
        uint rate;

        // BK Next block Ok
        if(startTime + 2 days >= at) {
            rate = 140;
        } else if(startTime + 7 days >= at) {
            rate = 130;
        } else if(startTime + 14 days >= at) {
            rate = 120;
        } else if(startTime + 21 days >= at) {
            rate = 110;
        } else {
            rate = 105;
        }
        // BK Ok
        return ((_value * rate) / weiPerToken) / 100;
    }

    /*
     * @dev check contributor is whitelisted or not for buy token 
     * @param contributor
     * @param amount — how much ethers contributor wants to spend
     * @return true if access allowed
     */
    // BK Ok
    function checkWhitelist(address contributor, uint256 amount) internal returns (bool) {
        // BK Ok
        if(startTime + 1 days < now) {
            // BK Ok
            return true;
        }
        // BK Ok
        return etherBalances[contributor] + amount <= whitelist[contributor];
    }


    /*
     * @dev grant backer until first 24 hours
     * @param contributor address
     */
    // BK Ok
    function addWhitelist(address contributor, uint256 amount) onlyOwner returns (bool) {
        // BK Ok
        whitelist[contributor] = amount;
        // BK Ok
        return true;
    }


    /*
     * @dev sell token and send to contributor address
     * @param contributor address
     */
    // BK Ok
    function buyTokens(address contributor) payable validPurchase {
        // BK Ok
        uint256 amount = calcAmountAt(msg.value, block.timestamp);
  
        // BK Ok
        require(contributor != 0x0) ;
        // BK Ok
        require(checkWhitelist(contributor, msg.value));
        // BK Ok
        require(minimalEther <= msg.value);
        // BK Ok
        require(token.totalSupply() + amount <= maximumTokens);

        // BK Ok
        token.mint(contributor, amount);
        // BK Ok - Log event
        TokenPurchase(contributor, msg.value, amount);

        // BK Ok
        if(softCapReached()) {
            // BK Ok
            totalEthers = totalEthers + msg.value;
        // BK Ok
        } else if (this.balance >= softCap) {
            // BK Ok
            totalEthers = this.balance;
        // BK Ok
        } else {
            // BK Ok
            etherBalances[contributor] = etherBalances[contributor] + msg.value;
        }

        // BK Ok
        require(totalEthers <= hardCap);
    }

    // @withdraw to wallet
    // BK Ok
    function withdraw() public {
        // BK Ok
        require(softCapReached());
        // BK Ok
        require(this.balance > 0);

        // BK Ok
        wallet.transfer(this.balance);
    }

    // @withdraw token to wallet
    // BK NOTE - Only can only withdraw tokens after 1 year
    // BK Ok
    function withdrawTokenToFounder() public {
        // BK Ok
        require(token.balanceOf(this) > 0);
        // BK Ok
        require(softCapReached());
        // BK Ok
        require(startTime + 1 years < now);

        // BK Ok
        token.transfer(wallet, token.balanceOf(this));
    }

    // @refund to backers, if softCap is not reached
    // BK NOTE - Should restrict 
    function refund() isExpired public {
        // BK Ok
        require(refundAllowed);
        // BK Ok
        require(!softCapReached());
        // BK Ok
        require(etherBalances[msg.sender] > 0);
        // BK Ok
        require(token.balanceOf(msg.sender) > 0);
 
        // BK NOTE - Safer to have this statement after the zeroing of the account's balance
        msg.sender.transfer(etherBalances[msg.sender]);
        // BK Ok
        token.burn(msg.sender);
        // BK Ok
        etherBalances[msg.sender] = 0;
    }

    function finishCrowdsale() public {
        require(now > endTime || hardCapReached());
        require(!token.mintingFinished());

        bountyReward = token.totalSupply() * 3 / 83; 
        teamReward = token.totalSupply() * 7 / 83; 
        founderReward = token.totalSupply() * 7 / 83; 

        if(softCapReached()) {
            token.mint(wallet, bountyReward);
            token.mint(wallet, teamReward);
            token.mint(this, founderReward);

            token.finishMinting(true);
        } else {
            refundAllowed = true;
            token.finishMinting(false);
        }
   }

    // @return true if crowdsale event has ended
    // BK Ok - Not used
    function running() public constant returns (bool) {
        // BK Ok
        return now >= startTime && !(now > endTime || hardCapReached());
    }
}
```
