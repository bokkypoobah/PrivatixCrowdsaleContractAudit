# Privatix Crowdsale Contract Audit

[https://privatix.io/](https://privatix.io/).

<br />

<hr />

## Summary

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Code Review](#code-review)

<br />

<hr />

## Code Review

* [ ] [code-review/MultiOwners.md](code-review/MultiOwners.md)
  * [ ] contract MultiOwners 
* [ ] [code-review/Sale.md](code-review/Sale.md)
  * [ ] contract Sale is MultiOwners 
* [ ] [code-review/Token.md](code-review/Token.md)
  * [ ] contract Token is MintableToken 


<br />

### OpenZeppelin Code Review

From [OpenZeppelin Solidity contracts](https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts).

Commit [5cf5036](https://github.com/OpenZeppelin/zeppelin-solidity/commit/5cf503673faea92c1b5c615c3f8358febf06e160).

* [ ] [openzeppelin-code-review/math/SafeMath.md](openzeppelin-code-review/math/SafeMath.md)
  * [ ] library SafeMath
* [ ] [openzeppelin-code-review/ownership/Ownable.md](openzeppelin-code-review/ownership/Ownable.md)
  * [ ] contract Ownable
* [ ] [openzeppelin-code-review/token/ERC20Basic.md](openzeppelin-code-review/token/ERC20Basic.md)
  * [ ] contract ERC20Basic 
* [ ] [openzeppelin-code-review/token/ERC20.md](openzeppelin-code-review/token/ERC20.md)
  * [ ] contract ERC20 is ERC20Basic 
* [ ] [openzeppelin-code-review/token/BasicToken.md](openzeppelin-code-review/token/BasicToken.md)
  * [ ] contract BasicToken is ERC20Basic 
* [ ] [openzeppelin-code-review/token/StandardToken.md](openzeppelin-code-review/token/StandardToken.md)
  * [ ] contract StandardToken is ERC20, BasicToken 
* [ ] [openzeppelin-code-review/token/MintableToken.md](openzeppelin-code-review/token/MintableToken.md)
  * [ ] contract MintableToken is StandardToken, Ownable 

<br />

### Code Not Reviewed

The following contracts are for the Presale funding that is now completed:

* [ ] [../contracts/Presale.sol](../contracts/Presale.sol)
  * [ ] contract Presale 
* [ ] [../contracts/PresaleToken.sol](../contracts/PresaleToken.sol)
  * [ ] contract PresaleToken is MintableToken 

The following contracts are for testing and the testing framework:

* [ ] [../contracts/Migrations.sol](../contracts/Migrations.sol)
  * [ ] contract Migrations 

