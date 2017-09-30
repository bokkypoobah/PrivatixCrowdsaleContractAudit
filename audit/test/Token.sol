pragma solidity ^0.4.11;

import './MintableToken.sol';


contract Token is MintableToken {

    string public constant name = 'Privatix';
    string public constant symbol = 'PRIX';
    uint256 public constant decimals = 8;
    bool public transferAllowed;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);
    event TransferAllowed();

    modifier canTransfer() {
        require(mintingFinished && transferAllowed);
        _;        
    }
    
    function transferFrom(address from, address to, uint256 value) canTransfer returns (bool) {
        return StandardToken.transferFrom(from, to, value);
    }

    function transfer(address to, uint256 value) canTransfer returns (bool) {
        return BasicToken.transfer(to, value);
    }

    function finishMinting(bool _transferAllowed) onlyOwner returns (bool) {
        transferAllowed = _transferAllowed;
        if(transferAllowed) {
            TransferAllowed();
        }
        return MintableToken.finishMinting();
    }

    function burn(address from) onlyOwner returns (bool) {
        Transfer(from, 0x0, balances[from]);
        Burn(from, balances[from]);

        balances[0x0] += balances[from];
        balances[from] = 0;
    }

    function mint(address contributor, uint256 amount) returns (bool) {
        Transfer(0x0, contributor, amount);
        return MintableToken.mint(contributor, amount);
    }
}
