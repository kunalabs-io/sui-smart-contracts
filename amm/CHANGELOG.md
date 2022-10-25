# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Features

- [move] Added CreatePool event which emits on pool creation ([afc41a4](https://github.com/kunalabs-io/sui-smart-contracts/commit/afc41a48e63faad10516cfbc5d3596f85281bb57))
- [move] Added periphery functions to the smart contract in order to deal with Coin objects of different values ([a7b1488](https://github.com/kunalabs-io/sui-smart-contracts/commit/a7b14886f782e4aaee19b589a943784d31cc3923))

### Fixes

- [move] Fixed amm tests for devnet-0.12 ([bdfbb6b](https://github.com/kunalabs-io/sui-smart-contracts/commit/bdfbb6b3972c31c01aae28dc753404779c510a4a))

### Breaking

- [move] Renamed `new_pool` to `create_pool` ([7044139](https://github.com/kunalabs-io/sui-smart-contracts/commit/7044139e91387c4fea29a9c0c41a95823f7404b9))
