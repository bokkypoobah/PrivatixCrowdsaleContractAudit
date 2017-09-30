# Token

Source file [../../contracts/Token.sol](../../contracts/Token.sol).

<br />

<hr />

```javascript
// BK Ok - Consider updating to a recent version
pragma solidity ^0.4.11;

// BK Ok - Carefully check for new commits between testing and mainnet deployment
import 'zeppelin-solidity/contracts/token/MintableToken.sol';


// BK Ok
contract Token is MintableToken {

    // BK Ok
    string public constant name = 'Privatix';
    // BK Ok
    string public constant symbol = 'PRIX';
    // BK NOTE - This should be `uint8`
    uint256 public constant decimals = 8;
    // BK Ok
    bool public transferAllowed;

    // BK NOTE - This event is already defined in ERC20Basic
    event Transfer(address indexed from, address indexed to, uint256 value);
    // BK Ok
    event Burn(address indexed from, uint256 value);
    // BK NOTE - Consider adding the parameter `bool _transferAllowed` to the TransferAllowed event
    // BK Ok
    event TransferAllowed();

    // BK Ok
    modifier canTransfer() {
        // BK Ok
        require(mintingFinished && transferAllowed);
        // BK Ok
        _;        
    }
    
    // BK Ok
    function transferFrom(address from, address to, uint256 value) canTransfer returns (bool) {
        // BK NOTE - Consider using `super.transferFrom(...)`
        // BK Ok
        return StandardToken.transferFrom(from, to, value);
    }

    // BK Ok
    function transfer(address to, uint256 value) canTransfer returns (bool) {
        // BK NOTE - Consider using `super.transfer(...)`
        // BK Ok
        return BasicToken.transfer(to, value);
    }

    // BK Ok
    function finishMinting(bool _transferAllowed) onlyOwner returns (bool) {
        // BK Ok
        transferAllowed = _transferAllowed;
        // BK NOTE - Consider removing the if condition and logging the _transferAllowed value
        if(transferAllowed) {
            // BK NOTE - Consider removing the if condition and logging the _transferAllowed value
            TransferAllowed();
        }
        // BK Ok
        return MintableToken.finishMinting();
    }

    // BK Ok - Only the owner can execute this function, and the owner is the Sale contract. To be called by `Sale.refund()`
    function burn(address from) onlyOwner returns (bool) {
        // BK Ok
        Transfer(from, 0x0, balances[from]);
        // BK Ok
        Burn(from, balances[from]);

        
        // BK Ok
        balances[0x0] += balances[from];
        // BK Ok
        balances[from] = 0;
    }

    // BK NOTE - Anyone can call this to mint tokens, but MintableToken.mint can only be called by the owner, in this case Sale
    // BK NOTE - Would be good to explicitly add onlyOwner
    // BK Ok
    function mint(address contributor, uint256 amount) returns (bool) {
        // BK Ok
        Transfer(0x0, contributor, amount);
        // BK Ok
        return MintableToken.mint(contributor, amount);
    }
}

```
