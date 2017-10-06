import increaseTime, { duration } from 'zeppelin-solidity/test/helpers/increaseTime';
import moment from 'moment';


var Token = artifacts.require("./Token.sol");
var Sale = artifacts.require("./Sale.sol");


contract('Sale', (accounts) => {
    let owner, wallet, client, client_wl, token, sale, startTime, endTime;
    let testMaxTokens, testMaxEthers, testMinEthers, testRate;


    before(async () => {
        owner = web3.eth.accounts[0];
        wallet = web3.eth.accounts[1];
        client = web3.eth.accounts[2];
        client_wl = web3.eth.accounts[3];
    });

    let balanceEqualTo = async (client, should_balance) => {
        let balance;

        balance = await token.balanceOf(client, {from: client});
        assert.equal(balance.toNumber(), should_balance, `Token balance should be equal to ${should_balance}`);
    };

    let shouldHaveException = async (fn, error_msg) => {
        let has_error = false;

        try {
            await fn();
        } catch(err) {
            has_error = true;
        } finally {
            assert.equal(has_error, true, error_msg);
        }        

    }

    let calcAmount = (amount) => {
        let rate = getCurrentRate();
        return amount / testRate * rate;
    }

    let getCurrentRate = () => {
        let currentTime = web3.eth.getBlock('latest').timestamp;
        let rate;

        if((startTime + 86400 * 2) > currentTime) {
            rate = 1.4;
        } else if((startTime + 86400 * 7) > currentTime) {
            rate = 1.3;
        } else if((startTime + 86400 * 14) > currentTime) {
            rate = 1.2;
        } else if((startTime + 86400 * 21) > currentTime) {
            rate = 1.1;
        } else {
            rate = 1.05;
        }
        return rate;
    }

    let calcEthers = (amount) => {
        let rate = getCurrentRate();
        return amount * testRate / rate;
    }

    beforeEach(async function () {
        startTime = web3.eth.getBlock('latest').timestamp + duration.weeks(1);
        sale = await Sale.new(startTime, wallet);
        token = await Token.at(await sale.token());
        testRate = await sale.weiPerToken();
        testMaxEthers = (await sale.hardCap()).toNumber();
        testMinEthers = (await sale.softCap()).toNumber();
        testMaxTokens = testMaxEthers / testRate * 1.4;
    })
  
    // Sale :: check token from Pre-ICO was transfered to new token contract
    it("Before donate", async () => {
        assert.equal((await token.balanceOf(client)).toNumber(), 0, "balanceOf must be 0 on the start");
        assert.equal((await token.totalSupply()).toNumber(), 29993599999510, "totalSupply must be 29993599999510 on the start");
    });

    // running
    it("Start Presale", async() => {
        assert.equal((await sale.running()), false);
        await increaseTime(duration.weeks(1));
        assert.equal((await sale.running()), true);
    });

    it("token.transfer :: forbid transfer and transferFrom until ITO", async() => {
        await increaseTime(duration.weeks(2));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(4)});

        await shouldHaveException(async () => {
            await token.transfer(client, 1e8, {from: client});
        }, "Should has an error");

        await shouldHaveException(async () => {
            await token.transferFrom(client, client, 1e8, {from: client});
        }, "Should has an error");

        await shouldHaveException(async () => {
            await sale.refund({from: client});
        }, "Should has an error");
    });

    it("token.transfer :: allow transfer token after ITO", async () => {
        await increaseTime(duration.weeks(2));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMinEthers});
        await increaseTime(duration.weeks(3));
        await sale.finishCrowdsale();
        assert.equal((await token.mintingFinished()), true);
        assert.equal((await token.transferAllowed()), true);

        await token.transfer(client, 1e8, {from: client});

        await shouldHaveException(async () => {
            await sale.refund({from: client});
        }, "Should has an error");

        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client, to: sale.address, value: 1e18});
        }, "Should has an error");
    });

    // minimalTokenPrice :: do not allow to sell less than minimalTokenPrice
    it("Do not sell less than token", async() => {
        await increaseTime(duration.days(9));
        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client, to: sale.address, value: (web3.toWei(1)/testRate) - 1});
        }, "Should has an error");
    });

    it("buyTokens : discount 40%", async() => {
        await increaseTime(duration.days(8));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(1)});
        await balanceEqualTo(client, 140e8);
    });

    it("buyTokens : discount 30%", async() => {
        await increaseTime(duration.days(9));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(1)});
        await balanceEqualTo(client, 130e8);
    });

    it("buyTokens : discount 20%", async() => {
        await increaseTime(duration.weeks(2));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(1)});
        await balanceEqualTo(client, 120e8);
    });

    it("buyTokens : discount 10%", async() => {
        await increaseTime(duration.weeks(3));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(1)});
        await balanceEqualTo(client, 110e8);
    });

    it("buyTokens : discount 5%", async() => {
        await increaseTime(duration.weeks(4));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(1)});
        await balanceEqualTo(client, 105e8);
    });

    it("withdraw : withdraw ether to wallet if softcap reached", async() => {
        let balance1, balance2, balance3;

        balance1 = (await web3.eth.getBalance(wallet)).toNumber();
        await increaseTime(duration.weeks(2));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMinEthers});
        await sale.withdraw();
        balance2 = (await web3.eth.getBalance(wallet)).toNumber();

        assert.equal(Math.round((balance2 - balance1)/1e18), Math.round(testMinEthers/1e18));


        await web3.eth.sendTransaction({from: client, to: sale.address, value: 1e18});
        await sale.withdraw();
        balance3 = (await web3.eth.getBalance(wallet)).toNumber();

        assert.equal(Math.round((balance3 - balance2)/1e18), 1);
    });

    it("withdraw : withdraw ether to wallet if not softcap reached", async() => {
        let balance1, balance2, balance3;

        balance1 = (await web3.eth.getBalance(wallet)).toNumber();
        await increaseTime(duration.weeks(2));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: 1e18});

        await shouldHaveException(async () => {
            await sale.withdraw();
        }, "Should has an error");
        balance2 = (await web3.eth.getBalance(wallet)).toNumber();

        assert.equal(Math.round((balance2 - balance1)/1e18), 0);
    });

    it("withdrawTokenToFounder : withdraw token to founder after 1 year if softcap reached", async() => {
        await increaseTime(duration.weeks(2));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMaxEthers});

        await increaseTime(duration.weeks(5));
        await sale.finishCrowdsale();

        await increaseTime(duration.years(1));
        await sale.withdrawTokenToFounder();
    });

    it("withdrawTokenToFounder : withdraw token to founder before 1 year if softcap reached", async() => {
        await increaseTime(duration.weeks(2));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMaxEthers});
        await increaseTime(duration.weeks(5));
        await sale.finishCrowdsale();

        await shouldHaveException(async () => {
            await sale.withdrawTokenToFounder();
        }, "Should has an error");
    });

    it("withdrawTokenToFounder : withdraw token to founder after 1 year if not softcap reached", async() => {
        await increaseTime(duration.weeks(2));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: 1e18});

        await increaseTime(duration.weeks(5));
        await sale.finishCrowdsale();

        await increaseTime(duration.years(1));

        await shouldHaveException(async () => {
            await sale.withdrawTokenToFounder();
        }, "Should has an error");
    });

    it("refund : refund ethers back to backers if not softcap reached after ito", async() => {
        await increaseTime(duration.weeks(2));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: 10e18});

        await increaseTime(duration.weeks(4));
        await sale.finishCrowdsale();

        await sale.refund({from: client});
    });

    it("refund : refund ethers back to backers if softcap reached after ito", async() => {
        await increaseTime(duration.weeks(2));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMinEthers});

        await increaseTime(duration.weeks(4));
        await sale.finishCrowdsale();

        await shouldHaveException(async () => {
            await sale.refund({from: client});
        }, "Should has an error");
    });

    it("refund : refund ethers back to backers if softcap reached when ito in progress", async() => {
        await increaseTime(duration.weeks(2));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMaxEthers});

        await sale.finishCrowdsale();

        await shouldHaveException(async () => {
            await sale.refund({from: client});
        }, "Should has an error");
    });

    it("refund : refund ethers back to backers if not softcap reached when ito in progress", async() => {
        await increaseTime(duration.weeks(2));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: 1e18});

        await shouldHaveException(async () => {
            await sale.finishCrowdsale();
        }, "Should has an error");
    
        await shouldHaveException(async () => {
            await sale.refund({from: client});
        }, "Should has an error");
    });

    it("refund : token should burned", async() => {
        await increaseTime(duration.weeks(2));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: 10e18});

        await increaseTime(duration.weeks(4));
        await sale.finishCrowdsale();

        let client_balance = (await token.balanceOf(client));

        await sale.refund({from: client});

        let client_balance2 = (await token.balanceOf(client));
        let burn_balance = (await token.balanceOf(0x0));

        assert.equal(client_balance.toNumber(), burn_balance.toNumber());
        assert.equal(client_balance2, 0);
    });

    it("finishCrowdsale : transfer token after ITO to bounty and team and finish minting", async() => {
        let tokenOnWallet, tokenOnWallet2, tokenOnWallet3, tokenOnContract, tokenOnContract3, totalSupply, totalSupply2;
        await increaseTime(duration.weeks(2));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMinEthers});

        tokenOnWallet = (await token.balanceOf(wallet)).toNumber();
        totalSupply = (await token.totalSupply()).toNumber();

        await increaseTime(duration.weeks(4));
        await sale.finishCrowdsale();

        assert.equal((await token.mintingFinished()), true);
        assert.equal((await token.transferAllowed()), true);

        tokenOnWallet2 = (await token.balanceOf(wallet)).toNumber();
        totalSupply2 = (await token.totalSupply()).toNumber();
        tokenOnContract = (await token.balanceOf(sale.address)).toNumber();

        assert.equal(Math.round(totalSupply*10/830), Math.round(tokenOnWallet2/10));
        assert.equal(Math.round(totalSupply*7/830), Math.round(tokenOnContract/10));

        await increaseTime(duration.years(1));
        await sale.withdrawTokenToFounder();

        tokenOnContract3 = (await token.balanceOf(sale.address)).toNumber();
        tokenOnWallet3 = (await token.balanceOf(wallet)).toNumber();

        assert.equal(tokenOnContract3, 0);
        assert.equal(Math.round((totalSupply/830)*17), Math.round(tokenOnWallet3/10));
    });

    it("finishCrowdsale : try to transfer token before ITO is finished to bounty and team and finish minting", async() => {
        let tokenOnWallet, tokenOnWallet2, tokenOnWallet3, tokenOnContract, tokenOnContract3, totalSupply, totalSupply2;

        await increaseTime(duration.weeks(2));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMinEthers});

        tokenOnContract3 = (await token.balanceOf(sale.address)).toNumber();
        tokenOnWallet3 = (await token.balanceOf(wallet)).toNumber();

        assert.equal(tokenOnContract3, 0);
        assert.equal(tokenOnWallet3, 0);
    });

    it("addWhitelist : test add new address to whitelist", async() => {
        await increaseTime(duration.weeks(1));

        await shouldHaveException(async () => {
            await web3.eth.sendTransaction();
        }, "Should has an error");

        await sale.addWhitelist(client, 100e18, {from: owner});
        await web3.eth.sendTransaction({from: client, to: sale.address, value: 100e18});
    });

    it("whitelist : test fund on 24 stage from whitelisting address", async() => {
        await increaseTime(duration.weeks(1));
        await web3.eth.sendTransaction({from: client_wl, to: sale.address, value: 100e18});
    });

    it("whitelist : test fund on 24 stage from whitelisting address, set new limit and fund again", async() => {
        await increaseTime(duration.weeks(1));
        await web3.eth.sendTransaction({from: client_wl, to: sale.address, value: 100e18});

        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client_wl, to: sale.address, value: 100e18});
        }, "Should has an error");

        await sale.addWhitelist(client_wl, 200e18);

        await web3.eth.sendTransaction({from: client_wl, to: sale.address, value: 100e18});

        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client_wl, to: sale.address, value: 100e18});
        }, "Should has an error");
    });

    it("whitelist : test fund on 24 stage from not whitelisting address", async() => {
        await increaseTime(duration.weeks(1));

        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client, to: sale.address, value: 100e18});
        }, "Should has an error");
    });

    it("buyTokens : received lower than 0.01 ether", async() => {
        await increaseTime(duration.weeks(2));

        let client_wl_balance = (await token.balanceOf(client_wl));
        await shouldHaveException(async () => {
            await sale.buyTokens(client_wl, {from: client, value: 0.009e18});
        }, "Should has an error");
    });

    it("buyTokens : direct call", async() => {
        await increaseTime(duration.weeks(2));
        await increaseTime(duration.days(1));

        let client_wl_balance = (await token.balanceOf(client_wl));
        await sale.buyTokens(client_wl, {from: client, value: 100e18});
        let client_wl_balance2 = (await token.balanceOf(client_wl));
        assert.notEqual(client_wl_balance, client_wl_balance2.toNumber());
        assert.equal(client_wl_balance2.toNumber(), calcAmount(100e18));
    });

    it("finishCrowdsale : not more than 10000000e8 token possible to issue", async() => {
        await increaseTime(duration.weeks(1));

        let total = (await token.totalSupply());
        let maximumTokens = (await sale.maximumTokens());
        await increaseTime(duration.days(1));
        await sale.buyTokens(client, {from: client, value: testMaxEthers});
        await increaseTime(duration.years(1));
        await sale.finishCrowdsale();

        let total2 = (await token.totalSupply());
        if(total2 == 10000000e8-300000e8+total) {
            throw new Error(`${maximumTokens} ${total} ${total2} should be lower than 10000000e8`);
        }
    });

    it("Check token balance", async() => {
        await increaseTime(duration.weeks(1));
        await increaseTime(duration.days(1));

        await balanceEqualTo(client, 0);

        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(1)});

        await balanceEqualTo(client, calcAmount(1e18));
    });

    it("After donate", async () => {
        await balanceEqualTo(client, 0);
        await increaseTime(duration.weeks(1));
        await increaseTime(duration.days(1));

        let initialTotalSupply = (await token.totalSupply()).toNumber();
        let tokens = calcAmount(1e18);

        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(1)});

        assert.equal(initialTotalSupply + tokens, (await token.totalSupply()).toNumber(), "Client balance must be 1 ether / testRate");
        await balanceEqualTo(client, tokens);
    });

    it("Donate before startTime", async () => {
        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(4)});
        }, "Should has an error");
    });

    it("Donate after startTime", async () => {
        await increaseTime(duration.weeks(1));
        await increaseTime(duration.days(1));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(1)});
    });

    it("Donate max ether", async () => {
        await increaseTime(duration.weeks(2));

        assert.equal((await token.mintingFinished()), false);

        assert.equal((await sale.running()), true);
        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMaxEthers});
        let totalEthers = (await sale.totalEthers()).toNumber();
        assert.equal(totalEthers, testMaxEthers);

        assert.equal((await sale.running()), false);

        await sale.finishCrowdsale();

        assert.equal((await token.mintingFinished()), true);
        assert.equal((await token.transferAllowed()), true);

        await token.transfer(client, 1e8, {from: client});

        await shouldHaveException(async () => {
            await sale.refund({from: client});
        }, "Should has an error");

        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client, to: sale.address, value: 1e18});
        }, "Should has an error");
    });

    it("Donate more then max ether", async () => {
        await increaseTime(duration.weeks(2));

        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client, to: sale.address, value: testMaxEthers + 1e18});
        }, "Should has an error");
    });

    it("Donate after endTime", async () => {
        await increaseTime(duration.weeks(5));

        await shouldHaveException(async () => {
            await web3.eth.sendTransaction({from: client, to: sale.address, value: web3.toWei(4)});
        }, "Should has an error");

        await sale.finishCrowdsale();
        assert.equal((await token.mintingFinished()), true, 'mintingFinished must true');
        assert.equal((await token.transferAllowed()), false, 'transferAllowed must false');
    });

    it("Finish minting", async () => {
        let end_balance, tokenOnWallet, tokenOnWallet2, tokenOnWallet3, tokenOnContract, tokenOnContract3, totalSupply, totalSupply2;
        let started_balance = (await web3.eth.getBalance(wallet)).toNumber();

        await increaseTime(duration.weeks(2));
        await web3.eth.sendTransaction({from: client, to: sale.address, value: testMaxEthers});

        tokenOnWallet = (await token.balanceOf(wallet)).toNumber();
        totalSupply = (await token.totalSupply()).toNumber();

        await sale.finishCrowdsale();

        await shouldHaveException(async () => {
            await sale.finishCrowdsale();
        }, "Should has an error");

        assert.equal((await token.mintingFinished()), true);
        assert.equal((await token.transferAllowed()), true);

        await sale.withdraw();

        end_balance = (await web3.eth.getBalance(wallet)).toNumber();
        assert.equal(Math.round((end_balance - started_balance)/1e18), Math.round(testMaxEthers/1e18));
        tokenOnWallet2 = (await token.balanceOf(wallet)).toNumber();
        totalSupply2 = (await token.totalSupply()).toNumber();
        tokenOnContract = (await token.balanceOf(sale.address)).toNumber();

        assert.equal(Math.round(totalSupply/830), Math.round(tokenOnWallet2/100));
        assert.equal(Math.round((totalSupply/8300)*7), Math.round(tokenOnContract/100));

        await shouldHaveException(async () => {
            await sale.withdrawTokenToFounder();
        }, "Should has an error");

        await shouldHaveException(async () => {
            await sale.refund({from: client});
        }, "Should has an error");


        await increaseTime(duration.years(1));
        await sale.withdrawTokenToFounder();

        tokenOnContract3 = (await token.balanceOf(sale.address)).toNumber();
        tokenOnWallet3 = (await token.balanceOf(wallet)).toNumber();

        assert.equal(tokenOnContract3, 0);
        assert.equal(Math.round((totalSupply/8300)*17), Math.round(tokenOnWallet3/100));

    });

    it("Check mint", async () => {
        await increaseTime(duration.weeks(1));
        await increaseTime(duration.days(1));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: 1e18});
        let client_balance = (await token.balanceOf(client));
    });

    it("should do something that fires SaleMade", async () => {
        let transfers = (await token.Transfer({fromBlock: 0, toBlock: 'latest'}))

        await increaseTime(duration.days(8));

        await web3.eth.sendTransaction({from: client, to: sale.address, value: 1e18});
        transfers.get((err, events) => {
            assert.equal(events.length, 1);
        });
        
    });
});

