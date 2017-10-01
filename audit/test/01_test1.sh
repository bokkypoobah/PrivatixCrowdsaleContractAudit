#!/bin/bash
# ----------------------------------------------------------------------------------------------
# Testing the smart contract
#
# Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2017. The MIT Licence.
# ----------------------------------------------------------------------------------------------

MODE=${1:-test}

GETHATTACHPOINT=`grep ^IPCFILE= settings.txt | sed "s/^.*=//"`
PASSWORD=`grep ^PASSWORD= settings.txt | sed "s/^.*=//"`

SOURCEDIR=`grep ^SOURCEDIR= settings.txt | sed "s/^.*=//"`

CROWDSALESOL=`grep ^CROWDSALESOL= settings.txt | sed "s/^.*=//"`
CROWDSALEJS=`grep ^CROWDSALEJS= settings.txt | sed "s/^.*=//"`
TOKENSOL=`grep ^TOKENSOL= settings.txt | sed "s/^.*=//"`

DEPLOYMENTDATA=`grep ^DEPLOYMENTDATA= settings.txt | sed "s/^.*=//"`

INCLUDEJS=`grep ^INCLUDEJS= settings.txt | sed "s/^.*=//"`
TEST1OUTPUT=`grep ^TEST1OUTPUT= settings.txt | sed "s/^.*=//"`
TEST1RESULTS=`grep ^TEST1RESULTS= settings.txt | sed "s/^.*=//"`

CURRENTTIME=`date +%s`
CURRENTTIMES=`date -r $CURRENTTIME -u`

BLOCKSINDAY=10

if [ "$MODE" == "dev" ]; then
  # Start time now
  STARTTIME=`echo "$CURRENTTIME" | bc`
else
  # Start time 1m 10s in the future
  STARTTIME=`echo "$CURRENTTIME+90" | bc`
fi
STARTTIME_S=`date -r $STARTTIME -u`
ENDTIME=`echo "$CURRENTTIME+60*5" | bc`
ENDTIME_S=`date -r $ENDTIME -u`

printf "MODE            = '$MODE'\n" | tee $TEST1OUTPUT
printf "GETHATTACHPOINT = '$GETHATTACHPOINT'\n" | tee -a $TEST1OUTPUT
printf "PASSWORD        = '$PASSWORD'\n" | tee -a $TEST1OUTPUT
printf "SOURCEDIR       = '$SOURCEDIR'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALESOL    = '$CROWDSALESOL'\n" | tee -a $TEST1OUTPUT
printf "CROWDSALEJS     = '$CROWDSALEJS'\n" | tee -a $TEST1OUTPUT
printf "TOKENSOL        = '$TOKENSOL'\n" | tee -a $TEST1OUTPUT
printf "DEPLOYMENTDATA  = '$DEPLOYMENTDATA'\n" | tee -a $TEST1OUTPUT
printf "INCLUDEJS       = '$INCLUDEJS'\n" | tee -a $TEST1OUTPUT
printf "TEST1OUTPUT     = '$TEST1OUTPUT'\n" | tee -a $TEST1OUTPUT
printf "TEST1RESULTS    = '$TEST1RESULTS'\n" | tee -a $TEST1OUTPUT
printf "CURRENTTIME     = '$CURRENTTIME' '$CURRENTTIMES'\n" | tee -a $TEST1OUTPUT
printf "STARTTIME       = '$STARTTIME' '$STARTTIME_S'\n" | tee -a $TEST1OUTPUT
printf "ENDTIME         = '$ENDTIME' '$ENDTIME_S'\n" | tee -a $TEST1OUTPUT

# Make copy of SOL file and modify start and end times ---
# `cp modifiedContracts/SnipCoin.sol .`
`cp $SOURCEDIR/$CROWDSALESOL .`
`cp $SOURCEDIR/$TOKENSOL .`
`cp $SOURCEDIR/MultiOwners.sol .`
`cp ../openzeppelin-contracts/math/SafeMath.sol .`
`cp ../openzeppelin-contracts/ownership/Ownable.sol .`
`cp ../openzeppelin-contracts/token/MintableToken.sol .`
`cp ../openzeppelin-contracts/token/StandardToken.sol .`
`cp ../openzeppelin-contracts/token/BasicToken.sol .`
`cp ../openzeppelin-contracts/token/ERC20.sol .`
`cp ../openzeppelin-contracts/token/ERC20Basic.sol .`

# --- Modify parameters ---
`perl -pi -e "s/zeppelin-solidity\/contracts\/math\//.\//" $CROWDSALESOL`
# Modify non-whitelist period from from 1 day to 1 minute
`perl -pi -e "s/startTime \+ 1 days \< now/startTime \+ 1 minutes \< now/" $CROWDSALESOL`
# Modify end date to 3 minutes after start date
`perl -pi -e "s/endTime \= _startTime \+ 28 days/endTime \= _startTime \+ 3 minutes/" $CROWDSALESOL`
`perl -pi -e "s/zeppelin-solidity\/contracts\/token\//.\//" $TOKENSOL`
`perl -pi -e "s/..\/ownership\//.\//" MintableToken.sol`
`perl -pi -e "s/..\/math\//.\//" BasicToken.sol`
# `perl -pi -e "s/bool transferable/bool public transferable/" $TOKENSOL`
# `perl -pi -e "s/MULTISIG_WALLET_ADDRESS \= 0xc79ab28c5c03f1e7fbef056167364e6782f9ff4f;/MULTISIG_WALLET_ADDRESS \= 0xa22AB8A9D641CE77e06D98b7D7065d324D3d6976;/" GimliCrowdsale.sol`
# `perl -pi -e "s/START_DATE = 1505736000;.*$/START_DATE \= $STARTTIME; \/\/ $STARTTIME_S/" GimliCrowdsale.sol`
# `perl -pi -e "s/END_DATE = 1508500800;.*$/END_DATE \= $ENDTIME; \/\/ $ENDTIME_S/" GimliCrowdsale.sol`
# `perl -pi -e "s/VESTING_1_DATE = 1537272000;.*$/VESTING_1_DATE \= $VESTING1TIME; \/\/ $VESTING1TIME_S/" GimliCrowdsale.sol`
# `perl -pi -e "s/VESTING_2_DATE = 1568808000;.*$/VESTING_2_DATE \= $VESTING2TIME; \/\/ $VESTING2TIME_S/" GimliCrowdsale.sol`

DIFFS1=`diff $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL`
echo "--- Differences $SOURCEDIR/$CROWDSALESOL $CROWDSALESOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

DIFFS1=`diff $SOURCEDIR/$TOKENSOL $TOKENSOL`
echo "--- Differences $SOURCEDIR/$TOKENSOL $TOKENSOL ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

DIFFS1=`diff ../openzeppelin-contracts/token/MintableToken.sol MintableToken.sol`
echo "--- Differences ../openzeppelin-contracts/token/MintableToken.sol MintableToken.sol ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

DIFFS1=`diff ../openzeppelin-contracts/token/BasicToken.sol BasicToken.sol`
echo "--- Differences ../openzeppelin-contracts/token/BasicToken.sol BasicToken.sol ---" | tee -a $TEST1OUTPUT
echo "$DIFFS1" | tee -a $TEST1OUTPUT

echo "var saleOutput=`solc --optimize --combined-json abi,bin,interface $CROWDSALESOL`;" > $CROWDSALEJS

geth --verbosity 3 attach $GETHATTACHPOINT << EOF | tee -a $TEST1OUTPUT
loadScript("$CROWDSALEJS");
loadScript("functions.js");

var saleAbi = JSON.parse(saleOutput.contracts["$CROWDSALESOL:Sale"].abi);
var saleBin = "0x" + saleOutput.contracts["$CROWDSALESOL:Sale"].bin;
var tokenAbi = JSON.parse(saleOutput.contracts["$TOKENSOL:Token"].abi);
var tokenBin = "0x" + saleOutput.contracts["$TOKENSOL:Token"].bin;

// console.log("DATA: saleAbi=" + JSON.stringify(saleAbi));
// console.log("DATA: saleBin=" + JSON.stringify(saleBin));
// console.log("DATA: tokenAbi=" + JSON.stringify(tokenAbi));
// console.log("DATA: tokenBin=" + JSON.stringify(tokenBin));

unlockAccounts("$PASSWORD");
printBalances();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var saleMessage = "Deploy Crowdsale/Token Contract";
// -----------------------------------------------------------------------------
console.log("RESULT: " + saleMessage);
var saleContract = web3.eth.contract(saleAbi);
// console.log(JSON.stringify(saleContract));
var saleTx = null;
var saleAddress = null;
var token = null;

// console.log("RESULT: parameters=" + $STARTTIME + ", \"" + wallet + "\"");
var sale = saleContract.new($STARTTIME, wallet, {from: contractOwnerAccount, data: saleBin, gas: 6000000},
  function(e, contract) {
    if (!e) {
      if (!contract.address) {
        saleTx = contract.transactionHash;
      } else {
        saleAddress = contract.address;
        token = web3.eth.contract(tokenAbi).at(sale.token());
        addAccount(saleAddress, "Sale");
        addAccount(sale.token(), "Token '" + token.symbol() + "' '" + token.name() + "'");
        addCrowdsaleContractAddressAndAbi(saleAddress, saleAbi);
        addTokenContractAddressAndAbi(sale.token(), tokenAbi);
        console.log("DATA: saleAddress=" + saleAddress);
      }
    }
  }
);

while (txpool.status.pending > 0) {
}

printTxData("saleAddress=" + saleAddress, saleTx);
printBalances();
failIfGasEqualsGasUsed(saleTx, saleMessage);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var whitelistMessage = "Whitelist";
// -----------------------------------------------------------------------------
console.log("RESULT: " + whitelistMessage);
var whitelist1Tx = sale.addWhitelist(account3, web3.toWei(1000, "ether"), {from: contractOwnerAccount, gas: 400000});
// var whitelist2Tx = sale.addWhitelist(account4, web3.toWei(1000, "ether"), {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("whitelist1Tx", whitelist1Tx);
// printTxData("whitelist2Tx", whitelist2Tx);
printBalances();
failIfGasEqualsGasUsed(whitelist1Tx, whitelistMessage + " - ac3 Whitelist");
// failIfGasEqualsGasUsed(whitelist2Tx, whitelistMessage + " - ac4 Whitelist Capped");
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution1Message = "Send Contribution Before Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution1Message);
var sendContribution1_1Tx = eth.sendTransaction({from: account3, to: saleAddress, gas: 400000, value: web3.toWei("1", "ether")});
var sendContribution1_2Tx = eth.sendTransaction({from: account4, to: saleAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution1_1Tx", sendContribution1_1Tx);
printTxData("sendContribution1_2Tx", sendContribution1_2Tx);
printBalances();
passIfGasEqualsGasUsed(sendContribution1_1Tx, sendContribution1Message + " - ac3 1 ETH - Expecting Failure");
passIfGasEqualsGasUsed(sendContribution1_2Tx, sendContribution1Message + " - ac4 1 ETH - Expecting Failure");
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for crowdsale start
// -----------------------------------------------------------------------------
var startTime = sale.startTime();
var startTimeDate = new Date(startTime * 1000);
console.log("RESULT: Waiting until startTime at " + startTime + " " + startTimeDate + " currentDate=" + new Date());
while ((new Date()).getTime() <= startTimeDate.getTime()) {
}
console.log("RESULT: Waited until startTime at " + startTime + " " + startTimeDate + " currentDate=" + new Date());


// -----------------------------------------------------------------------------
var sendContribution2Message = "Send Contribution After Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution2Message);
var sendContribution2_1Tx = eth.sendTransaction({from: account3, to: saleAddress, gas: 400000, value: web3.toWei("2000", "ether")});
var sendContribution2_2Tx = eth.sendTransaction({from: account4, to: saleAddress, gas: 400000, value: web3.toWei("2000", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution2_1Tx", sendContribution2_1Tx);
printTxData("sendContribution2_2Tx", sendContribution2_2Tx);
printBalances();
passIfGasEqualsGasUsed(sendContribution2_1Tx, sendContribution2Message + " - ac3 2,000 ETH - Expecting Failure - Over Whitelist");
passIfGasEqualsGasUsed(sendContribution2_2Tx, sendContribution2Message + " - ac4 2,000 ETH - Expecting Failure - Not Whitelisted");
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution3Message = "Send Contribution After Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution3Message);
var sendContribution3_1Tx = eth.sendTransaction({from: account3, to: saleAddress, gas: 400000, value: web3.toWei("1000", "ether")});
var sendContribution3_2Tx = eth.sendTransaction({from: account4, to: saleAddress, gas: 400000, value: web3.toWei("1000", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution3_1Tx", sendContribution3_1Tx);
printTxData("sendContribution3_2Tx", sendContribution3_2Tx);
printBalances();
failIfGasEqualsGasUsed(sendContribution3_1Tx, sendContribution3Message + " - ac3 1,000 ETH = 140,000 PRIX");
passIfGasEqualsGasUsed(sendContribution3_2Tx, sendContribution3Message + " - ac4 1,000 ETH - Expecting Failure - Not Whitelisted");
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
// Wait for whitelist period over
// -----------------------------------------------------------------------------
var whitelistOverTime = parseInt(sale.startTime()) + 60;
var whitelistOverTimeDate = new Date(whitelistOverTime * 1000);
console.log("RESULT: Waiting until whitelistOverTime at " + whitelistOverTime + " " + whitelistOverTimeDate + " currentDate=" + new Date());
while ((new Date()).getTime() <= whitelistOverTimeDate.getTime()) {
}
console.log("RESULT: Waited until whitelistOverTime at " + whitelistOverTime + " " + whitelistOverTimeDate + " currentDate=" + new Date());


// -----------------------------------------------------------------------------
var sendContribution4Message = "Send Contribution After Whitelist Over";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution4Message);
var sendContribution4_1Tx = eth.sendTransaction({from: account3, to: saleAddress, gas: 400000, value: web3.toWei("1200", "ether")});
var sendContribution4_2Tx = eth.sendTransaction({from: account4, to: saleAddress, gas: 400000, value: web3.toWei("1200", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution4_1Tx", sendContribution4_1Tx);
printTxData("sendContribution4_2Tx", sendContribution4_2Tx);
printBalances();
failIfGasEqualsGasUsed(sendContribution4_1Tx, sendContribution4Message + " - ac3 1,200 ETH = 168,000 PRIX");
failIfGasEqualsGasUsed(sendContribution4_2Tx, sendContribution4Message + " - ac4 1,200 ETH = 168,000 PRIX");
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution5Message = "Send Contribution To Hard Cap";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution5Message);
var sendContribution5_1Tx = eth.sendTransaction({from: account3, to: saleAddress, gas: 400000, value: web3.toWei("26871", "ether")});
var sendContribution5_2Tx = eth.sendTransaction({from: account4, to: saleAddress, gas: 400000, value: web3.toWei("26871", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution5_1Tx", sendContribution5_1Tx);
printTxData("sendContribution5_2Tx", sendContribution5_2Tx);
printBalances();
failIfGasEqualsGasUsed(sendContribution5_1Tx, sendContribution5Message + " - ac3 26,871 ETH = 3,761,940 PRIX");
failIfGasEqualsGasUsed(sendContribution5_2Tx, sendContribution5Message + " - ac4 26,871 ETH = 3,761,940 PRIX");
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var finishCrowdsaleMessage = "Finish Crowdsale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + finishCrowdsaleMessage);
var finishCrowdsale1Tx = sale.finishCrowdsale({from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("finishCrowdsale1Tx", finishCrowdsale1Tx);
printBalances();
failIfGasEqualsGasUsed(finishCrowdsale1Tx, finishCrowdsaleMessage);
printCrowdsaleContractDetails();
printTokenContractDetails();
console.log("RESULT: ");


exit;


// -----------------------------------------------------------------------------
var openSaleMessage = "Open Sale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + openSaleMessage);
var openSaleTx = token.openOrCloseSale(true, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("openSaleTx", openSaleTx);
printBalances();
failIfGasEqualsGasUsed(openSaleTx, openSaleMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution2Message = "Send Contribution After Start";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution2Message);
var sendContribution2Tx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("1", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution2Tx", sendContribution2Tx);
printBalances();
failIfGasEqualsGasUsed(sendContribution2Tx, sendContribution2Message + " - ac3 1 ETH = 300,000 SNIP");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution3Message = "Send Contribution After Start - Past Cap";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution3Message);
var sendContribution3_aTx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
var sendContribution3_bTx = eth.sendTransaction({from: account4, to: tokenAddress, gas: 400000, value: web3.toWei("100", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution3_aTx", sendContribution3_aTx);
printTxData("sendContribution3_bTx", sendContribution3_bTx);
printBalances();
failIfGasEqualsGasUsed(sendContribution3_aTx, sendContribution3Message + " - ac3 100 ETH - 30,000,000");
passIfGasEqualsGasUsed(sendContribution3_bTx, sendContribution3Message + " - ac4 100 ETH - Fail");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var sendContribution4Message = "Send Contribution After Start - Below Cap";
// -----------------------------------------------------------------------------
console.log("RESULT: " + sendContribution4Message);
var sendContribution4_aTx = eth.sendTransaction({from: account3, to: tokenAddress, gas: 400000, value: web3.toWei("10", "ether")});
var sendContribution4_bTx = eth.sendTransaction({from: account4, to: tokenAddress, gas: 400000, value: web3.toWei("10", "ether")});
while (txpool.status.pending > 0) {
}
printTxData("sendContribution4_aTx", sendContribution4_aTx);
printTxData("sendContribution4_bTx", sendContribution4_bTx);
printBalances();
failIfGasEqualsGasUsed(sendContribution4_aTx, sendContribution4Message + " - ac3 10 ETH - 3,000,000");
failIfGasEqualsGasUsed(sendContribution4_bTx, sendContribution4Message + " - ac4 10 ETH - 3,000,000");
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var closeSaleMessage = "Close Sale";
// -----------------------------------------------------------------------------
console.log("RESULT: " + closeSaleMessage);
var closeSaleTx = token.openOrCloseSale(false, {from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("closeSaleTx", closeSaleTx);
printBalances();
failIfGasEqualsGasUsed(closeSaleTx, closeSaleMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var allowTransfersMessage = "Enable Transfers";
// -----------------------------------------------------------------------------
console.log("RESULT: " + allowTransfersMessage);
var allowTransfersTx = token.allowTransfers({from: contractOwnerAccount, gas: 400000});
while (txpool.status.pending > 0) {
}
printTxData("allowTransfersTx", allowTransfersTx);
printBalances();
failIfGasEqualsGasUsed(allowTransfersTx, allowTransfersMessage);
printTokenContractDetails();
console.log("RESULT: ");


// -----------------------------------------------------------------------------
var moveTokenMessage = "Move Tokens After Transfers Allowed";
// -----------------------------------------------------------------------------
console.log("RESULT: " + moveTokenMessage);
var moveToken1Tx = token.transfer(account5, "100000000000000000", {from: account3, gas: 100000});
var moveToken2Tx = token.approve(account6,  "3000000000000000000", {from: account4, gas: 100000});
while (txpool.status.pending > 0) {
}
var moveToken3Tx = token.transferFrom(account4, account7, "3000000000000000000", {from: account6, gas: 100000});
while (txpool.status.pending > 0) {
}
printTxData("moveToken1Tx", moveToken1Tx);
printTxData("moveToken2Tx", moveToken2Tx);
printTxData("moveToken3Tx", moveToken3Tx);
printBalances();
failIfGasEqualsGasUsed(moveToken1Tx, moveTokenMessage + " - transfer 0.1 SNIP ac3 -> ac5. CHECK for movement");
failIfGasEqualsGasUsed(moveToken2Tx, moveTokenMessage + " - approve 3 SNIP ac4 -> ac6");
failIfGasEqualsGasUsed(moveToken3Tx, moveTokenMessage + " - transferFrom 3 SNIP ac4 -> ac7 by ac6. CHECK for movement");
printTokenContractDetails();
console.log("RESULT: ");


EOF
grep "DATA: " $TEST1OUTPUT | sed "s/DATA: //" > $DEPLOYMENTDATA
cat $DEPLOYMENTDATA
grep "RESULT: " $TEST1OUTPUT | sed "s/RESULT: //" > $TEST1RESULTS
cat $TEST1RESULTS
