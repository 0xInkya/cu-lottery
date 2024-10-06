# Raffle
This is a reimplementation of Cyfrin Updraft's [Lottery](https://github.com/Cyfrin/foundry-smart-contract-lottery-cu) contract. This repo is for learning purposes only. It contains my own notes and I have organized the code to make it more understandable to study. 

Deploying to Anvil doesn't work (even though the tests pass) and I'm not sure it's fixable, because creating a subscription programatically doesn't seem to work in any chain. Deploying on Sepolia does work as long as you create a subscription through the [Chainlink VRF UI](https://vrf.chain.link/) and set the subscription ID in your HelperConfig.

GitHub CI workflows fails because it can't find events in the test.

# Installation
Install the repo:
```
git clone https://github.com/0xInkya/cu-lottery.git
```

Install dependencies:
```
make install
```