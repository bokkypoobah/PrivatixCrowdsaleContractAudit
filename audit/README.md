# Privatix Crowdsale Contract Audit

<br />

## Summary

[Privatix](https://privatix.io/) intends to run a [crowdsale](https://privatix.io/#tokenSale) commencing on October 19 2017.

Bok Consulting Pty Ltd was commissioned to perform an audit on the Ethereum smart contracts for Privatix's crowdsale and token contract.

This audit has been conducted on Privatix's source code in commits
[c2f6d3d](https://github.com/Privatix/smart-contract/commit/c2f6d3d88f66eeb3f1c88cb76550e9a93ae387fc),
[58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6),
[609c861](https://github.com/Privatix/smart-contract/commit/609c86107087823ffd678bcc1fcebba917f79a51),
[ce37920](https://github.com/Privatix/smart-contract/commit/ce37920852e289ba26543bc9316075c9a66cdad7),
[5fda921](https://github.com/Privatix/smart-contract/commit/5fda9217e40aad85a9d12d05c19aa3955fd10fb9),
[fde2422](https://github.com/Privatix/smart-contract/commit/fde2422394212f7e6fbea7318432860273149511),
[e8fbb6d](https://github.com/Privatix/smart-contract/commit/e8fbb6dd9372a844d2a8e716104aa141d3552b92),
[f7a1ce3](https://github.com/Privatix/smart-contract/commit/f7a1ce31e2640daabc0f4198493a6c914e28f842),
[15001fe](https://github.com/Privatix/smart-contract/commit/15001fe2b2cf7094003db9b57db6d038602900a7) and
[290e66b](https://github.com/Privatix/smart-contract/commit/290e66bddc64de8ac7f392a15a1da3ab9cd5be6a).

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

### Crowdsale Mainnet Addresses

`TBA`

<br />

<br />

### Crowdsale Contract

The *Sale* crowdsale contract will accept ethers (ETH) from Ethereum accounts sending ETH.

There is an initial 1 day period when accounts contributing to the crowdsale contract have to be whitelisted before
these contributions are accepted by the crowdsale contract. After this period, there is no check for whitelisted
accounts.

The rate of tokens generated per ETH will vary according to the time of contribution.

ETH contributed by participants to the *Sale* crowdsale contract will result in PRIX tokens being allocated to the
participant's account in the token contract. The contributed ETHs are held in the crowdsale contract but the developer
has stated that they will periodically transfer the ETH into the crowdsale `wallet` after the softcap is reached. This
is to minimise the risk of loss of ETHs in this bespoke smart contract if a unforseen vulnerability is exploited.

The crowdsale contract will generate `Transfer(0x0, participantAddress, tokens)` events during the crowdsale period and this
event is used by token explorers to recognise the token contract and to display the ongoing token minting progress.

The tokens generated in the crowdsale process will not be transferable until after the crowdsale is finalised, and the
softcap is reached. If the softcap is not reached, the tokens will not be transferable, but participants will be able to
execute the `Sale.refund()` function to burn their tokens in exchange for their originally contributed ETH.

<br />

### Token Contract

The token contract is built upon the OpenZeppelin library.

The token contract is [ERC20 Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md)
compliant with the following features:

* `decimals` is correctly defined as `uint8` instead of `uint256`
* `transfer(...)` and `transferFrom(...)` will generally throw if there is an error instead of returning false
* `transfer(...)` and `transferFrom(...)` will successfuly execute if 0 tokens are transferred
* `transfer(...)` and `transferFrom(...)` have not been built with a check on the size of the data being passed (and this 
  check is not an effective check anyway - see
  [Smart Contract Short Address Attack Mitigation Failure](https://blog.coinfabrik.com/smart-contract-short-address-attack-mitigation-failure/))
* `approve(...)` does not require that a non-zero approval limit be set to 0 before a new non-zero limit can be set

<br />

<hr />

## Table Of Contents

* [Summary](#summary)
* [Recommendations](#recommendations)
  * [First Review Recommendations](#first-review-recommendations)
  * [Second Review Recommendations](#second-review-recommendations)
  * [Third Review Recommendations](#third-review-recommendations)
* [Potential Vulnerabilities](#potential-vulnerabilities)
* [Scope](#scope)
* [Limitations](#limitations)
* [Due Diligence](#due-diligence)
* [Risks](#risks)
* [Testing](#testing)
  * [Test 1 Successful Crowdsale](#test-1-successful-crowdsale)
  * [Test 2 Refunds](#test-2-refunds)
* [Code Review](#code-review)

<br />

<hr />

## Recommendations

### First Review Recommendations

* **LOW IMPORTANCE** The event `Transfer(...)` in *Token* is a duplicate of `Transfer(...)` in *ERC20Basic* and should be removed
  * [x] Removed in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)
* **MEDIUM IMPORTANCE** What is the `burn(...)` function for? It breaks the trustlessness of the token contract as the owner can destroy any
  account's token balance. The reply from the developer is that `burn(...)` is only for use by `Sale.refund(...)`.
  
  Replace `function burn(address from) onlyOwner returns (bool) {` with `function burn(address from) internal returns (bool) {` and this
  prevents the contract owner from directly executing the `burn(...)` function, but allows `Sale.refund(...)` to burn refunded tokens
  
  * [x] The developer has brought to my attention that the owner of the *Token* contract is the *Sale* contract, not the crowdsale contract
    owner, so this is not an issue. Also, the `internal` keyword change will prevent this function from working correctly, as the call
    is across contracts from *Sale* to *Token*
* **LOW IMPORTANCE** *Token* has the following statements `StandardToken.transferFrom(from, to, value);`, `BasicToken.transfer(to, value);`,
  `MintableToken.finishMinting();` and `MintableToken.mint(contributor, amount);`. Consider replacing these with
  `super.transferFrom(from, to, value);`, `super.transfer(to, value);`, `super.finishMinting();` and `super.mint(contributor, amount);` as any
  intermediate contract functions may be bypassed
  * [x] Updated in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)
* **LOW IMPORTANCE** The expression `((hardCap / 1000) * 999)` in *Sale* should be rewritten as `((hardCap * 999) / 1000)` for more precision
  in the calculated result. See the following sample calculation

      pragma solidity ^0.4.16;

      contract Test {
          uint public hardCap = 57142e18;
          uint public calc1;
          uint public calc2;
    
          function Test() public {
              // Result 57142000000000000000000
              calc1 = ((hardCap / 1000) * 999);
              // Result 57084858000000000000000
              calc2 = hardCap * 999 / 1000;
          }
      }

  * [x] Fixed in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)
* **MEDIUM IMPORTANCE** *Sale* and *Token* depend on the OpenZeppelin libraries, and the latest version of the OpenZeppelin libraries will
  be used when compiling the *Sale* and *Token* contracts for deployment. There are frequent changes to this library (last set of changes
  5d, 7d, 7d, 8d, 9d, 11d, 12d, 15d, 16d, ... ago). There is a risk that you may compile in partially tested changes. Consider hand-assembling
  the combined source code with a particular OpenZeppelin commit, testing with this version, and checking for further bug fix commits before
  deployment to mainnet. Or note what OpenZeppelin commit you are testing with, and review all new changes in OpenZeppelin before deployment
  to mainnet
  * [x] Developer has been made aware of this
* **LOW IMPORTANCE** In `Sale.updateStatus()` the bounty, team and founders allocations are calculated as 3%, 7% and 7% respectively. Say the
  totalSupply is 100, bounty%=3, team%=7, founders%=7. totalSupply after allocation is 100+3+7+7=117. bounty=3/117=2.56%, team=founders=7/117=
  5.98%. Is this 2.56%, 5.98% and 5.98% the intended distribution?
  * [x] Developer has updated the code in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)
* **LOW IMPORTANCE** In `Sale.updateStatus()`, rewrite the expressions for the bounty, team and founders allocation calculations for more 
  precision. e.g. `bountyAvailable = token.totalSupply() / 100 * 3;` should be `bountyAvailable = (token.totalSupply() * 3) / 100;`.
  Multiplication before division
  * [x] Fixed in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)
* **LOW IMPORTANCE** In *MultiOwners*, consider logging events when new owners are granted access, and existing owners are revoked access
  * [x] Added in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)
* **LOW IMPORTANCE** As stated in the [ERC20 Token Standard](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md#decimals),
  `decimals` should be defined as `uint8`
  * [x] Fixed in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)
* **LOW IMPORTANCE** In *Token*, consider adding `bool _transferAllowed` to the `TransferAllowed(...)` event, removing the `if(...)` condition in
  `finishMinting(...)`, and logging the `_transferAllowed` value
  * [x] Updated in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)
* **LOW IMPORTANCE** In *Token*, `mint(...)` can be called by anyone, but `MintableToken.mint(...)` will only allow the owner to execute
  `Token.mint(...)`. Just a small suggestion to add `onlyOwner` to `Token.mint(...)` to explicitly inform the readers of the source code
  that only the owner can execute this function
  * [x] Updated in [58152e4](https://github.com/Privatix/smart-contract/commit/58152e4759a61c86448008376345aa72bc3cd4c6)

<br />

### Second Review Recommendations

* **LOW IMPORTANCE** Consider updating the Solidity version number from `^0.4.11` and `^0.4.13` to a recent version
  * [x] Updated to `^0.4.15` in [ce37920](https://github.com/Privatix/smart-contract/commit/ce37920852e289ba26543bc9316075c9a66cdad7)
* **LOW IMPORTANCE** The modifier `Sale.isStarted()` is not used. Consider removing this modifier
  * [x] Not removed, as it would be useful for viewing the the blockchain explorer
* **LOW IMPORTANCE** In `Sale.calcAmount(...)`, rewrite `return ((_value / weiPerToken) / 100) * rate;` as
  `return (_value * rate / weiPerToken) / 100;` for better precision
  * [x] Fixed in [609c861](https://github.com/Privatix/smart-contract/commit/609c86107087823ffd678bcc1fcebba917f79a51) 
* **LOW IMPORTANCE** Two `Transfer(0x0, ...)` events are logged for each minting event. `Token.mint(...)` emits one `Transfer(0x0, ...)` event and
  then calls `MintableToken.mint(...)` that also emits one `Transfer(0x0, ...)` event. `Token.mint(...)` can probably be removed as it does not
  add any functionality over `MintableToken.mint(...)`

      Mint 0 #229 {"amount":"11199999999860","to":"0x992066a964c241ed4996e750284d039b14a19fa5"}
      Mint 1 #229 {"amount":"9333333333170","to":"0x1f4df63b8d32e54d94141ef8475c55df4db2a02d"}
      ...
      Transfer 0 #229: from=0x0000000000000000000000000000000000000000 to=0x992066a964c241ed4996e750284d039b14a19fa5 value=111999.9999986
      Transfer 1 #229: from=0x0000000000000000000000000000000000000000 to=0x992066a964c241ed4996e750284d039b14a19fa5 value=111999.9999986
      Transfer 2 #229: from=0x0000000000000000000000000000000000000000 to=0x1f4df63b8d32e54d94141ef8475c55df4db2a02d value=93333.3333317
      Transfer 3 #229: from=0x0000000000000000000000000000000000000000 to=0x1f4df63b8d32e54d94141ef8475c55df4db2a02d value=93333.3333317
      ...

  * [x] Fixed in [ce37920](https://github.com/Privatix/smart-contract/commit/ce37920852e289ba26543bc9316075c9a66cdad7)

<br />

### Third Review Recommendations

* **MEDIUM IMPORTANCE** While the crowdsale contract can be made as safe as possible, it it still a bespoke contract with little testing compared
  to the hardware wallets or multisig wallets. For this reason, the risk of ETH being stolen or stuck in this contract can be reduced by
  immediately transferring all ETH contributions to the crowdsale wallet. As there is a `softCap` where refunds will be available to 
  participants if the `softCap` is not reached, store the ETH in the crowdsale contract until the `softCap` is reached. After this, transfer
  all ETH balances immediately to the crowdsale wallet using `wallet.transfer(eth.balance);`.
  
  For this to occur, the calculation of `softCapReached` will need to be moved into `buyTokens(...)`. And a few other changes need to be made.
  
  * [x] Developer wants to keep the gas cost of contributions down to 90,000 and to minimise ETH sitting in the crowdsale contract the 
    crowdsale administrator will call `withdraw()` frequently, after the `softCap` has been reached 

* **LOW IMPORTANCE** In *Sale*, the first parameter `purchaser` of the event `TokenPurchase(...)` is redundant as it will always be 0x0. Consider
  removing this parameter

  * [x] Removed in [5fda921](https://github.com/Privatix/smart-contract/commit/5fda9217e40aad85a9d12d05c19aa3955fd10fb9)

* **LOW IMPORTANCE** In `Sale.refund()` it is safer to have the `msg.sender.transfer(etherBalances[msg.sender]);` executed after the tokens
  have been burnt, and `etherBalances[msg.sender] = 0;`. This is because the control flow will be transferred to potentially a malicious contract.
  In this case the amount of gas provided to the malicious contract will be low, so the damage is limited. But it's always safer to zero the
  account's balance before transferring control outside the contract.

  * [x] Fixed in [fde2422](https://github.com/Privatix/smart-contract/commit/fde2422394212f7e6fbea7318432860273149511)

* **LOW IMPORTANCE** Mark `Sale.withdraw()` and `Sale.withdrawTokenToFounder()` to be executed by `onlyOwner` just to be on the safe side. The 
  funds and tokens respectively will be transferred to the crowdsale wallet anyway, but there is no harm restricting the use of this function

  * [x] Fixed in [fde2422](https://github.com/Privatix/smart-contract/commit/fde2422394212f7e6fbea7318432860273149511)

* **LOW IMPORTANCE** Mark `Sale.finishCrowdsale()` to be executed by `onlyOwner` just to be on the safe side

  * [x] Fixed in [fde2422](https://github.com/Privatix/smart-contract/commit/fde2422394212f7e6fbea7318432860273149511)

* **LOW IMPORTANCE** Remove `Sale.running()` as this function is not used

  * [x] Developer explained that this status will be viewable in the blockchain explorers

* **LOW IMPORTANCE** `Sale.addWhitelist(...)` and `Sale.buyTokens(...)` should be marked as `public` but this is the default anyway

  * [x] Fixed in [e8fbb6d](https://github.com/Privatix/smart-contract/commit/e8fbb6dd9372a844d2a8e716104aa141d3552b92)

* **LOW IMPORTANCE** `SafeMath` is not used in *Sale*

  * [x] Fixed in [f7a1ce3](https://github.com/Privatix/smart-contract/commit/f7a1ce31e2640daabc0f4198493a6c914e28f842)

<br />

<hr />

## Potential Vulnerabilities

No potential vulnerabilities have been identified in the crowdsale and token contract.

<br />

<hr />

## Scope

This audit is into the technical aspects of the crowdsale contracts. The primary aim of this audit is to ensure that funds
contributed to these contracts are not easily attacked or stolen by third parties. The secondary aim of this audit is that
ensure the coded algorithms work as expected. This audit does not guarantee that that the code is bugfree, but intends to
highlight any areas of weaknesses.

<br />

<hr />

## Limitations

This audit makes no statements or warranties about the viability of the Privatix's business proposition, the individuals
involved in this business or the regulatory regime for the business model.

<br />

<hr />

## Due Diligence

As always, potential participants in any crowdsale are encouraged to perform their due diligence on the business proposition
before funding any crowdsales.

Potential participants are also encouraged to only send their funds to the official crowdsale Ethereum address, published on
the crowdsale beneficiary's official communication channel.

Scammers have been publishing phishing address in the forums, twitter and other communication channels, and some go as far as
duplicating crowdsale websites. Potential participants should NOT just click on any links received through these messages.
Scammers have also hacked the crowdsale website to replace the crowdsale contract address with their scam address.
 
Potential participants should also confirm that the verified source code on EtherScan.io for the published crowdsale address
matches the audited source code, and that the deployment parameters are correctly set, including the constant parameters.

<br />

<hr />

## Risks

* The risk of funds getting stolen or hacked from the *Sale* contract can be minimised if the crowdsale administrators 
  regularly transfer out any accummulated ETH in the crowdsale contract, after the softCap is reached.

<br />

<hr />

## Testing

Note that this testing uses the OpenZeppelin library commit 
[5cf5036](https://github.com/OpenZeppelin/zeppelin-solidity/commit/5cf503673faea92c1b5c615c3f8358febf06e160).

<br />

### Test 1 Successful Crowdsale

The following functions were tested using the script [test/01_test1.sh](test/01_test1.sh) with the summary results saved
in [test/test1results.txt](test/test1results.txt) and the detailed output saved in [test/test1output.txt](test/test1output.txt):

* [x] Deploy *Sale* contract
* [x] Send contribution before start and no whitelist - expecting failure
* [x] Add whitelisted addresses
* [x] Send contribution before start - success for whitelisted account, failure for non-whitelisted account
* [x] Send contribution after start - success for whitelisted and non-whitelisted account
* [x] Send contribution to hard cap
* [x] Attempt transfers - failure
* [x] Finish crowdsale
* [x] Move crowdsale funds to wallet
* [x] Transfer tokens
* [x] Withdraw tokens to founder after long wait period

<br />

### Test 2 Refunds

The following functions were tested using the script [test/02_test2.sh](test/02_test2.sh) with the summary results saved
in [test/test2results.txt](test/test2results.txt) and the detailed output saved in [test/test2output.txt](test/test2output.txt):

* [x] Deploy *Sale* contract
* [x] Add whitelisted addresses
* [x] Send small contribution after whitelist period over
* [x] Finish crowdsale
* [x] Move crowdsale funds and tokens to wallet - expecting failure
* [x] Withdraw refunds

<br />

<hr />

## Code Review

* [x] [code-review/MultiOwners.md](code-review/MultiOwners.md)
  * [x] contract MultiOwners 
* [x] [code-review/Sale.md](code-review/Sale.md)
  * [x] contract Sale is MultiOwners 
* [x] [code-review/Token.md](code-review/Token.md)
  * [x] contract Token is MintableToken 


<br />

### OpenZeppelin Code Review

From [OpenZeppelin Solidity contracts](https://github.com/OpenZeppelin/zeppelin-solidity/tree/master/contracts).

Commit [5cf5036](https://github.com/OpenZeppelin/zeppelin-solidity/commit/5cf503673faea92c1b5c615c3f8358febf06e160).

* [x] [openzeppelin-code-review/math/SafeMath.md](openzeppelin-code-review/math/SafeMath.md)
  * [x] library SafeMath
* [x] [openzeppelin-code-review/ownership/Ownable.md](openzeppelin-code-review/ownership/Ownable.md)
  * [x] contract Ownable
* [x] [openzeppelin-code-review/token/ERC20Basic.md](openzeppelin-code-review/token/ERC20Basic.md)
  * [x] contract ERC20Basic 
* [x] [openzeppelin-code-review/token/ERC20.md](openzeppelin-code-review/token/ERC20.md)
  * [x] contract ERC20 is ERC20Basic 
* [x] [openzeppelin-code-review/token/BasicToken.md](openzeppelin-code-review/token/BasicToken.md)
  * [x] contract BasicToken is ERC20Basic 
* [x] [openzeppelin-code-review/token/StandardToken.md](openzeppelin-code-review/token/StandardToken.md)
  * [x] contract StandardToken is ERC20, BasicToken 
* [x] [openzeppelin-code-review/token/MintableToken.md](openzeppelin-code-review/token/MintableToken.md)
  * [x] contract MintableToken is StandardToken, Ownable 

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

<br />

<br />

(c) BokkyPooBah / Bok Consulting Pty Ltd for Privatix - Oct 9 2017. The MIT Licence.