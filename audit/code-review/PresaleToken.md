# PresaleToken

Source file [../../contracts/PresaleToken.sol](../../contracts/PresaleToken.sol).

<br />

<hr />

```javascript
pragma solidity ^0.4.11;

import 'zeppelin-solidity/contracts/token/MintableToken.sol';


contract PresaleToken is MintableToken {

    string public constant name = 'Privatix Presale';
    string public constant symbol = 'PRIXY';
    uint256 public constant decimals = 8;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function transferFrom(address from, address to, uint256 value) returns (bool) {
        revert();
    }

    function transfer(address _to, uint256 _value) returns (bool) {
        revert();
    }

    function mint(address contributor, uint256 amount) returns (bool) {
        Transfer(0x0, contributor, amount);
        return MintableToken.mint(contributor, amount);
    }
}

```
