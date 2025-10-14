<div align="center">
  <img height="100x" src="https://bluefin.io/images/bluefin-logo.svg" />

  <h1 style="margin-top:20px;">Bluefin Spot</h1>

</div>

Sui smart contracts for bluefin spot exchange

## Usage

-   Install/Update submodules using `yarn submodules`
-   Install npm package dependencies using `yarn; cd library-sui; yarn`
-   Update .env file with DEPLOY_ON flag
-   Build smart contracts using `yarn build`
-   Deploy contracts using `yarn deploy`
-   To run tests, make sure the `DEPLOY_ON` in .env is set to devnet. The deployer account must have SUI token to deploy contracts and perform contract calls. Use Sui discord channel to request SUI tokens or run `sui client faucet --address` on sui client to fund the deployment account. Update "config.json" with 2 coins. You can use [this](https://github.com/fireflyprotocol/bluefin-coin-contracts/tree/myym/coins-for-tests) repo to deploy USDC and BLUE coins. Once deployed copy the `TreasuryCap` and `PackageId` from the "deployment.json" to "config.json". Run `yarn setup:tests` to deploy contracts and perform genesis actions and then do `yarn test` to run tests


## Run unit tests
- Run unit tests `sui move test`
- Run tests for coverage `sui move test --coverage`
- Show coverage report `sui move coverage summary`
- Run tests and show coverage `sui move test --coverage; sui move coverage summary`


## License
```
This repository is licensed under a Proprietary Smart Contract License held by Bluefin Labs Inc.
The source code is published for transparency and verification purposes only and may not be reused, modified, 
or redeployed without written permission. For inquiries, contact hi@bluefin.io.
```
