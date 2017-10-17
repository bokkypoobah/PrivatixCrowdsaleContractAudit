# Sale

Source file [../../contracts/Sale.sol](../../contracts/Sale.sol).

<br />

<hr />

```javascript
// BK Ok
pragma solidity ^0.4.15;

// BK Next 2 Ok
import './Token.sol';
import './MultiOwners.sol';


// BK Ok
contract Sale is MultiOwners {
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
    event Whitelist(address indexed beneficiary, uint256 value);

    // BK Ok
    modifier validPurchase(address contributor) {
        // BK Ok
        bool withinPeriod = ((now >= startTime || checkWhitelist(contributor, msg.value)) && now <= endTime);
        // BK Ok
        bool nonZeroPurchase = msg.value != 0;

        // BK Ok
        require(withinPeriod && nonZeroPurchase);

        // BK Ok
        _;        
    }

    // BK Ok - Not used in code but can be queried from blockchain explorers
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
        // BK Next block Ok
        whitelist[0xBd7dC4B22BfAD791Cd5d39327F676E0dC3c0C2D0] = 2000 ether;
        whitelist[0xebAd12E50aDBeb3C7b72f4a877bC43E7Ec03CD60] = 200 ether;
        whitelist[0xcFC9315cee88e5C650b5a97318c2B9F632af6547] = 200 ether;
        whitelist[0xC6318573a1Eb70B7B3d53F007d46fcEB3CFcEEaC] = 200 ether;
        whitelist[0x9d4096117d7FFCaD8311A1522029581D7BF6f008] = 150 ether;
        whitelist[0xfa99b733fc996174CE1ef91feA26b15D2adC3E31] = 100 ether;
        whitelist[0xdbb70fbedd2661ef3b6bdf0c105e62fd1c61da7c] = 100 ether;
        whitelist[0xa16fd60B82b81b4374ac2f2734FF0da78D1CEf3f] = 100 ether;
        whitelist[0x8c950B58dD54A54E90D9c8AD8bE87B10ad30B59B] = 100 ether;
        whitelist[0x5c32Bd73Afe16b3De78c8Ce90B64e569792E9411] = 100 ether;
        whitelist[0x4Daf690A5F8a466Cb49b424A776aD505d2CD7B7d] = 100 ether;
        whitelist[0x3da7486DF0F343A0E6AF8D26259187417ed08EC9] = 100 ether;
        whitelist[0x3ac05aa1f06e930640c485a86a831750a6c2275e] = 100 ether;
        whitelist[0x009e02b21aBEFc7ECC1F2B11700b49106D7D552b] = 100 ether;
        whitelist[0xCD540A0cC5260378fc818CA815EC8B22F966C0af] = 85 ether;
        whitelist[0x6e8b688CB562a028E5D9Cb55ac1eE43c22c96995] = 60 ether;
        whitelist[0xe6D62ec63852b246d3D348D4b3754e0E72F67df4] = 50 ether;
        whitelist[0xE127C0c9A2783cBa017a835c34D7AF6Ca602c7C2] = 50 ether;
        whitelist[0xD933d531D354Bb49e283930743E0a473FC8099Df] = 50 ether;
        whitelist[0x8c3C524A2be451A670183Ee4A2415f0d64a8f1ae] = 50 ether;
        whitelist[0x7e0fb316Ac92b67569Ed5bE500D9A6917732112f] = 50 ether;
        whitelist[0x738C090D87f6539350f81c0229376e4838e6c363] = 50 ether;
        // anothers KYC will be added using addWhitelists
    }

    // BK Ok - Constant function
    function hardCapReached() constant public returns (bool) {
        // BK Ok
        return ((hardCap * 999) / 1000) <= totalEthers;
    }

    // BK Ok - Constant function
    function softCapReached() constant public returns(bool) {
        // BK Ok
        return totalEthers >= softCap;
    }

    /*
     * @dev fallback for processing ether
     */
    // BK Ok - Fallback function marked as payable
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
    // BK Ok - Constant function
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
    // BK Ok - Internal function
    function checkWhitelist(address contributor, uint256 amount) internal returns (bool) {
        // BK Ok
        return etherBalances[contributor] + amount <= whitelist[contributor];
    }


    /*
     * @dev grant backer until first 24 hours
     * @param contributor address
     */
    // BK Ok - Only owner can execute
    function addWhitelist(address contributor, uint256 amount) onlyOwner public returns (bool) {
        // BK Ok - Log event
        Whitelist(contributor, amount);
        // BK Ok
        whitelist[contributor] = amount;
        // BK Ok
        return true;
    }


    /*
     * @dev grant backers until first 24 hours
     * @param contributor address
     */
    // BK Ok - Only owner can execute
    function addWhitelists(address[] contributors, uint256[] amounts) onlyOwner public returns (bool) {
        // BK Next 2 Ok
        address contributor;
        uint256 amount;

        // BK Ok
        require(contributors.length == amounts.length);

        // BK Ok
        for (uint i = 0; i < contributors.length; i++) {
            // BK Ok
            contributor = contributors[i];
            // BK Ok
            amount = amounts[i];
            // BK Ok
            require(addWhitelist(contributor, amount));
        }
        // BK Ok
        return true;
    }

    /*
     * @dev sell token and send to contributor address
     * @param contributor address
     */
    // BK Ok - Payable, should mark as public but this is the default anyway
    function buyTokens(address contributor) payable validPurchase(contributor) public {
        // BK Ok
        uint256 amount = calcAmountAt(msg.value, block.timestamp);
  
        // BK Ok
        require(contributor != 0x0) ;
        // BK Ok
        require(minimalEther <= msg.value);
        // BK Ok
        require(token.totalSupply() + amount <= maximumTokens);

        // BK Ok
        token.mint(contributor, amount);
        // BK Ok - Log event
        TokenPurchase(contributor, msg.value, amount);

        // BK Ok - If softCap already reached
        if(softCapReached()) {
            // BK Ok
            totalEthers = totalEthers + msg.value;
        // BK Ok - If softCap not already reached, but just reached
        } else if (this.balance >= softCap) {
            // BK Ok
            totalEthers = this.balance;
        // BK Ok - If softCap not reached, store contributions in case of refunds
        } else {
            // BK Ok
            etherBalances[contributor] = etherBalances[contributor] + msg.value;
        }

        // BK Ok
        require(totalEthers <= hardCap);
    }

    // @withdraw to wallet
    // BK Ok - Only owner can execute, after softCap reached
    function withdraw() onlyOwner public {
        // BK Ok
        require(softCapReached());
        // BK Ok
        require(this.balance > 0);

        // BK Ok
        wallet.transfer(this.balance);
    }

    // @withdraw token to wallet
    // BK Ok - Only owner can only execute after 1 year to withdraw tokens
    function withdrawTokenToFounder() onlyOwner public {
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

        // BK Ok
        uint256 current_balance = etherBalances[msg.sender];
        // BK Ok
        etherBalances[msg.sender] = 0;
 
        // BK Ok
        token.burn(msg.sender);
        // BK Ok
        msg.sender.transfer(current_balance);
    }

    // BK Ok - Only owner can execute, after crowdsale OR hardCap reached
    function finishCrowdsale() onlyOwner public {
        // BK Ok
        require(now > endTime || hardCapReached());
        // BK Ok
        require(!token.mintingFinished());

        // BK Next block Ok
        bountyReward = token.totalSupply() * 3 / 83; 
        teamReward = token.totalSupply() * 7 / 83; 
        founderReward = token.totalSupply() * 7 / 83; 

        // BK Ok
        if(softCapReached()) {
            // BK Ok
            token.mint(wallet, bountyReward);
            token.mint(wallet, teamReward);
            token.mint(this, founderReward);

            // BK Ok - Transfers enabled
            token.finishMinting(true);
        // BK Ok - softCap not reached, refund mode
        } else {
            // BK Ok
            refundAllowed = true;
            // BK Ok - Transfers disabled
            token.finishMinting(false);
        }
   }

    // @return true if crowdsale event has ended
    // BK Ok - Not used, but status can be viewed in blockchain explorers
    function running() public constant returns (bool) {
        // BK Ok
        return now >= startTime && !(now > endTime || hardCapReached());
    }
}
```
